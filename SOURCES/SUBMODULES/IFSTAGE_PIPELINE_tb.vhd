-- Testbench created online at:
--   https://www.doulos.com/knowhow/perl/vhdl-testbench-creation-using-perl/
-- Copyright Doulos Ltd

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity IFSTAGE_PIPELINE_tb is
end;

architecture bench of IFSTAGE_PIPELINE_tb is

  component IFSTAGE_PIPELINE
      Port ( PC_Immed : in STD_LOGIC_VECTOR (31 downto 0);
             PC_sel : in STD_LOGIC;
             PC_LdEn : in STD_LOGIC;
             Reset : in STD_LOGIC;
             Clk : in STD_LOGIC;
             PC : out STD_LOGIC_VECTOR (31 downto 0));
  end component;

COMPONENT RAM is
port (
    clk : in std_logic;
    inst_addr : in std_logic_vector(10 downto 0);
    inst_dout : out std_logic_vector(31 downto 0);
    data_we : in std_logic;
    data_addr : in std_logic_vector(10 downto 0);
    data_din : in std_logic_vector(31 downto 0);
    data_dout : out std_logic_vector(31 downto 0));
 end COMPONENT;
 


  signal PC_Immed: STD_LOGIC_VECTOR (31 downto 0);
  signal PC_sel: STD_LOGIC;
  signal PC_LdEn: STD_LOGIC;
  signal Reset: STD_LOGIC;
  signal Clk: STD_LOGIC;
  signal PC_out: STD_LOGIC_VECTOR (31 downto 0);
  signal inst_dout :  std_logic_vector(31 downto 0);
  constant clock_period: time := 100 ns;
  signal stop_the_clock: boolean;
  
  
begin

  uut: IFSTAGE_PIPELINE port map ( PC_Immed => PC_Immed,
                          PC_sel   => PC_sel,
                          PC_LdEn  => PC_LdEn,
                          Reset    => Reset,
                          Clk      => Clk,
                          PC       => PC_out );
                          
  memory:RAM
    port map(
    clk =>clk,
    inst_addr => PC_OUT(12 downto 2),
    inst_dout => inst_dout,
    data_we =>'0',
    data_addr =>(others =>'0'),
    data_din =>(others => '0'),
    data_dout =>open
    );

  stimulus: process
  begin
  
    -- Put initialisation code here
    PC_sel<='1';
   PC_LdEn<='1';
   Reset<='1';
   PC_immed<=x"00000002";
   wait for clock_period;
   reset<='0';
   wait for 2*clock_period;
   --Reset='0', start fetching instructions for 5 clock cycles
   --5 consecutive instructions.
   Reset<='0';
   wait for clock_period*5;
   
   --Load enable='0' for 2 clock cycles, should see the last instruction fetched
   PC_LdEn<='1';
   --asserting the right signals for a branch
   PC_sel<='0';
   wait for clock_period*2;
   
      PC_sel<='0';
   wait for clock_period*2;
   
      PC_sel<='1';
   
   PC_immed<=x"0000000f";
   wait for clock_period*2;
 PC_immed<=x"0000000c";
   wait for clock_period*2;
   
   PC_LdEn<='0';
   wait for clock_period*2;

    
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