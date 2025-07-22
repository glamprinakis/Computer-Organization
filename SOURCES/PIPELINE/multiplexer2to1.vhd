
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity multiplexer2to1_32 is
    Port ( input1 : in STD_LOGIC_VECTOR (31 downto 0);
           input2 : in STD_LOGIC_VECTOR (31 downto 0);
           sel : in STD_LOGIC;
           output : out STD_LOGIC_VECTOR (31 downto 0));
end multiplexer2to1_32;

architecture Behavioral of multiplexer2to1_32 is

begin
output <= input1 when (sel='0') else
          input2 ;

end Behavioral;
