----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.03.2021 13:39:42
-- Design Name: 
-- Module Name: Register - Behavioral
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

entity Register5 is
    Port ( Datain : in STD_LOGIC_VECTOR (4 downto 0);
           Dataout : out STD_LOGIC_VECTOR (4 downto 0);
           Clk : in STD_LOGIC;
           Rst : in STD_LOGIC;
           WE : in STD_LOGIC);
end Register5;

architecture Behavioral of Register5 is
signal temp_output :STD_LOGIC_VECTOR (4 downto 0);


begin
    
    process
    begin
     wait until Clk'event and Clk='1';
      if Rst='1'then
        temp_output <= (others =>'0') ;
      elsif WE = '1' then
        temp_output<= Datain ;

      end if;
    end process;
dataout<=temp_output  after 10ns;
end Behavioral;
