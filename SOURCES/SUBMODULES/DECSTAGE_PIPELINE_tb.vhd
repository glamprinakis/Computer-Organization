-- Testbench created online at:
--   https://www.doulos.com/knowhow/perl/vhdl-testbench-creation-using-perl/
-- Copyright Doulos Ltd

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity DECSTAGE_PIPELINE_tb is
end;

architecture bench of DECSTAGE_PIPELINE_tb is

  component DECSTAGE_PIPELINE
      Port ( ReadRegister1: in std_logic_vector(4 downto 0);
         ReadRegister2: in std_logic_vector(4 downto 0);
         WriteRegister: in std_logic_vector(4 downto 0);
         Immediate: in std_logic_vector(15 downto 0);
         RF_WrEn : in std_logic;
         WrData : in std_logic_vector(31 downto 0);
 
 
         ImmExt : in std_logic_vector(1 downto 0);
         Clk : in std_logic;
         Immed : out std_logic_vector(31 downto 0);
         RST: in std_logic;
         RF_A : out std_logic_vector(31 downto 0);
         RF_B : out std_logic_vector(31 downto 0));
  end component;

  signal Instr: STD_LOGIC_VECTOR (31 downto 0);
  SIGNAL ReadRegister1:  std_logic_vector(4 downto 0);
  SIGNAL ReadRegister2:  std_logic_vector(4 downto 0);
 SIGNAL WriteRegister:  std_logic_vector(4 downto 0);
  signal RF_WrEn: STD_LOGIC;
  signal ALU_out: STD_LOGIC_VECTOR (31 downto 0);
  signal MEM_out: STD_LOGIC_VECTOR (31 downto 0);
  signal RF_WrData_sel: STD_LOGIC;
  signal RF_B_sel: STD_LOGIC;
  signal ImmExt: STD_LOGIC_VECTOR(1 DOWNTO 0);
  signal Clk: STD_LOGIC;
  signal rst: STD_LOGIC;
   SIGNAL WrData :  std_logic_vector(31 downto 0);
  signal Immed: STD_LOGIC_VECTOR (31 downto 0);
  signal Immediate: STD_LOGIC_VECTOR (15 downto 0);
  signal RF_A: STD_LOGIC_VECTOR (31 downto 0);
  signal RF_B: STD_LOGIC_VECTOR (31 downto 0);
  constant clock_period: time := 100 ns;
  signal stop_the_clock: boolean;
  
begin

  uut: DECSTAGE_PIPELINE port map ( ReadRegister1         => ReadRegister1,
                             ReadRegister2         => ReadRegister2,
                            WriteRegister         => WriteRegister,
                            Immediate         => Immediate,
                            RF_WrEn       => RF_WrEn,
                           WrData                  =>WrData,

                           ImmExt        => ImmExt,
                           Clk           => Clk,
                           rst           => rst,
                           Immed         => Immed,
                           RF_A          => RF_A,
                           RF_B          => RF_B );

  stimulus: process
  begin
  stop_the_clock <= false;
    -- Put initialisation code here
   
    ImmExt<="00";
rst<='1';
wait for clock_period;
rst<='0';
   --writing in register 1 the  imm ffff
   WriteRegister<="00001";
   RF_WrEn<='1';
   Immediate<=x"cccc";
   WrData<=x"ffffffff";
   
   wait for Clock_period;
   --writing in register 2 the contents of MEM and sign extend imm 1111
   WriteRegister<="00010";
     RF_WrEn<='1';
     
     WrData<=x"11111111";
   wait for Clock_period;
   --reading from registers 1 and 2 (reg2 address in bits 15-11)
   RF_WrEn<='0';
   ImmExt<="10";
   Immediate<=x"cccc";
   wait for Clock_period;
   
   ImmExt<="11";
   Immediate<=x"cccc";

   wait for Clock_period;
   ImmExt<="01";
   Immediate<=x"cccc";
   readRegister2<="00010";
   readRegister1<="00001";
   
   wait for Clock_period;


   

    -- Put test bench stimulus code here
stop_the_clock <= true;
    wait;
  end process;
  
clocking: process
  begin
    while not stop_the_clock loop
      Clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;
end;