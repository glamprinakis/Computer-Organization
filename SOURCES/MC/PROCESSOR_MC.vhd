----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.04.2021 21:39:25
-- Design Name: 
-- Module Name: PROC_SC - Behavioral
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

entity PROCESSOR_MC is
  Port (
  clk:IN STD_LOGIC;
  RESET:IN STD_LOGIC;
  inst_addr : out std_logic_vector(31 downto 0);
  inst_dout : in std_logic_vector(31 downto 0);
  data_we : out std_logic;
  data_addr : out std_logic_vector(31 downto 0);
  data_din : out std_logic_vector(31 downto 0);
  data_dout : in std_logic_vector(31 downto 0)
  );
end PROCESSOR_MC;

architecture Behavioral of PROCESSOR_MC is
component DATAPATH_MC
    Port ( 
             PC_sel : in STD_LOGIC;
             PC_LdEn : in STD_LOGIC;
             Reset : in STD_LOGIC;
             Clk : in STD_LOGIC;
             PC : out STD_LOGIC_VECTOR (31 downto 0);
             Instr : in std_logic_vector(31 downto 0);
              RF_WrEn : in std_logic;
              RF_WrData_sel : in std_logic;
              RF_B_sel : in std_logic;
              ImmExt : in std_logic_vector(1 downto 0);
              ALU_zero : out STD_LOGIC;
              ALU_func : in STD_LOGIC_VECTOR (3 downto 0);
              ALU_Bin_sel : in STD_LOGIC;
              ByteOp : in std_logic;
              Mem_WrEn : in std_logic;
              MM_WrEn : out std_logic;
              MM_Addr : out std_logic_vector(31 downto 0);
              MM_WrData : out std_logic_vector(31 downto 0);
              MM_RdData : in std_logic_vector(31 downto 0)
             );
  end component;
  
    component CONTROL_MC
    Port (opcode : in STD_LOGIC_VECTOR (5 downto 0);
           zero: in std_logic;
           func : in STD_LOGIC_VECTOR (5 downto 0);
           Clock : in STD_LOGIC;
           Rst : in STD_LOGIC;
           ALU_func : out STD_LOGIC_VECTOR (3 downto 0);
           PC_sel : out STD_LOGIC;
           PC_LdEn : out STD_LOGIC;
            RF_WrEn : out std_logic;
            RF_WrData_sel : out std_logic;
            RF_B_sel : out std_logic;
            ImmExt : out std_logic_vector(1 downto 0);
            ALU_Bin_sel : out STD_LOGIC;
            ByteOp : out std_logic;
            Mem_WrEn : out std_logic );
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
     

signal t_ALU_zero: std_logic;
signal t_ALU_Func: std_logic_vector(3 downto 0);
signal t_PC_Sel: std_logic;
signal t_RF_WrData_sel: std_logic;
signal t_RF_WrEn: std_logic;
signal t_RF_B_sel: std_logic;
signal t_ImmExt: std_logic_vector(1 downto 0);
signal t_ALU_Bin_sel: std_logic;
signal t_ByteOp: std_logic;
signal t_Mem_WrEn: std_logic;
signal t_PC_LdEn: std_logic;


begin

--memory:RAM
--    port map(
--    clk =>clk,
--    inst_addr => t_PC(12 downto 2),
--    inst_dout => t_Instr,
--    data_we =>t_MM_WrEn,
--    data_addr =>t_MM_addr(12 downto 2 ),
--    data_din =>t_MM_WrData,
--    data_dout =>t_MM_RdData
--    );
  DATA: DATAPATH_MC port map ( PC_sel        => t_PC_sel,
                           PC_LdEn       => t_PC_LdEn,
                           Reset         => Reset,
                           Clk           => Clk,
                           PC            => inst_addr,
                           Instr         => inst_dout,
                           RF_WrEn       => t_RF_WrEn,
                           RF_WrData_sel => t_RF_WrData_sel,
                           RF_B_sel      => t_RF_B_sel,
                           ImmExt        => t_ImmExt,
                           ALU_zero      => t_ALU_zero,
                           ALU_func      => t_ALU_func,
                           ALU_Bin_sel   => t_ALU_Bin_sel,
                           ByteOp        => t_ByteOp,
                           Mem_WrEn      => t_Mem_WrEn,
                           MM_WrEn       => data_we,
                           MM_Addr       => data_addr,
                           MM_WrData     => data_din,
                           MM_RdData     => data_dout );

 CON: CONTROL_MC port map ( opcode        => inst_dout(31 downto 26),
                          zero          => t_ALU_zero,
                          func          => inst_dout(5 downto 0),
                          Rst         => Reset,
                          Clock           => Clk,
                          ALU_func      => t_ALU_func,
                          PC_sel        => t_PC_sel,
                          PC_LdEn       => t_PC_LdEn,
                          RF_WrEn       => t_RF_WrEn,
                          RF_WrData_sel => t_RF_WrData_sel,
                          RF_B_sel      => t_RF_B_sel,
                          ImmExt        => t_ImmExt,
                          ALU_Bin_sel   => t_ALU_Bin_sel,
                          ByteOp        => t_ByteOp,
                          Mem_WrEn      => t_Mem_WrEn );

end Behavioral;
