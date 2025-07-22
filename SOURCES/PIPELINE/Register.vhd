library IEEE;                               
use IEEE.STD_LOGIC_1164.ALL;               

-- Entity declaration for a 32‑bit register with clock, reset, and write enable
entity Register32 is
    Port (
        Datain  : in  STD_LOGIC_VECTOR(31 downto 0);  -- 32‑bit input data bus
        Dataout : out STD_LOGIC_VECTOR(31 downto 0);  -- 32‑bit output data bus
        Clk     : in  STD_LOGIC;                      -- Clock input (rising‑edge)
        Rst     : in  STD_LOGIC;                      -- Synchronous reset (active high)
        WE      : in  STD_LOGIC                       -- Write enable (active high)
    );
end Register32;

architecture Behavioral of Register32 is
    -- Internal signal to hold the register’s state
    signal temp_output : STD_LOGIC_VECTOR(31 downto 0);
begin

    -- Process triggered on the rising edge of Clk
    process
    begin
        wait until Clk'event and Clk = '1';          -- Wait for clock rising edge
        if Rst = '1' then                            -- If reset is asserted
            temp_output <= (others => '0');          --   clear register to all zeros
        elsif WE = '1' then                          -- Else if write enable is high
            temp_output <= Datain;                   --   load new data into register
        end if;
    end process;

    -- Registered output, with a propagation delay of 10 ns
    Dataout <= temp_output after 10 ns;

end Behavioral;
