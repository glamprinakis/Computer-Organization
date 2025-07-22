-- 5-to-32 Line Decoder 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;       
use IEEE.NUMERIC_STD.ALL;          

entity decoder is
    Port (
        awr            : in  STD_LOGIC_VECTOR(4 downto 0);  -- 5-bit input address
        decoderoutput : out STD_LOGIC_VECTOR(31 downto 0)  -- 32-bit one-hot output
    );
end decoder;

architecture Behavioral of decoder is
begin

    -- 1) Convert constant 1 to a 32-bit unsigned vector.
    -- 2) Shift it left by the integer value of 'awr'.
    -- 3) Convert the result back to std_logic_vector for output.
    decoderoutput <= std_logic_vector(
        shift_left(
            to_unsigned(1, 32),                -- '1' at LSB of 32-bit unsigned
            to_integer(unsigned(awr))         -- shift amount from input address
        )
    );

end Behavioral;
