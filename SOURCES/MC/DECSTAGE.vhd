library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DECSTAGE is
  Port ( 
        Instr : in std_logic_vector(31 downto 0);
        RF_WrEn : in std_logic;
        ALU_out : in std_logic_vector(31 downto 0);
        MEM_out : in std_logic_vector(31 downto 0);
        RF_WrData_sel : in std_logic;
        RF_B_sel : in std_logic;
        ImmExt : in std_logic_vector(1 downto 0);
        Clk : in std_logic;
        Immed : out std_logic_vector(31 downto 0);
        RST: in std_logic;
        RF_A : out std_logic_vector(31 downto 0);
        RF_B : out std_logic_vector(31 downto 0)
  
  );
end DECSTAGE;

architecture Behavioral of DECSTAGE is

component ImmedExtender is
 Port (
        Immed : in std_logic_vector(15 downto 0);
        immedsel : in std_logic_vector(1 downto 0);
        Immed_Out : out std_logic_vector(31 downto 0)
  );
  
end component;

component RegisterFIle is
    Port ( Ard1 : in STD_LOGIC_VECTOR (4 downto 0);
           Ard2 : in STD_LOGIC_VECTOR (4 downto 0);
           Awr : in STD_LOGIC_VECTOR (4 downto 0);
           Dout1 : out STD_LOGIC_VECTOR (31 downto 0);
           Dout2 : out STD_LOGIC_VECTOR (31 downto 0);
           Din : in STD_LOGIC_VECTOR (31 downto 0);
           RST: in std_logic;
           WrEn : in STD_LOGIC;
           Clk : in STD_LOGIC);
end component;

component multiplexer2To1_5 is
 Port ( 
       input1 : in std_logic_vector(4 downto 0);
       input2 : in std_logic_vector(4 downto 0);
       output : out std_logic_vector(4 downto 0);
       Sel : in std_logic
 );
end component;


component multiplexer2To1_32 is
    Port ( input1 : in STD_LOGIC_VECTOR (31 downto 0);
           input2 : in STD_LOGIC_VECTOR (31 downto 0);
           sel: in std_logic;
           output : out STD_LOGIC_VECTOR (31 downto 0));
end component;

signal t_WrData : STD_LOGIC_VECTOR (31 downto 0);
signal t_readRegister2 : STD_LOGIC_VECTOR (4 downto 0);
signal opcode : STD_LOGIC_VECTOR (5 downto 0);

begin

mux32: multiplexer2To1_32
port map(
        input1=>ALU_out,
        input2=>MEM_out,
        sel=>RF_WrData_sel,
        output=>t_wrData
);

mux5: multiplexer2To1_5
port map(
        input1=>Instr(15 downto 11),
        input2=>Instr(20 downto 16),
        Sel=>RF_B_sel,
        output=>t_readRegister2
);

ImmediateExtender: ImmedExtender
port map(
        Immed=>Instr(15 downto 0),
        immedSel=>ImmExt,
        Immed_Out=>Immed
);

RF:RegisterFile
port map(
        Ard1=>Instr(25 downto 21),
        Ard2=>t_readRegister2,
        Awr=>Instr(20 downto 16),
        Dout1=>RF_A,
        Dout2=>RF_B,
        Din=>t_WrData,
        WrEn=>RF_WrEn,
        Clk=>Clk,
        RST=>RST
             
);
opcode<=instr(31 downto 26);

end Behavioral;