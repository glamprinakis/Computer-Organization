-- DECSTAGE_PIPELINE.vhd
-- Description: Decode stage of a pipelined processor including register file and immediate extender

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entity Declaration: DECSTAGE_PIPELINE
-- Ports:
--   ReadRegister1, ReadRegister2: Source register addresses for operand fetch
--   WriteRegister: Destination register address for write-back stage
--   Immediate: 16-bit immediate field from instruction
--   ImmExt: Immediate extension control (e.g., sign/zero/branch offset)
--   RF_WrEn: Register file write enable signal
--   WrData: Data to write into the register file
--   Clk: System clock
--   RST: Synchronous reset for register file
--   Immed: 32-bit extended immediate output
--   RF_A, RF_B: Read data outputs from register file
entity DECSTAGE_PIPELINE is
  Port (
    ReadRegister1 : in  std_logic_vector(4 downto 0); -- Source register #1 address
    ReadRegister2 : in  std_logic_vector(4 downto 0); -- Source register #2 address
    WriteRegister : in  std_logic_vector(4 downto 0); -- Destination register address for write-back
    Immediate     : in  std_logic_vector(15 downto 0);-- 16-bit immediate from instruction
    RF_WrEn       : in  std_logic;                   -- Enable write to register file
    WrData        : in  std_logic_vector(31 downto 0);-- Data to write back

    ImmExt        : in  std_logic_vector(1 downto 0); -- Control for immediate extension mode
    Clk           : in  std_logic;                    -- Clock signal
    RST           : in  std_logic;                    -- Reset for register file
    Immed         : out std_logic_vector(31 downto 0);-- Extended 32-bit immediate
    RF_A          : out std_logic_vector(31 downto 0);-- Read data output 1
    RF_B          : out std_logic_vector(31 downto 0) -- Read data output 2
  );
end DECSTAGE_PIPELINE;

architecture Behavioral of DECSTAGE_PIPELINE is

  -- Component declaration for immediate extender
  component ImmedExtender is
    Port (
      Immed      : in  std_logic_vector(15 downto 0); -- 16-bit immediate input
      immedsel   : in  std_logic_vector(1 downto 0);  -- Selector for extension type
      Immed_Out  : out std_logic_vector(31 downto 0)  -- 32-bit extended immediate
    );
  end component;

  -- Component declaration for register file
  component RegisterFile is
    Port (
      Ard1  : in  std_logic_vector(4 downto 0);       -- Address of first read port
      Ard2  : in  std_logic_vector(4 downto 0);       -- Address of second read port
      Awr   : in  std_logic_vector(4 downto 0);       -- Address of write port
      Dout1 : out std_logic_vector(31 downto 0);      -- Data output from first read port
      Dout2 : out std_logic_vector(31 downto 0);      -- Data output from second read port
      Din   : in  std_logic_vector(31 downto 0);      -- Data input for write port
      RST   : in  std_logic;                          -- Reset signal
      WrEn  : in  std_logic;                          -- Write enable
      Clk   : in  std_logic                           -- Clock signal
    );
  end component;

  -- Component declaration for 2-to-1 multiplexer (5-bit wide)
  component multiplexer2To1_5 is
    Port (
      input1 : in std_logic_vector(4 downto 0); -- First input
      input2 : in std_logic_vector(4 downto 0); -- Second input
      output : out std_logic_vector(4 downto 0);-- Selected output
      Sel    : in std_logic                    -- Select signal
    );
  end component;

  -- Internal signals for pipeline/register connections
  signal t_WrData        : std_logic_vector(31 downto 0); -- Temporary write data
  signal t_readRegister2 : std_logic_vector(4 downto 0);  -- Temporary second read address
  signal opcode          : std_logic_vector(5 downto 0);  -- Instruction opcode

begin

  -- Instantiate Immediate Extender
  -- Extends 16-bit immediate to 32-bit based on ImmExt control
  ImmediateExtender: ImmedExtender
    port map (
      Immed     => Immediate,
      immedSel  => ImmExt,
      Immed_Out => Immed
    );

  -- Instantiate Register File
  -- Provides two read ports and one write port for the register file
  RF: RegisterFile
    port map (
      Ard1  => ReadRegister1, -- Address for read port A
      Ard2  => ReadRegister2, -- Address for read port B
      Awr   => WriteRegister, -- Address for write port
      Dout1 => RF_A,           -- Data from read port A
      Dout2 => RF_B,           -- Data from read port B
      Din   => WrData,         -- Data to be written
      WrEn  => RF_WrEn,        -- Write enable
      Clk   => Clk,            -- Clock signal
      RST   => RST             -- Reset signal
    );

  -- (Optional) Instantiate additional multiplexers or control logic here
  -- e.g., forwarding muxes, pipeline stall signals, etc.

end Behavioral;
