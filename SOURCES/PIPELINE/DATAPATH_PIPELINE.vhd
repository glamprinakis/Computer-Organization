-- DATAPATH_PIPELINE.vhd
-- This file defines the top-level pipelined datapath for a simple RISC-style processor.
-- It includes IF, ID, EX, MEM, and WB stages with pipeline registers and forwarding logic.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Top-level entity declaration for the pipelined datapath
entity DATAPATH_PIPELINE is
  Port (
    -- Control inputs for program counter (PC) selection and loading
    PC_sel       : in  STD_LOGIC;              -- 0: PC+4, 1: branch/jump target
    PC_LdEn      : in  STD_LOGIC;              -- Enable PC register update
    IFID_LdEn    : in  STD_LOGIC;              -- Enable IF/ID pipeline register
    Reset        : in  STD_LOGIC;              -- Active-high reset signal
    Clk          : in  STD_LOGIC;              -- System clock

    -- Program Counter output (sent to instruction memory)
    PC           : out STD_LOGIC_VECTOR(31 downto 0);

    -- Instruction fetched from memory (input to IF stage)
    Instr        : in  STD_LOGIC_VECTOR(31 downto 0);

    -- Forwarding select signals for EX stage ALU inputs
    forward_sel_A: in  STD_LOGIC_VECTOR(1 downto 0);  -- Select for ALU A
    forward_sel_B: in  STD_LOGIC_VECTOR(1 downto 0);  -- Select for ALU B

    -- Control signals from the hazard unit for all stages
    control_signals : in STD_LOGIC_VECTOR(14 downto 0);

    -- Status flag from ALU in EX stage
    ALU_zero     : out STD_LOGIC;

    -- Memory stage interfaces
    MM_WrEn      : out STD_LOGIC;                -- External memory write enable
    MM_Addr      : out STD_LOGIC_VECTOR(31 downto 0);  -- External memory address
    MM_WrData    : out STD_LOGIC_VECTOR(31 downto 0);  -- Data to write to external memory
    MM_RdData    : in  STD_LOGIC_VECTOR(31 downto 0);  -- Data read from external memory

    -- Outputs to the hazard/directory units for register writeback tracking
    Opcode       : out STD_LOGIC_VECTOR(5 downto 0);   -- Current instruction opcode
    func         : out STD_LOGIC_VECTOR(3 downto 0);   -- Function field for R-type
    EXMEM_RF_WrEn: out STD_LOGIC;                -- Write enable in EX/MEM stage
    MEMWB_RF_WrEn: out STD_LOGIC;                -- Write enable in MEM/WB stage

    -- Control signals passing through ID/EX pipeline register
    IDEX_RF_B_sel      : out STD_LOGIC;         -- Select for ALU second operand (Reg vs Imm)
    IDEX_RF_WrData_sel : out STD_LOGIC;         -- Select for writeback data (ALU vs Mem)
    branch             : out STD_LOGIC_VECTOR(1 downto 0); -- Branch type control

    -- Register specifiers at various pipeline stages (for hazard detection)
    IFID_Rs      : out STD_LOGIC_VECTOR(4 downto 0);
    IFID_Rt      : out STD_LOGIC_VECTOR(4 downto 0);
    IFID_Rd      : out STD_LOGIC_VECTOR(4 downto 0);
    IDEX_Rd      : out STD_LOGIC_VECTOR(4 downto 0);
    IDEX_Rs      : out STD_LOGIC_VECTOR(4 downto 0);
    IDEX_Rt      : out STD_LOGIC_VECTOR(4 downto 0);
    EXMEM_Rd     : out STD_LOGIC_VECTOR(4 downto 0);
    MEMWB_Rd     : out STD_LOGIC_VECTOR(4 downto 0)
  );
end DATAPATH_PIPELINE;

