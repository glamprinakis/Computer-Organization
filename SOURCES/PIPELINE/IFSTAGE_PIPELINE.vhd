-- IFSTAGE_PIPELINE.vhd
-- Instruction Fetch stage with PC update logic including branch offset handling

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration for the Instruction Fetch stage pipeline register
-- Computes the next program counter (PC) value based on sequential increment or branch target
entity IFSTAGE_PIPELINE is
    Port (
        PC_Immed : in  STD_LOGIC_VECTOR (31 downto 0);  -- Immediate offset for branch target
        PC_sel    : in  STD_LOGIC;                     -- Select signal: '0' = sequential, '1' = branch
        PC_LdEn   : in  STD_LOGIC;                     -- Enable loading of PC register
        Reset     : in  STD_LOGIC;                     -- Asynchronous reset for PC register
        Clk       : in  STD_LOGIC;                     -- Clock signal
        PC        : out STD_LOGIC_VECTOR (31 downto 0) -- Current PC output
    );
end IFSTAGE_PIPELINE;

architecture Behavioral of IFSTAGE_PIPELINE is
    -- Component declarations
    component register32 is
        port (
            Datain  : in  STD_LOGIC_VECTOR (31 downto 0); -- Data input to register
            Dataout : out STD_LOGIC_VECTOR (31 downto 0); -- Data output from register
            Clk     : in  STD_LOGIC;                     -- Clock input
            Rst     : in  STD_LOGIC;                     -- Reset input
            WE      : in  STD_LOGIC                      -- Write enable
        );
    end component;

    component multiplexer2to1_32 is
        port (
            input1 : in  STD_LOGIC_VECTOR (31 downto 0); -- First data input
            input2 : in  STD_LOGIC_VECTOR (31 downto 0); -- Second data input
            output : out STD_LOGIC_VECTOR (31 downto 0); -- Selected output
            sel    : in  STD_LOGIC                      -- Select control
        );
    end component;

    component incrementor is
        port (
            input1 : in  STD_LOGIC_VECTOR (31 downto 0); -- First addend
            input2 : in  STD_LOGIC_VECTOR (31 downto 0); -- Second addend
            output : out STD_LOGIC_VECTOR (31 downto 0)  -- Sum output
        );
    end component;

    -- (Optional) Instruction memory RAM component, not used in PC logic here
    component RAM is
        port (
            clk       : in  std_logic;
            inst_addr : in  std_logic_vector(10 downto 0);
            inst_dout : out std_logic_vector(31 downto 0);
            data_we   : in  std_logic;
            data_addr : in  std_logic_vector(10 downto 0);
            data_din  : in  std_logic_vector(31 downto 0);
            data_dout : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Internal signals for PC pipeline and arithmetic
    signal pc_in        : std_logic_vector(31 downto 0); -- Next PC value into register
    signal pc_out       : std_logic_vector(31 downto 0); -- Current PC value from register
    signal incr_out     : std_logic_vector(31 downto 0); -- PC + 4 (sequential increment)
    signal incrImm_out  : std_logic_vector(31 downto 0); -- PC + 4 + immediate offset
    signal PC_Immed_red : std_logic_vector(31 downto 0); -- Reduced immediate (PC_Immed - 8)

begin
    -- PC register: holds the current PC value
    PC_reg: register32
        port map (
            Datain  => pc_in,
            Dataout => pc_out,
            Clk     => Clk,
            Rst     => Reset,
            WE      => PC_LdEn
        );

    -- Incrementor 1: calculate sequential next PC = PC + 4
    incr: incrementor
        port map (
            input1 => pc_out,
            input2 => x"00000004",  -- constant 4
            output => incr_out
        );

    -- Subtract 8 from immediate: prepare for branch calculation
    bis: incrementor
        port map (
            input1 => x"FFFF_FFF8",  -- two's complement (-8)
            input2 => PC_Immed,
            output => PC_Immed_red
        );

    -- Incrementor 2: add reduced immediate to sequential PC for branch target
    incrImm: incrementor
        port map (
            input1 => incr_out,
            input2 => PC_Immed_red,
            output => incrImm_out
        );

    -- Multiplexer: select between sequential PC or branch target
    MUX2to1: multiplexer2to1_32
        port map (
            input1 => incr_out,      -- sequential next PC
            input2 => incrImm_out,    -- branch target PC
            output => pc_in,          -- next PC into register
            sel    => PC_sel          -- 0 = sequential, 1 = branch
        );

    -- Output the current PC value
    PC <= pc_out;

end Behavioral;
