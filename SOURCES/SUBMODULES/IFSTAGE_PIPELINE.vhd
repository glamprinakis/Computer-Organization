----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.03.2021 11:58:35
-- Design Name: 
-- Module Name: IFSTAGE - Behavioral
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


--add a new incrementor which subtracts 8 from immediate
entity IFSTAGE_PIPELINE is
    Port ( PC_Immed : in STD_LOGIC_VECTOR (31 downto 0);
           PC_sel : in STD_LOGIC;
           PC_LdEn : in STD_LOGIC;
           Reset : in STD_LOGIC;
           Clk : in STD_LOGIC;
           PC : out STD_LOGIC_VECTOR (31 downto 0));
end IFSTAGE_PIPELINE;

architecture Behavioral of IFSTAGE_PIPELINE is
    COMPONENT register32 is
    port (Datain : in STD_LOGIC_VECTOR (31 downto 0);
           Dataout : out STD_LOGIC_VECTOR (31 downto 0);
           Clk : in STD_LOGIC;
           Rst : in STD_LOGIC;
           WE : in STD_LOGIC
    );
    end component;
     COMPONENT multiplexer2to1_32 is
        port (input1: in STD_LOGIC_VECTOR (31 downto 0);
              input2: in STD_LOGIC_VECTOR (31 downto 0);
              output : out STD_LOGIC_VECTOR (31 downto 0);
              sel : in STD_LOGIC
           
    );
    end component;
    COMPONENT incrementor is
        port (input1: in STD_LOGIC_VECTOR (31 downto 0);
              input2: in STD_LOGIC_VECTOR (31 downto 0);
              output : out STD_LOGIC_VECTOR (31 downto 0)
              );
    end component;
    
    component RAM is
port (
    clk : in std_logic;
    inst_addr : in std_logic_vector(10 downto 0);
    inst_dout : out std_logic_vector(31 downto 0);
    data_we : in std_logic;
    data_addr : in std_logic_vector(10 downto 0);
    data_din : in std_logic_vector(31 downto 0);
    data_dout : out std_logic_vector(31 downto 0));
 end component;
 signal pc_in,pc_out,incr_out,incrImm_out:std_logic_vector(31 downto 0);
  signal PC_Immed_red:std_logic_vector(31 downto 0);
begin
    
    PC_reg:register32
    port map(
    datain=>pc_in,
    dataout=>pc_out,
    clk=>clk,
    rst=>reset,
    WE=>pc_LdEn
    
    );
    
    incr:incrementor
    port map(
    input1=>pc_out,
    input2=>x"00000004",
    output=>incr_out
    );
    
    incrImm:incrementor
    port map(
    input1=>incr_out,
    input2=>PC_Immed_red,
    output=>incrImm_out
    );
    
     bis:incrementor
    port map(
    input1=>x"fffffff8",
    input2=>PC_Immed,
    output=>PC_Immed_red
    );

    MUX2to1:multiplexer2to1_32
    port map(
    input1=>incr_out,
    input2=>incrImm_out,
    output=>PC_in,
    sel=>PC_sel
    );
    
    pc<=pc_out;
end Behavioral;
