-- CONTROL_PIPELINE.vhd
-- Top-level control pipeline module for a 5-stage MIPS-like pipeline.
-- Handles main control signal generation, hazard detection, forwarding decisions, and selection or stalling via a multiplexer.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CONTROL_PIPELINE is
  Port (
    -- Write-enable signals from later pipeline stages
    EXMEM_RF_WrEn    : in  std_logic;          -- Write enable from EX/MEM stage
    MEMWB_RF_WrEn    : in  std_logic;          -- Write enable from MEM/WB stage

    -- Control selections coming from ID/EX register
    IDEX_RF_B_sel    : in  std_logic;          -- Select signal for B operand source
    IDEX_RF_WrData_sel : in std_logic;         -- Select signal for register-file write data (e.g. from ALU or memory)

    -- Register specifiers in different stages
    IDEX_Rs          : in  std_logic_vector(4 downto 0);  -- Source register Rs in ID/EX stage
    IDEX_Rt          : in  std_logic_vector(4 downto 0);  -- Source register Rt in ID/EX stage
    IDEX_Rd          : in  std_logic_vector(4 downto 0);  -- Destination register Rd in ID/EX stage
    EXMEM_Rd         : in  std_logic_vector(4 downto 0);  -- Destination register Rd in EX/MEM stage
    MEMWB_Rd         : in  std_logic_vector(4 downto 0);  -- Destination register Rd in MEM/WB stage

    -- Forwarding select outputs to choose operand sources for EX stage
    forward_A_sel    : out std_logic_vector(1 downto 0);  -- Forward select for ALU operand A
    forward_B_sel    : out std_logic_vector(1 downto 0);  -- Forward select for ALU operand B

    -- IF/ID pipeline register fields for hazard detection
    IFID_Rs          : in  std_logic_vector(4 downto 0);  -- Rs in IF/ID stage (for branch hazards)
    IFID_Rt          : in  std_logic_vector(4 downto 0);  -- Rt in IF/ID stage
    IFID_Rd          : in  std_logic_vector(4 downto 0);  -- Rd in IF/ID stage (unused but provided)

    -- Control signals to stall or flush pipeline
    IFID_LdEn        : out std_logic;             -- Load enable for IF/ID register (de-assert to freeze)
    PC_LdEn          : out std_logic;             -- Load enable for PC register (de-assert to stall fetch)
    PC_sel           : out std_logic;             -- PC mux select (0 = PC+4, 1 = branch target)

    -- Instruction fields and branch outcome
    opcode           : in  std_logic_vector(5 downto 0);  -- Opcode field from IF/ID
    func             : in  std_logic_vector(3 downto 0);  -- Function code for R-type
    zero             : in  std_logic;                   -- Zero flag from ALU for branch decisions
    branch_in        : in  std_logic_vector(1 downto 0);  -- Branch type signal from Main Control

    -- Final bundled control signals after stalling/multiplexing
    Control_signals_out : out std_logic_vector(14 downto 0) -- 15-bit bus of control signals
  );
end CONTROL_PIPELINE;

architecture Behavioral of CONTROL_PIPELINE is

  -- Main Control Unit generates core control signals based on opcode/function
  COMPONENT MAIN_CONTROL_UNIT is
    Port (
      opcode        : in  std_logic_vector(5 downto 0);
      func          : in  std_logic_vector(3 downto 0);
      ALU_func      : out std_logic_vector(3 downto 0);  -- ALU operation code
      branch        : out std_logic_vector(1 downto 0);  -- Encoded branch type
      RF_WrEn       : out std_logic;                    -- Register-file write enable
      RF_WrData_sel: out std_logic;                     -- Select between ALU result or memory data
      RF_B_sel      : out std_logic;                    -- ALU B operand source (register or immediate)
      ImmExt        : out std_logic_vector(1 downto 0);  -- Immediate extension type
      ALU_Bin_sel   : out std_logic;                     -- ALU second operand: register or immediate
      ByteOp        : out std_logic;                     -- Byte (load/store) operation flag
      Mem_WrEn      : out std_logic                      -- Memory write enable
    );
  end COMPONENT;

  -- Hazard Detection Unit handles load-use hazards and branch stalls
  COMPONENT HAZARD_DETECTION_UNIT is
    Port (
      RF_B_sel       : in  std_logic;                    -- RF_B_sel forwarded from ID/EX
      RF_WrData_sel  : in  std_logic;                    -- Write-data select from ID/EX
      branch         : in  std_logic_vector(1 downto 0);  -- Branch type override from ID
      zero           : in  std_logic;                    -- ALU zero flag
      IFID_Rs        : in  std_logic_vector(4 downto 0);
      IFID_Rt        : in  std_logic_vector(4 downto 0);
      IFID_Rd        : in  std_logic_vector(4 downto 0);
      IDEX_Rd        : in  std_logic_vector(4 downto 0);
      PC_LdEn        : out std_logic;                    -- Stall PC update
      PC_sel         : out std_logic;                    -- Branch multiplex select
      IFID_LdEn      : out std_logic;                    -- Stall IF/ID register
      Control_sel    : out std_logic                     -- Select point: zero-control (stall) vs. normal
    );
  end COMPONENT;

  -- Forwarding Unit resolves data hazards by selecting recent stage results
  COMPONENT FORWARD_UNIT is
    Port (
      EXMEM_RF_WrEn  : in  std_logic;
      MEMWB_RF_WrEn  : in  std_logic;
      RF_B_sel       : in  std_logic;                    -- B operand source override
      IDEX_Rs        : in  std_logic_vector(4 downto 0);
      IDEX_Rt        : in  std_logic_vector(4 downto 0);
      IDEX_Rd        : in  std_logic_vector(4 downto 0);
      EXMEM_Rd       : in  std_logic_vector(4 downto 0);
      MEMWB_Rd       : in  std_logic_vector(4 downto 0);
      forward_A_sel  : out std_logic_vector(1 downto 0);  -- Forward mux select for operand A
      forward_B_sel  : out std_logic_vector(1 downto 0)   -- Forward mux select for operand B
    );
  end COMPONENT;

  -- Generic 2-to-1 multiplexer for 15-bit control bus: passes control signals or zeros (flush)
  component multiplexer2to1_15 is
    Port (
      input1  : in  std_logic_vector(14 downto 0);      -- Normal control bus
      input2  : in  std_logic_vector(14 downto 0);      -- Flushed control bus (zeros)
      sel     : in  std_logic;                           -- 0: pass input1, 1: pass input2
      output  : out std_logic_vector(14 downto 0)
    );
  end component;

  -- Internal signals to connect components
  signal ALU_func       : std_logic_vector(3 downto 0);
  signal branch         : std_logic_vector(1 downto 0);
  signal RF_WrEn        : std_logic;
  signal RF_WrData_sel  : std_logic;
  signal RF_B_sel       : std_logic;
  signal ImmExt         : std_logic_vector(1 downto 0);
  signal ALU_Bin_sel    : std_logic;
  signal ByteOp         : std_logic;
  signal Mem_WrEn       : std_logic;
  signal Control_sel    : std_logic;
  signal Control_signals: std_logic_vector(14 downto 0);

