Design of a Multi-Cycle & Pipelined Processor

Course Assignment – April 18, 2021Author: Georgios Lamprinakis (AM: 2018030017)

🎯 Purpose

Understand how to build a multi-cycle processor and evolve it into a pipelined processor by incrementally modifying a single-cycle baseline. The project explores datapath partitioning, control strategies (FSM vs. combinational), and classic pipeline hazard handling (data & control).

📁 Repository Layout (suggested)

├── src/
│   ├── single_cycle/
│   ├── multi_cycle/
│   ├── pipeline/
│   │   ├── control/
│   │   │   ├── main_control.vhd
│   │   │   ├── forward_unit.vhd
│   │   │   └── hazard_detection.vhd
│   │   └── datapath/
│   ├── common/   # ALU, RF, memory, etc.
│   └── tb/       # testbenches
├── sim/
│   ├── reference_program_1/
│   └── waveforms/
├── docs/
│   ├── report_pipeline.pdf
│   └── figures/
├── scripts/      # build/run scripts for your simulator
└── README.md

Adjust paths/extensions to your HDL/simulator/tooling.

🧠 High-Level Architecture

1. Multi-Cycle Processor

5 stages, 1 cycle each: Instruction Fetch (IF), Decode (ID), Execute (EX), Memory (MEM), Write Back (WB).

Pipeline-style registers between stages:

IF→ID: instruction register

ID→EX: two RF read values + immediate value

EX→MEM: ALU result + memory write data

MEM→WB: read data from memory

Control: Finite State Machine (FSM) → Mealy machine (output depends on state & inputs). Signals like pc_ld, immExt, RF_B_sel, PC_sel vary by state and inputs.

No dedicated addi state: merged with Store/Load due to identical control requirements.

2. Pipelined Processor

Built by refining the multi-cycle datapath and adding:

Extra inter-stage registers

ID→EX: Rs, Rt, Rd (5-bit each) + packed control word (15 bits)

EX→MEM / MEM→WB: Rd + control words

Forwarding logic with 3→1 multiplexers in front of ALU inputs (forward_sel_A, forward_sel_B).

IF/ID stage tweaks to manage branch hazards (see below).

Removed/relocated muxes from ID for write-back address/data, since those are only resolved later.

🧰 Pipeline Control Blocks

Main Control Unit

Combines classic "main" and "ALU" control.

Adds a branch signal encoding branch type (BEQ, BNE, b).

Forward Unit

Chooses correct operands to bypass from later stages to EX when RAW hazards appear.

Hazard Detection Unit

Handles stalls and flushes:

Load-Use Hazard

If an instruction needs a register being loaded by the immediately preceding instruction, stall the pipe for 1 cycle:

Freeze pc and IFID writes

Zero control signals for the instruction in ID (convert to bubble)

Control Hazards (Branches)

Assume not taken. Resolve in EX using zero signal.

When branch is taken:

Zero control signals for instruction in ID

Overwrite the already-fetched IF instruction with a harmless "unused opcode" via IFID input mux (e.g., x"40000000")

PC has already advanced by 2 instructions → subtract 8 from immediate to jump to correct target; an extra incrementer handles this.

Even unconditional b uses the same mechanism for simplicity.

▶️ Simulation

Waveforms for Reference Program 1 are provided (see /sim/reference_program_1). Add screenshots or VCD/GTKWave instructions here.
