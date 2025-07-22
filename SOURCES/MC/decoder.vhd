----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.03.2021 01:00:49
-- Design Name: 
-- Module Name: decoder - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity decoder is
    Port ( awr : in STD_LOGIC_VECTOR (4 downto 0);
           decoderoutput : out STD_LOGIC_VECTOR (31 downto 0));
end decoder;

architecture Behavioral of decoder is
signal temp_out: std_logic_vector(31 downto 0);
begin
 
    with awr select
    temp_out<=x"00000001" when "00000",
              x"00000002" when "00001",
              x"00000004" when "00010",
              x"00000008" when "00011",
              x"00000010" when "00100",
              x"00000020" when "00101",
              x"00000040" when "00110",
              x"00000080" when "00111",
              x"00000100" when "01000",
              x"00000200" when "01001",
              x"00000400" when "01010",
              x"00000800" when "01011",
              x"00001000" when "01100",
              x"00002000" when "01101",
              x"00004000" when "01110",
              x"00008000" when "01111",
              x"00010000" when "10000",
              x"00020000" when "10001",
              x"00040000" when "10010",
              x"00080000" when "10011",
              x"00100000" when "10100",
              x"00200000" when "10101",
              x"00400000" when "10110",
              x"00800000" when "10111",
              x"01000000" when "11000",
              x"02000000" when "11001",
              x"04000000" when "11010",
              x"08000000" when "11011",
              x"10000000" when "11100",
              x"20000000" when "11101",
              x"40000000" when "11110",
              x"80000000" when others;
              
  decoderoutput<=temp_out;            
end Behavioral;
