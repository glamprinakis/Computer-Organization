library IEEE;
use IEEE.STD_LOGIC_1164.ALL;       
use IEEE.NUMERIC_STD.ALL;          

-- Entity declaration for a simple 32‑bit adder (“incrementor”)
entity incrementor is
    Port (
        input1 : in  STD_LOGIC_VECTOR(31 downto 0);  -- First 32‑bit operand
        input2 : in  STD_LOGIC_VECTOR(31 downto 0);  -- Second 32‑bit operand
        output : out STD_LOGIC_VECTOR(31 downto 0)   -- 32‑bit sum result
    );
end incrementor;

-- Architecture defining the internal workings of the incrementor
architecture Behavioral of incrementor is
    -- Internal signal to hold the signed sum of input1 and input2
    signal t_out : signed(31 downto 0);
begin

    -- Convert input vectors to signed, add them, and assign to internal signal
    t_out <= signed(input1) + signed(input2);

    -- Convert the resulting signed sum back to std_logic_vector for output
    output <= std_logic_vector(t_out);

end Behavioral;
