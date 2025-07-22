-- PROCESSOR_PIPELINE.vhd
-- Top-level wrapper for a pipelined processor integrating instruction memory (IMEM), data memory (DMEM), datapath, and control units.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration for the pipeline processor
entity PROCESSOR_PIPELINE is
  Port (
        clk       : in  STD_LOGIC;                       -- System clock
        RESET     : in  STD_LOGIC;                       -- Asynchronous reset
        inst_addr : out STD_LOGIC_VECTOR(31 downto 0);   -- Address output to instruction memory
        inst_dout : in  STD_LOGIC_VECTOR(31 downto 0);   -- Instruction fetched from memory
        data_we   : out STD_LOGIC;                       -- Data memory write enable
        data_addr : out STD_LOGIC_VECTOR(31 downto 0);   -- Address output to data memory
        data_din  : out STD_LOGIC_VECTOR(31 downto 0);   -- Data to write into memory
        data_dout : in  STD_LOGIC_VECTOR(31 downto 0)    -- Data read from memory
  );
end PROCESSOR_PIPELINE;

architecture Behavioral of PROCESSOR_PIPELINE is

  -- Component declarations for modular blocks
  component DATAPATH_PIPELINE is
    Port (
           PC_sel         : in  STD_LOGIC;                  -- Select for next PC source (branch/jump vs. sequential)
           PC_LdEn        : in  STD_LOGIC;                  -- Enable loading of PC register
           IFID_LdEn      : in  STD_LOGIC;                  -- Enable for IF/ID pipeline register
           Reset          : in  STD_LOGIC;                  -- Reset signal for datapath
           Clk            : in  STD_LOGIC;                  -- Clock for datapath registers
           PC             : out STD_LOGIC_VECTOR(31 downto 0); -- Current PC value
           Instr          : in  STD_LOGIC_VECTOR(31 downto 0); -- Instruction input
           forward_sel_A  : in  STD_LOGIC_VECTOR(1 downto 0); -- Forwarding selection for ALU input A
           forward_sel_B  : in  STD_LOGIC_VECTOR(1 downto 0); -- Forwarding selection for ALU input B
           control_signals: in  STD_LOGIC_VECTOR(14 downto 0);-- Control bus from main control unit
           ALU_zero       : out STD_LOGIC;                  -- Zero flag from ALU
           MM_WrEn        : out STD_LOGIC;                  -- Memory write enable
           MM_Addr        : out STD_LOGIC_VECTOR(31 downto 0); -- Memory address
           MM_WrData      : out STD_LOGIC_VECTOR(31 downto 0); -- Data to memory write port
           MM_RdData      : in  STD_LOGIC_VECTOR(31 downto 0); -- Data from memory read port
           Opcode         : out STD_LOGIC_VECTOR(5 downto 0);  -- Instruction opcode field
           func           : out STD_LOGIC_VECTOR(3 downto 0);  -- Function field for R-type
           EXMEM_RF_WrEn  : out STD_LOGIC;                  -- Regfile write enable from EX/MEM stage
           MEMWB_RF_WrEn  : out STD_LOGIC;                  -- Regfile write enable from MEM/WB stage
           IDEX_RF_B_sel  : out STD_LOGIC;                  -- Select between register B or immediate for EX stage
           IDEX_RF_WrData_sel : out STD_LOGIC;              -- Select between ALU result or memory data in WB stage
           branch         : out STD_LOGIC_VECTOR(1 downto 0); -- Branch type encoding (e.g., beq, bne)
           IFID_Rs        : out STD_LOGIC_VECTOR(4 downto 0); -- Source register Rs in IF/ID register
           IFID_Rt        : out STD_LOGIC_VECTOR(4 downto 0); -- Source register Rt in IF/ID register
           IFID_Rd        : out STD_LOGIC_VECTOR(4 downto 0); -- Destination register Rd in IF/ID register
           IDEX_Rd        : out STD_LOGIC_VECTOR(4 downto 0); -- Rd passed into EX stage
           IDEX_Rs        : out STD_LOGIC_VECTOR(4 downto 0); -- Rs passed into EX stage
           IDEX_Rt        : out STD_LOGIC_VECTOR(4 downto 0); -- Rt passed into EX stage
           EXMEM_Rd       : out STD_LOGIC_VECTOR(4 downto 0); -- Rd passed into MEM stage
           MEMWB_Rd       : out STD_LOGIC_VECTOR(4 downto 0)  -- Rd passed into WB stage
         );
  end component;

  component CONTROL_PIPELINE is
    Port (
           EXMEM_RF_WrEn       : in  STD_LOGIC;          -- EX/MEM write enable for hazard detection
           MEMWB_RF_WrEn       : in  STD_LOGIC;          -- MEM/WB write enable for hazard detection
           IDEX_RF_B_sel       : in  STD_LOGIC;          -- Data path control for immediate vs. register
           IDEX_RF_WrData_sel  : in  STD_LOGIC;          -- Data path control for WB stage mux
           IDEX_Rs             : in  STD_LOGIC_VECTOR(4 downto 0); -- Source register for hazards
           IDEX_Rt             : in  STD_LOGIC_VECTOR(4 downto 0); -- Target register for hazards
           IDEX_Rd             : in  STD_LOGIC_VECTOR(4 downto 0); -- Destination register for hazards
           EXMEM_Rd            : in  STD_LOGIC_VECTOR(4 downto 0); -- EX/MEM destination for hazards
           MEMWB_Rd            : in  STD_LOGIC_VECTOR(4 downto 0); -- MEM/WB destination for hazards
           forward_A_sel       : out STD_LOGIC_VECTOR(1 downto 0); -- Forwarding control to datapath A input
           forward_B_sel       : out STD_LOGIC_VECTOR(1 downto 0); -- Forwarding control to datapath B input
           IFID_Rs             : in  STD_LOGIC_VECTOR(4 downto 0); -- IF/ID Rs for stall logic
           IFID_Rt             : in  STD_LOGIC_VECTOR(4 downto 0); -- IF/ID Rt for stall logic
           IFID_Rd             : in  STD_LOGIC_VECTOR(4 downto 0); -- IF/ID Rd for branch logic
           IFID_LdEn           : out STD_LOGIC;          -- IF/ID register load enable (stall control)
           PC_sel              : out STD_LOGIC;          -- PC mux select for branch taken/not taken
           PC_LdEn             : out STD_LOGIC;          -- PC register load enable (stall control)
           opcode              : in  STD_LOGIC_VECTOR(5 downto 0); -- OPC field for control decoding
           func                : in  STD_LOGIC_VECTOR(3 downto 0); -- FUNC field for R-type decoding
           zero                : in  STD_LOGIC;          -- Zero flag from ALU
           branch_in           : in  STD_LOGIC_VECTOR(1 downto 0); -- Branch type from datapath
           Control_signals_out : out STD_LOGIC_VECTOR(14 downto 0) -- Control signals bus to datapath
         );
  end component;

  component RAM is
    port (
        clk       : in  STD_LOGIC;                      -- Clock for synchronous RAM
        inst_addr : in  STD_LOGIC_VECTOR(10 downto 0);  -- 11-bit instruction address (word-aligned)
        inst_dout : out STD_LOGIC_VECTOR(31 downto 0);  -- Instruction memory data output
        data_we   : in  STD_LOGIC;                      -- Data memory write enable
        data_addr : in  STD_LOGIC_VECTOR(10 downto 0);  -- 11-bit data address (word-aligned)
        data_din  : in  STD_LOGIC_VECTOR(31 downto 0);  -- Data memory data input
        data_dout : out STD_LOGIC_VECTOR(31 downto 0)   -- Data memory data output
    );
  end component;

  -- Internal signals for interconnecting components
  signal PC_sel, PC_LdEn, IFID_LdEn           : STD_LOGIC;
  signal PC                                 : STD_LOGIC_VECTOR(31 downto 0);
  signal Instr                              : STD_LOGIC_VECTOR(31 downto 0);
  signal control_signals                    : STD_LOGIC_VECTOR(14 downto 0);
  signal zero                               : STD_LOGIC;
  signal MM_WrEn                            : STD_LOGIC;
  signal MM_Addr, MM_WrData, MM_RdData      : STD_LOGIC_VECTOR(31 downto 0);
  signal Opcode                             : STD_LOGIC_VECTOR(5 downto 0);
  signal func                               : STD_LOGIC_VECTOR(3 downto 0);
  signal EXMEM_RF_WrEn, MEMWB_RF_WrEn        : STD_LOGIC;
  signal IDEX_RF_B_sel, IDEX_RF_WrData_sel  : STD_LOGIC;
  signal IFID_Rs, IFID_Rt, IFID_Rd           : STD_LOGIC_VECTOR(4 downto 0);
  signal IDEX_Rs, IDEX_Rt, IDEX_Rd           : STD_LOGIC_VECTOR(4 downto 0);
  signal EXMEM_Rd, MEMWB_Rd                  : STD_LOGIC_VECTOR(4 downto 0);
  signal forward_A_sel, forward_B_sel        : STD_LOGIC_VECTOR(1 downto 0);
  signal branch                             : STD_LOGIC_VECTOR(1 downto 0);

