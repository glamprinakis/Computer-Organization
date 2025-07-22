library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity PROCESSOR_PIPELINE_tb is
end;

architecture bench of PROCESSOR_PIPELINE_tb is

  component PROCESSOR_PIPELINE
   Port (
         Reset : in std_logic;
         clk: in std_logic;
           inst_addr : out std_logic_vector(31 downto 0);
         inst_dout : in std_logic_vector(31 downto 0);
         data_we : out std_logic;
         data_addr : out std_logic_vector(31 downto 0);
         data_din : out std_logic_vector(31 downto 0);
         data_dout : in std_logic_vector(31 downto 0)
    );
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

signal Reset: std_logic;
signal clk: std_logic ;

signal t_MM_RdData: std_logic_vector(31 downto 0);
signal t_PC: std_logic_vector(31 downto 0);

signal t_MM_WrEn: std_logic;
signal t_MM_WrData: std_logic_vector(31 downto 0);
signal t_MM_Addr: std_logic_vector(31 downto 0);
signal t_instr: std_logic_vector(31 downto 0);
constant Clk_period : time := 100 ns;


begin

  uut: PROCESSOR_PIPELINE port map ( Reset => Reset,
                          clk   => clk ,
                          inst_addr =>t_PC,
                          inst_dout =>t_Instr,
                          data_we =>t_MM_WrEn,
                          data_addr =>t_MM_addr,
                          data_din =>t_MM_WrData,
                          data_dout =>t_MM_RdData);
                          
   memory:RAM
                              port map(
                              clk =>clk,
                              inst_addr => t_PC(12 downto 2),
                              inst_dout => t_Instr,
                              data_we =>t_MM_WrEn,
                              data_addr =>t_MM_addr(12 downto 2 ),
                              data_din =>t_MM_WrData,
                              data_dout =>t_MM_RdData
                              );                       
                          -- Clock process definitions
   Clk_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;



  stimulus: process
  begin
  
    wait for 100ns;




    Reset<='1';
    wait for 5*clk_period;

    Reset<='0';

    wait;
  end process;


end;