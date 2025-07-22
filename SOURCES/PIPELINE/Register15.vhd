library IEEE;                      
use IEEE.STD_LOGIC_1164.ALL;     

-- Entity declaration for a 15‑bit register
entity Register15 is
    Port (
        Datain  : in  STD_LOGIC_VECTOR (14 downto 0);  -- 15‑bit data input
        Dataout : out STD_LOGIC_VECTOR (14 downto 0);  -- 15‑bit data output
        Clk     : in  STD_LOGIC;                       -- Clock input (rising edge triggered)
        Rst     : in  STD_LOGIC;                       -- Synchronous reset (active high)
        WE      : in  STD_LOGIC                        -- Write enable (active high)
    );
end Register15;

-- Architecture defining the register behavior
architecture Behavioral of Register15 is
    -- Internal signal to hold the register state
    signal temp_output : STD_LOGIC_VECTOR (14 downto 0);
begin

    -- Synchronous process: triggered on the rising edge of Clk
    process
    begin
        wait until Clk'event and Clk = '1';  -- wait for rising edge of clock

        -- Check for synchronous reset first
        if Rst = '1' then
            temp_output <= (others => '0');  -- clear register to all zeros
        -- If reset is not asserted, check write enable
        elsif WE = '1' then
            temp_output <= Datain;           -- load new data into register
        end if;
    end process;

    -- Output assignment with inertial delay to model register output timing
    dataout <= temp_output after 10 ns;

end Behavioral;
