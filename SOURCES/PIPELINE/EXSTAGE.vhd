library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration for the EXSTAGE (Execute Stage) of a pipelined processor
entity EXSTAGE is
    Port (
        -- Operand A from register file
        RF_A         : in  STD_LOGIC_VECTOR (31 downto 0);
        -- Operand B from register file (or used as second ALU input when sel=0)
        RF_B         : in  STD_LOGIC_VECTOR (31 downto 0);
        -- Immediate value (used as second ALU input when sel=1)
        Immed        : in  STD_LOGIC_VECTOR (31 downto 0);
        -- Select between RF_B and Immed to feed the ALU’s B port
        ALU_Bin_sel  : in  STD_LOGIC;
        -- ALU operation code (4‑bit)
        ALU_func     : in  STD_LOGIC_VECTOR (3 downto 0);
        -- Result from the ALU
        ALU_out      : out STD_LOGIC_VECTOR (31 downto 0);
        -- Flag indicating ALU output is zero
        ALU_zero     : out STD_LOGIC
    );
end EXSTAGE;

architecture Behavioral of EXSTAGE is

    -- ALU component: performs the arithmetic/logic operation
    component ALU is
        Port (
            A      : in  STD_LOGIC_VECTOR (31 downto 0);
            B      : in  STD_LOGIC_VECTOR (31 downto 0);
            Op     : in  STD_LOGIC_VECTOR (3 downto 0);
            Output : out STD_LOGIC_VECTOR (31 downto 0);
            Zero   : out STD_LOGIC;
            Cout   : out STD_LOGIC;  -- carry-out, not used here
            Ovf    : out STD_LOGIC   -- overflow, not used here
        );
    end component;

    -- 2-to-1 32‑bit multiplexer component: selects between two inputs
    component multiplexer2to1_32 is
        port (
            input1 : in  STD_LOGIC_VECTOR (31 downto 0);
            input2 : in  STD_LOGIC_VECTOR (31 downto 0);
            output : out STD_LOGIC_VECTOR (31 downto 0);
            sel     : in STD_LOGIC
        );
    end component;

    -- Internal signal to hold the selected ALU B input
    signal mux_out : STD_LOGIC_VECTOR (31 downto 0);

begin

    -- Instantiate the ALU, connecting RF_A to A, mux_out to B,
    -- and wiring control/function and result signals.
    ALUinstance: ALU
        Port map (
            A      => RF_A,       -- first ALU operand
            B      => mux_out,    -- second ALU operand (from mux)
            Op     => ALU_func,   -- ALU operation code
            Output => ALU_out,    -- ALU result
            Zero   => ALU_zero,   -- zero flag
            Cout   => open,       -- unused carry-out
            Ovf    => open        -- unused overflow flag
        );

    -- Instantiate the 32‑bit multiplexer:
    -- when ALU_Bin_sel='0', RF_B is passed to mux_out; when '1', Immed is passed.
    mux32: multiplexer2to1_32
        port map (
            input1 => RF_B,           -- register file B output
            input2 => Immed,          -- immediate value
            sel    => ALU_Bin_sel,    -- select signal
            output => mux_out         -- feeds ALU B input
        );

end Behavioral;
