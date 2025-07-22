-- Register File Implementation in VHDL with Comments

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;      
use IEEE.NUMERIC_STD.ALL;         

-- Entity declaration for a 32x32 Register File
entity RegisterFile is
    Port (
        Ard1  : in  STD_LOGIC_VECTOR(4 downto 0);  -- Read address 1 (5 bits selects 1 of 32 registers)
        Ard2  : in  STD_LOGIC_VECTOR(4 downto 0);  -- Read address 2
        Awr   : in  STD_LOGIC_VECTOR(4 downto 0);  -- Write address
        Dout1 : out STD_LOGIC_VECTOR(31 downto 0); -- Data output for read port 1
        Dout2 : out STD_LOGIC_VECTOR(31 downto 0); -- Data output for read port 2
        Din   : in  STD_LOGIC_VECTOR(31 downto 0); -- Data input for write port
        WrEn  : in  STD_LOGIC;                    -- Global write enable signal
        rst   : in  STD_LOGIC;                    -- Synchronous reset for all registers
        Clk   : in  STD_LOGIC                     -- Clock signal
    );
end RegisterFile;

-- Architecture that instantiates a decoder and 32 registers
architecture Behavioral of RegisterFile is

    -- Decoder component: one-hot encode the 5-bit write address
    component decoder is
        Port (
            awr           : in  STD_LOGIC_VECTOR(4 downto 0);  -- Write address input
            decoderoutput : out STD_LOGIC_VECTOR(31 downto 0)  -- One-hot output to select register
        );
    end component;

    -- 32-bit register component with write enable and reset
    component Register32 is
        Port (
            Datain  : in  STD_LOGIC_VECTOR(31 downto 0); -- Input data bus
            Dataout : out STD_LOGIC_VECTOR(31 downto 0); -- Output data bus
            Clk     : in  STD_LOGIC;                    -- Clock
            Rst     : in  STD_LOGIC;                    -- Synchronous reset
            WE      : in  STD_LOGIC                     -- Write enable for this register
        );
    end component;

    -- Internal signals
    signal decoderOutput : STD_LOGIC_VECTOR(31 downto 0);      -- One-hot select signals from decoder
    signal temp          : STD_LOGIC_VECTOR(31 downto 0);      -- Masked write-enable signals for each register

    -- Array of 32 registers, each 32 bits wide
    type Outputs is array (0 to 31) of STD_LOGIC_VECTOR(31 downto 0);
    signal Output : Outputs;

begin
    -- Instantiate the address decoder
    dec: decoder
        port map (
            awr           => Awr,
            decoderoutput => decoderOutput
        );

    -- Register 0 is hard-wired to zero (read-only zero register)
    zero: Register32
        port map (
            Datain  => (others => '0'),  -- Always zero
            Clk     => Clk,
            WE      => '1',              -- Always "write" zero into it to hold zero
            Rst     => rst,
            Dataout => Output(0)         -- Connect to Output array index 0
        );

    -- Generate block for registers 1 to 31
    gen: for i in 1 to 31 generate
        -- Mask the global write enable with the decoder output bit for register i
        temp(i) <= decoderOutput(i) and WrEn after 2 ns;

        -- Instantiate each 32-bit register
        reg: Register32
            port map (
                Datain  => Din,         -- Data input bus
                Clk     => Clk,         -- Clock
                WE      => temp(i),     -- Individual write enable for register i
                Rst     => rst,         -- Synchronous reset
                Dataout => Output(i)    -- Connect to Output array index i
            );
    end generate gen;

    -- Read ports: output the contents of the selected registers
    Dout1 <= Output(to_integer(unsigned(Ard1))) after 10 ns;  -- Read port 1 with 10 ns delay
    Dout2 <= Output(to_integer(unsigned(Ard2))) after 10 ns;  -- Read port 2

end Behavioral;