architecture Behavioral of DATAPATH_PIPELINE is

  -- Component declarations for each pipeline stage and helper modules
  component IFSTAGE_PIPELINE
    Port (
      PC_Immed : in  STD_LOGIC_VECTOR(31 downto 0); -- Next PC value (branch/jump)
      PC_sel    : in  STD_LOGIC;                    -- PC source select
      PC_LdEn   : in  STD_LOGIC;                    -- PC load enable
      Reset     : in  STD_LOGIC;
      Clk       : in  STD_LOGIC;
      PC        : out STD_LOGIC_VECTOR(31 downto 0)  -- Current PC
    );
  end component;

  component register32
    port (
      Datain  : in  STD_LOGIC_VECTOR(31 downto 0);
      Dataout : out STD_LOGIC_VECTOR(31 downto 0);
      Clk     : in  STD_LOGIC;
      Rst     : in  STD_LOGIC;
      WE      : in  STD_LOGIC
    );
  end component;

  component register15 is
    port (
      Datain  : in  STD_LOGIC_VECTOR(14 downto 0);
      Dataout : out STD_LOGIC_VECTOR(14 downto 0);
      Clk     : in  STD_LOGIC;
      Rst     : in  STD_LOGIC;
      WE      : in  STD_LOGIC
    );
  end component;

  component register5 is
    port (
      Datain  : in  STD_LOGIC_VECTOR(4 downto 0);
      Dataout : out STD_LOGIC_VECTOR(4 downto 0);
      Clk     : in  STD_LOGIC;
      Rst     : in  STD_LOGIC;
      WE      : in  STD_LOGIC
    );
  end component;

  component multiplexer3to1_32 is
    Port (
      input1 : in STD_LOGIC_VECTOR(31 downto 0);
      input2 : in STD_LOGIC_VECTOR(31 downto 0);
      input3 : in STD_LOGIC_VECTOR(31 downto 0);
      sel    : in STD_LOGIC_VECTOR(1 downto 0);
      output : out STD_LOGIC_VECTOR(31 downto 0)
    );
  end component;

  component multiplexer2to1_32 is
    Port (
      input1 : in STD_LOGIC_VECTOR(31 downto 0);
      input2 : in STD_LOGIC_VECTOR(31 downto 0);
      sel    : in STD_LOGIC;
      output : out STD_LOGIC_VECTOR(31 downto 0)
    );
  end component;

  component multiplexer2to1_5 is
    Port (
      input1 : in STD_LOGIC_VECTOR(4 downto 0);
      input2 : in STD_LOGIC_VECTOR(4 downto 0);
      sel    : in STD_LOGIC;
      output : out STD_LOGIC_VECTOR(4 downto 0)
    );
  end component;

  component DECSTAGE_PIPELINE is
    Port (
      ReadRegister1 : in  STD_LOGIC_VECTOR(4 downto 0); -- rs
      ReadRegister2 : in  STD_LOGIC_VECTOR(4 downto 0); -- rt or rd, depending on format
      WriteRegister : in  STD_LOGIC_VECTOR(4 downto 0); -- register to write in WB stage
      Immediate     : in  STD_LOGIC_VECTOR(15 downto 0);-- immediate field
      RF_WrEn       : in  STD_LOGIC;                   -- write enable from MEM/WB
      WrData        : in  STD_LOGIC_VECTOR(31 downto 0);-- data to write back
      ImmExt        : in  STD_LOGIC_VECTOR(1 downto 0); -- immediate extension control
      Clk           : in  STD_LOGIC;
      RST           : in  STD_LOGIC;
      Immed         : out STD_LOGIC_VECTOR(31 downto 0);-- extended immediate
      RF_A          : out STD_LOGIC_VECTOR(31 downto 0);-- register file port A
      RF_B          : out STD_LOGIC_VECTOR(31 downto 0) -- register file port B
    );
  end component;

  component EXSTAGE is
    Port (
      RF_A        : in  STD_LOGIC_VECTOR(31 downto 0); -- forwarded A
      RF_B        : in  STD_LOGIC_VECTOR(31 downto 0); -- forwarded B
      Immed       : in  STD_LOGIC_VECTOR(31 downto 0); -- immediate value
      ALU_Bin_sel : in  STD_LOGIC;                    -- selects B or Immed
      ALU_func    : in  STD_LOGIC_VECTOR(3 downto 0); -- ALU opcode
      ALU_out     : out STD_LOGIC_VECTOR(31 downto 0); -- ALU result
      ALU_zero    : out STD_LOGIC                     -- zero flag for branching
    );
  end component;

  component MEMSTAGE is
    Port (
      ByteOp       : in  STD_LOGIC;                    -- byte/word operation control
      Mem_WrEn     : in  STD_LOGIC;                    -- local memory write enable
      MM_WrEn      : out STD_LOGIC;                    -- bus memory write enable
      ALU_MEM_Addr : in  STD_LOGIC_VECTOR(31 downto 0); -- address from ALU
      MEM_DataIn   : in  STD_LOGIC_VECTOR(31 downto 0); -- data from register file
      MEM_DataOut  : out STD_LOGIC_VECTOR(31 downto 0); -- data read from memory
      MM_Addr      : out STD_LOGIC_VECTOR(31 downto 0); -- bus memory address
      MM_WrData    : out STD_LOGIC_VECTOR(31 downto 0); -- bus memory write data
      MM_RdData    : in  STD_LOGIC_VECTOR(31 downto 0)  -- bus memory read data
    );
  end component;

  -- Internal signals for data passing through pipeline and between modules
  signal t_immed, t_immed_out       : STD_LOGIC_VECTOR(31 downto 0);
  signal instr_out, instr_mux       : STD_LOGIC_VECTOR(31 downto 0);
  signal t_WRDATA, t_RDDATA         : STD_LOGIC_VECTOR(31 downto 0);
  signal MEMWB_ALU_out, EXMEM_ALU_out, t_ALU, t_MEM_out : STD_LOGIC_VECTOR(31 downto 0);
  signal t_RF_A, t_RF_A_OUT, t_RF_B, t_RF_B_OUT       : STD_LOGIC_VECTOR(31 downto 0);
  signal t_A_OUT, t_B_OUT           : STD_LOGIC_VECTOR(31 downto 0);
  signal RF_WrData                  : STD_LOGIC_VECTOR(31 downto 0);

  -- Pipeline register fields for destination registers
  signal t_IDEX_Rd, t_EXMEM_Rd, t_MEMWB_Rd : STD_LOGIC_VECTOR(4 downto 0);
  signal readRegister2              : STD_LOGIC_VECTOR(4 downto 0);

  -- Clock inversion for DEC stage register (to avoid write/read conflict)
  signal not_clk                    : STD_LOGIC;

  -- Control signals latched at each pipeline boundary
  signal IDEX_control_signals, EXMEM_control_signals, MEMWB_control_signals : STD_LOGIC_VECTOR(14 downto 0);