begin
  -- Instantiate Main Control Unit
  MCU: MAIN_CONTROL_UNIT
    Port map(
      opcode         => opcode,
      func           => func,
      ALU_func       => ALU_func,
      branch         => branch,
      RF_WrEn        => RF_WrEn,
      RF_WrData_sel  => RF_WrData_sel,
      RF_B_sel       => RF_B_sel,
      ImmExt         => ImmExt,
      ALU_Bin_sel    => ALU_Bin_sel,
      ByteOp         => ByteOp,
      Mem_WrEn       => Mem_WrEn
    );

  -- Pack individual control outputs into a single 15-bit bus
  Control_signals(14)           <= '0';                    -- Reserved bit (unused)
  Control_signals(13 downto 12) <= branch;                 -- Branch type
  Control_signals(11)           <= RF_WrEn;                -- Reg write enable
  Control_signals(10)           <= RF_WrData_sel;          -- Write-data select
  Control_signals(9)            <= ByteOp;                 -- Byte operation flag
  Control_signals(8)            <= Mem_WrEn;               -- Memory write enable
  Control_signals(7)            <= ALU_Bin_sel;            -- ALU B mux select
  Control_signals(6 downto 3)   <= ALU_func;               -- ALU function code
  Control_signals(2 downto 1)   <= ImmExt;                 -- Immediate extension type
  Control_signals(0)            <= RF_B_sel;               -- B operand source select

  -- Instantiate Hazard Detection Unit to handle stalls/flushes on load-use or branch
  HDU: HAZARD_DETECTION_UNIT
    Port map(
      RF_B_sel       => RF_B_sel,
      RF_WrData_sel  => IDEX_RF_WrData_sel, -- Use pre-registered signals for hazard checks
      branch         => branch_in,
      zero           => zero,
      IFID_Rs        => IFID_Rs,
      IFID_Rt        => IFID_Rt,
      IFID_Rd        => IFID_Rd,
      IDEX_Rd        => IDEX_Rd,
      PC_LdEn        => PC_LdEn,
      PC_sel         => PC_sel,
      IFID_LdEn      => IFID_LdEn,
      Control_sel    => Control_sel
    );

  -- Instantiate Forwarding Unit to resolve data hazards by forwarding from EX/MEM or MEM/WB
  FU: FORWARD_UNIT
    Port map(
      EXMEM_RF_WrEn => EXMEM_RF_WrEn,
      MEMWB_RF_WrEn => MEMWB_RF_WrEn,
      RF_B_sel      => IDEX_RF_B_sel,  -- B operand selection from ID/EX
      IDEX_Rs       => IDEX_Rs,
      IDEX_Rt       => IDEX_Rt,
      IDEX_Rd       => IDEX_Rd,
      EXMEM_Rd      => EXMEM_Rd,
      MEMWB_Rd      => MEMWB_Rd,
      forward_A_sel => forward_A_sel,
      forward_B_sel => forward_B_sel
    );

  -- Multiplexer flushes control bus to zeros when a stall/flush is required
  MUX2TO1_15: multiplexer2to1_15
    Port map(
      input1 => Control_signals,             -- Normal control bus
      input2 => (others => '0'),             -- Flushed control bus: no operations
      sel    => Control_sel,                  -- 0 = normal, 1 = flush/stall
      output => Control_signals_out
    );

end Behavioral;
