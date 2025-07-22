----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.03.2021 13:32:21
-- Design Name: 
-- Module Name: RegisterFile - Behavioral
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

entity RegisterFile is
    Port ( Ard1 : in STD_LOGIC_VECTOR (4 downto 0);
           Ard2 : in STD_LOGIC_VECTOR (4 downto 0);
           Awr : in STD_LOGIC_VECTOR (4 downto 0);
           Dout1 : out STD_LOGIC_VECTOR (31 downto 0);
           Dout2 : out STD_LOGIC_VECTOR (31 downto 0);
           Din : in STD_LOGIC_VECTOR (31 downto 0);
           WrEn : in STD_LOGIC;
           rst: in std_logic;
           Clk : in STD_LOGIC);
end RegisterFile;

architecture Behavioral of RegisterFile is

component decoder is
    Port ( awr : in STD_LOGIC_VECTOR (4 downto 0);
         decoderoutput : out STD_LOGIC_VECTOR (31 downto 0));
end component;


  
    component Register32 is
    Port ( Datain : in STD_LOGIC_VECTOR (31 downto 0);
           Dataout : out STD_LOGIC_VECTOR (31 downto 0);
           Clk : in STD_LOGIC;
           Rst : in STD_LOGIC;
           WE : in STD_LOGIC);
    end component;
    
    

    signal decoderOutput: std_logic_vector (31 downto 0);--the output of the decoder
    signal temp:std_logic_vector(31 downto 0);--decoderoutput AND wrEn
    Type Outputs is array ( 0 to 31) of std_logic_vector( 31 downto 0); --the output of every register  
    Signal output: Outputs;
    
begin
    dec :decoder
    port map(
    awr=>awr,
    decoderoutput=>decoderoutput);

    --asign register zero to output(0) and set datain to all zeros
    zero:register32
        port map(
        Datain=>(others=>'0'),
        Clk=>clk,
        WE=> '1',
        rst=>rst,
        Dataout=>Output(0)
        );
    --assign registers from 1 to 31 to each output
    gen: for i in 1 to 31 generate
        temp(i)<=decoderOutput(i) and WrEn  after 2ns;
    
        reg:register32
        port map(
        Datain=>Din,
        Clk=>clk,
        WE=> temp(i),
        rst=>rst,
        Dataout=>Output(i)
        );
    end generate gen;

    --choosing the outputs of the two registers corresponding to ard1 and ard2 (equivalent to a mux 32 to 1 (32 bits))
    Dout1 <= Output(to_integer(unsigned(Ard1))) after 10ns;
    Dout2 <= Output(to_integer(unsigned(Ard2)))  after 10ns;
    
end Behavioral;