begin

  -----------------------------------------------------------------------------
  -- IF Stage: PC update & instruction fetch
  -----------------------------------------------------------------------------
  IFS: IFSTAGE_PIPELINE
    port map(
      PC_Immed => t_immed_out,     -- Next PC from branch/jump
      PC_sel   => PC_sel,           -- Select PC source
      PC_LdEn  => PC_LdEn,          -- Enable PC register
      Reset    => Reset,
      Clk      => Clk,
      PC       => PC                -- Output current PC
    );

  -- MUX to inject bubble or hold instruction during hazard
  mux2to1_32_Instr: multiplexer2To1_32
    port map(
      input1 => Instr,             -- Fetched instruction
      input2 => x"40000000",      -- NOP encoding (bubble)
      sel    => PC_sel,             -- Using PC_sel as bubble control
      output => instr_mux          -- Output to IF/ID register
    );

  -- IF/ID pipeline register latching instruction word
  IFID_REG: register32
    port map(
      Datain  => instr_mux,
      Dataout => instr_out,
      Clk     => Clk,
      Rst     => Reset,
      WE      => IFID_LdEn          -- Stall control
    );

  -- Extract fields for hazard detection and control
  Opcode <= instr_out(31 downto 26);  -- Top 6 bits
  func   <= instr_out(3 downto 0);    -- Bottom 4 bits (R-type func)
  IFID_Rs <= instr_out(25 downto 21); -- Source register rs
  IFID_Rd <= instr_out(20 downto 16); -- rt or rd depending on format (for hazards)
  IFID_Rt <= instr_out(15 downto 11); -- destination register for R-type (for hazards)

  -----------------------------------------------------------------------------
  -- ID Stage: Register file read and register decode
  -----------------------------------------------------------------------------
  -- Choose second register input: rt or rd depending on instruction format
  mux5: multiplexer2To1_5
    port map(
      input1 => instr_out(15 downto 11),  -- rd field
      input2 => instr_out(20 downto 16),  -- rt field
      Sel    => control_signals(0),       -- control: choose format
      output => readRegister2
    );

  not_clk <= not Clk;                    -- Inverted clock for DEC stage registers

  -- DECSTAGE_PIPELINE: extends immediate, reads register file, and writes back
  DEC: DECSTAGE_PIPELINE
    port map(
      ReadRegister1 => instr_out(25 downto 21),  -- rs
      ReadRegister2 => readRegister2,             -- rt/rd
      WriteRegister => t_MEMWB_Rd,                -- from WB stage
      Immediate     => instr_out(15 downto 0),    -- immediate field
      RF_WrEn       => MEMWB_control_signals(11),-- write enable from WB
      WrData        => RF_WrData,                -- data from WB mux
      ImmExt        => control_signals(2 downto 1), -- sign/zero/ext control
      Clk           => not_clk,                  -- inverted clock
      rst           => Reset,
      Immed         => t_immed,                  -- extended immediate
      RF_A          => t_RF_A,                   -- reg file port A
      RF_B          => t_RF_B                    -- reg file port B
    );

  -----------------------------------------------------------------------------
  -- ID/EX Pipeline Registers: latch registers and control
  -----------------------------------------------------------------------------
  IMMED_REG: register32
    port map(Datain => t_immed, Dataout => t_immed_out, Clk => Clk, Rst => Reset, WE => '1');
  RFA_REG  : register32
    port map(Datain => t_RF_A,  Dataout => t_RF_A_OUT,  Clk => Clk, Rst => Reset, WE => '1');
  RFB_REG  : register32
    port map(Datain => t_RF_B,  Dataout => t_RF_B_OUT,  Clk => Clk, Rst => Reset, WE => '1');
  IDEX_control_signals_REG: register15
    port map(Datain => control_signals, Dataout => IDEX_control_signals, Clk => Clk, Rst => Reset, WE => '1');

  -- Decode control fields for EX stage
  branch            <= IDEX_control_signals(13 downto 12); -- branch type
  IDEX_RF_WrData_sel<= IDEX_control_signals(10);           -- select ALU/MEM for WB
  IDEX_RF_B_sel     <= IDEX_control_signals(0);            -- select reg/imm for ALU B

  -- Pipeline register for destination register number
  IDEX_DESTINATION_REG: register5
    port map(Datain => instr_out(20 downto 16), Dataout => t_IDEX_Rd, Clk => Clk, Rst => Reset, WE => '1');
  IDEX_Rd <= t_IDEX_Rd;  -- expose for hazard detection

  -- Pipeline registers for source registers
  IDEX_Rs_REG: register5
    port map(Datain => instr_out(25 downto 21), Dataout => IDEX_Rs, Clk => Clk, Rst => Reset, WE => '1');
  IDEX_Rt_REG: register5
    port map(Datain => instr_out(15 downto 11), Dataout => IDEX_Rt, Clk => Clk, Rst => Reset, WE => '1');

  -----------------------------------------------------------------------------
  -- EX Stage: ALU operation with forwarding
  -----------------------------------------------------------------------------
  mux3to1_32_RFA: multiplexer3To1_32
    port map(
      input1 => t_RF_A_OUT,       -- normal data from ID/EX
      input2 => EXMEM_ALU_out,     -- forwarded from EX/MEM
      input3 => RF_WrData,         -- forwarded from WB stage
      sel    => forward_sel_A,      -- forwarding control
      output => t_A_OUT            -- final ALU A input
    );

  mux3to1_32_RFB: multiplexer3To1_32
    port map(
      input1 => t_RF_B_OUT,       -- normal data
      input2 => EXMEM_ALU_out,     -- forwarded from EX/MEM
      input3 => RF_WrData,         -- forwarded from WB
      sel    => forward_sel_B,      -- forwarding control (case-insensitive fix)
      output => t_B_OUT            -- final ALU B input
    );

  EX: EXSTAGE
    port map(
      RF_A        => t_A_OUT,                     -- forwarded operand A
      RF_B        => t_B_OUT,                     -- forwarded operand B
      Immed       => t_immed_out,                 -- immediate input
      ALU_Bin_sel => IDEX_control_signals(7),     -- choose B or immediate
      ALU_func    => IDEX_control_signals(6 downto 3), -- ALU operation code
      ALU_out     => t_ALU,                       -- ALU result
      ALU_zero    => ALU_zero                     -- zero flag for branch
    );

  -----------------------------------------------------------------------------
  -- EX/MEM Pipeline Registers: latch ALU result, data, control, and dest
  -----------------------------------------------------------------------------
  EXMEM_ALU_REG: register32
    port map(Datain => t_ALU, Dataout => EXMEM_ALU_out, Clk => Clk, Rst => Reset, WE => '1');
  WRDATA_REG: register32
    port map(Datain => t_B_OUT, Dataout => t_WRDATA, Clk => Clk, Rst => Reset, WE => '1');
  EXMEM_control_signals_REG: register15
    port map(Datain => IDEX_control_signals, Dataout => EXMEM_control_signals, Clk => Clk, Rst => Reset, WE => '1');

  -- Write enable for MEM stage
  EXMEM_RF_WrEn <= EXMEM_control_signals(11);

  -- Destination register for MEM stage
  EXMEM_DESTINATION_REG: register5
    port map(Datain => t_IDEX_Rd, Dataout => t_EXMEM_Rd, Clk => Clk, Rst => Reset, WE => '1');
  EXMEM_Rd <= t_EXMEM_Rd;

  -----------------------------------------------------------------------------
  -- MEM Stage: Data memory access and EX/MEM -> MEM/WB regs
  -----------------------------------------------------------------------------
  MEM: MEMSTAGE
    port map(
      ByteOp       => EXMEM_control_signals(9),   -- byte/word control
      Mem_WrEn     => EXMEM_control_signals(8),   -- internal memory write enable
      MM_WrEn      => MM_WrEn,                    -- external bus write enable
      ALU_MEM_Addr => EXMEM_ALU_out,              -- address
      MEM_DataIn   => t_WRDATA,                   -- data to store
      MEM_DataOut  => t_RDDATA,                   -- loaded data
      MM_Addr      => MM_Addr,
      MM_WrData    => MM_WrData,
      MM_RdData    => MM_RdData                   -- data from external bus
    );

  -- MEM/WB pipeline registers for loaded data, ALU result, control, and dest
  RDDATA_REG: register32
    port map(Datain => t_RDDATA, Dataout => t_MEM_out, Clk => Clk, Rst => Reset, WE => '1');
  MEMWB_ALU_REG: register32
    port map(Datain => EXMEM_ALU_out, Dataout => MEMWB_ALU_out, Clk => Clk, Rst => Reset, WE => '1');
  MEMWB_DESTINATION_REG: register5
    port map(Datain => t_EXMEM_Rd, Dataout => t_MEMWB_Rd, Clk => Clk, Rst => Reset, WE => '1');

  MEMWB_Rd <= t_MEMWB_Rd;
  MEMWB_control_signals_REG: register15
    port map(Datain => EXMEM_control_signals, Dataout => MEMWB_control_signals, Clk => Clk, Rst => Reset, WE => '1');
  MEMWB_RF_WrEn <= MEMWB_control_signals(11);

  -----------------------------------------------------------------------------
  -- WB Stage: Writeback multiplexing and forwarding outputs
  -----------------------------------------------------------------------------
  mux2to1_32_WrData: multiplexer2To1_32
    port map(
      input1 => MEMWB_ALU_out,             -- ALU result
      input2 => t_MEM_out,                  -- Data loaded from memory
      sel    => MEMWB_control_signals(10),  -- select ALU vs Mem
      output => RF_WrData                   -- final writeback data
    );

end Behavioral;
