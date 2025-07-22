----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.03.2021 14:16:26
-- Design Name: 
-- Module Name: multiplexer2to1 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity multiplexer2to1_5 is
    Port ( input1 : in STD_LOGIC_VECTOR (4 downto 0);
           input2 : in STD_LOGIC_VECTOR (4 downto 0);
           sel : in STD_LOGIC;
           output : out STD_LOGIC_VECTOR (4 downto 0));
end multiplexer2to1_5;

architecture Behavioral of multiplexer2to1_5 is

begin
output <= input1 when (sel='0') else
          input2 ;

end Behavioral;
