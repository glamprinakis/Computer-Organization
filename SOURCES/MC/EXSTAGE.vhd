----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.03.2021 14:59:38
-- Design Name: 
-- Module Name: EXSTAGE - Behavioral
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

entity EXSTAGE is
    Port ( RF_A : in STD_LOGIC_VECTOR (31 downto 0);
           RF_B : in STD_LOGIC_VECTOR (31 downto 0);
           Immed : in STD_LOGIC_VECTOR (31 downto 0);
           ALU_Bin_sel : in STD_LOGIC;
           ALU_func : in STD_LOGIC_VECTOR (3 downto 0);
           ALU_out : out STD_LOGIC_VECTOR (31 downto 0);
           ALU_zero : out STD_LOGIC);
end EXSTAGE;

architecture Behavioral of EXSTAGE is
component ALU is
Port ( 
 A: in std_logic_vector(31 downto 0);
 B: in std_logic_vector(31 downto 0);
 Op: in std_logic_vector(3 downto 0);
 Output: out std_logic_vector(31 downto 0);
 Zero: out std_logic;
 Cout: out std_logic;
 Ovf: out std_logic);
end component;

COMPONENT multiplexer2to1_32 is
        port (input1: in STD_LOGIC_VECTOR (31 downto 0);
              input2: in STD_LOGIC_VECTOR (31 downto 0);
              output : out STD_LOGIC_VECTOR (31 downto 0);
              sel : in STD_LOGIC);
    end component;
    signal mux_out:std_logic_vector(31 downto 0);
begin
ALUinstance:ALU 
Port map ( 
     A=>RF_A,
     B=>mux_out,
     Op=>ALU_func,
     Output=>ALU_out,
     Zero=>ALU_zero,
     Cout=>open,
     Ovf=>open);
     
mux32: multiplexer2To1_32
port map(
        input1=>RF_B,
        input2=>Immed,
        sel=>ALU_Bin_sel,
        output=>mux_out
);
end Behavioral;
