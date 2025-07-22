----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.03.2021 12:34:15
-- Design Name: 
-- Module Name: ImmedExtender - Behavioral
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
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ImmedExtender is
  Port (Immed:in std_logic_vector(15 downto 0);
        ImmedSel:in std_logic_vector(1 downto 0);
        Immed_out:out std_logic_vector(31 downto 0)
   );
end ImmedExtender;

architecture Behavioral of ImmedExtender is
signal signExtend:std_logic_vector(31 downto 0);
signal t_immed_out:std_logic_vector (31 downto 0);
begin
signExtend<=std_logic_vector(resize(signed(Immed),32));
with ImmedSel select 
t_Immed_out <= std_logic_vector(resize(unsigned(Immed), 32)) when "00",--zero filling when "00"
              signExtend when "01",                 --sign extend when "01"
             std_logic_vector(shift_left(unsigned(signExtend),2)) when "10",  --(sign extend and <<2)  when "10" 
             std_logic_vector(shift_left(unsigned(signExtend),16)) when others; --sign extend and <<16 when "11" 
Immed_out<= t_Immed_out  after 10ns;        

end Behavioral;