begin

  -- Instantiate the datapath pipeline
  DATAPATH: DATAPATH_PIPELINE
    port map (
      PC_sel             => PC_sel,
      PC_LdEn            => PC_LdEn,
      IFID_LdEn          => IFID_LdEn,
      Reset              => RESET,
      Clk                => clk,
      PC                 => inst_addr,   -- Connect internal PC to external inst_addr
      Instr              => inst_dout,   -- Instruction input from memory
      forward_sel_A      => forward_A_sel,
      forward_sel_B      => forward_B_sel,
      control_signals    => control_signals,
      ALU_zero           => zero,
      MM_WrEn            => data_we,
      MM_Addr            => data_addr,
      MM_WrData          => data_din,
      MM_RdData          => data_dout,
      Opcode             => Opcode,
      func               => func,
      EXMEM_RF_WrEn      => EXMEM_RF_WrEn,
      MEMWB_RF_WrEn      => MEMWB_RF_WrEn,
      IDEX_RF_B_sel      => IDEX_RF_B_sel,
      IDEX_RF_WrData_sel => IDEX_RF_WrData_sel,
      branch             => branch,
      IFID_Rs            => IFID_Rs,
      IFID_Rt            => IFID_Rt,
      IFID_Rd            => IFID_Rd,
      IDEX_Rs            => IDEX_Rs,
      IDEX_Rt            => IDEX_Rt,
      IDEX_Rd            => IDEX_Rd,
      EXMEM_Rd           => EXMEM_Rd,
      MEMWB_Rd           => MEMWB_Rd
    );

  -- Instantiate the control pipeline
  CONTROL: CONTROL_PIPELINE
    port map (
      EXMEM_RF_WrEn       => EXMEM_RF_WrEn,
      MEMWB_RF_WrEn       => MEMWB_RF_WrEn,
      IDEX_RF_B_sel       => IDEX_RF_B_sel,
      IDEX_RF_WrData_sel  => IDEX_RF_WrData_sel,
      IDEX_Rs             => IDEX_Rs,
      IDEX_Rt             => IDEX_Rt,
      IDEX_Rd             => IDEX_Rd,
      EXMEM_Rd            => EXMEM_Rd,
      MEMWB_Rd            => MEMWB_Rd,
      forward_A_sel       => forward_A_sel,
      forward_B_sel       => forward_B_sel,
      IFID_Rs             => IFID_Rs,
      IFID_Rt             => IFID_Rt,
      IFID_Rd             => IFID_Rd,
      IFID_LdEn           => IFID_LdEn,
      PC_sel              => PC_sel,
      PC_LdEn             => PC_LdEn,
      opcode              => Opcode,
      func                => func,
      zero                => zero,
      branch_in           => branch,
      Control_signals_out => control_signals
    );

end Behavioral;
