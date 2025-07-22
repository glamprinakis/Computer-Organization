----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.04.2021 11:37:21
-- Design Name: 
-- Module Name: DATAPATH - Behavioral
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

entity DATAPATH_MC is
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
end DATAPATH_MC;

architecture Behavioral of DATAPATH_MC is

component IFSTAGE
      Port ( PC_Immed : in STD_LOGIC_VECTOR (31 downto 0);
             PC_sel : in STD_LOGIC;
             PC_LdEn : in STD_LOGIC;
             Reset : in STD_LOGIC;
             Clk : in STD_LOGIC;
             PC : out STD_LOGIC_VECTOR (31 downto 0));
  end component;
COMPONENT register32 is
      port (Datain : in STD_LOGIC_VECTOR (31 downto 0);
             Dataout : out STD_LOGIC_VECTOR (31 downto 0);
             Clk : in STD_LOGIC;
             Rst : in STD_LOGIC;
             WE : in STD_LOGIC
      );
      end component;
COMPONENT DECSTAGE is
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
  END COMPONENT;
  
  COMPONENT EXSTAGE is
    Port ( RF_A : in STD_LOGIC_VECTOR (31 downto 0);
           RF_B : in STD_LOGIC_VECTOR (31 downto 0);
           Immed : in STD_LOGIC_VECTOR (31 downto 0);
           ALU_Bin_sel : in STD_LOGIC;
           ALU_func : in STD_LOGIC_VECTOR (3 downto 0);
           ALU_out : out STD_LOGIC_VECTOR (31 downto 0);
           ALU_zero : out STD_LOGIC);
end COMPONENT;

COMPONENT MEMSTAGE is
  Port (
       
       ByteOp : in std_logic;
       Mem_WrEn : in std_logic;
       MM_WrEn : out std_logic;
       ALU_MEM_Addr : in std_logic_vector(31 downto 0);
       MEM_DataIn : in std_logic_vector(31 downto 0);
       MEM_DataOut : out std_logic_vector(31 downto 0);
       MM_Addr : out std_logic_vector(31 downto 0);
       MM_WrData : out std_logic_vector(31 downto 0);
       MM_RdData : in std_logic_vector(31 downto 0)
   );
end COMPONENT;

SIGNAL t_immed,t_immed_out:std_logic_vector(31 downto 0);
SIGNAL instr_out:std_logic_vector(31 downto 0);
SIGNAL t_WRDATA,t_RDDATA:std_logic_vector(31 downto 0);
signal t_ALU_out,t_ALU,t_MEM_out:std_logic_vector(31 downto 0);
signal t_RF_A,t_RF_A_OUT,t_RF_B,t_RF_B_OUT:std_logic_vector(31 downto 0);

begin

IFS: IFSTAGE port map ( PC_Immed => t_immed,
                          PC_sel   => PC_sel,
                          PC_LdEn  => PC_LdEn,
                          Reset    => Reset,
                          Clk      => Clk,
                          PC       => PC );
INSTR_REG:register32
                              port map(
                              datain=>Instr,
                              dataout=>instr_out,
                              clk=>clk,
                              rst=>reset,
                              WE=>'1'
                              
                              );                          
                          
DEC: DECSTAGE port map ( Instr         => instr_out,
                           RF_WrEn       => RF_WrEn,
                           ALU_out       => t_ALU_out,
                           MEM_out       => t_MEM_out,
                           RF_WrData_sel => RF_WrData_sel,
                           RF_B_sel      => RF_B_sel,
                           ImmExt        => ImmExt,
                           Clk           => Clk,
                           rst           => reset,
                           Immed         => t_Immed,
                           RF_A          => t_RF_A,
                           RF_B          => t_RF_B );
                           
IMMED_REG:register32
                                port map(
                                datain=>t_Immed,
                                dataout=>t_immed_out,
                                clk=>clk,
                                rst=>reset,
                                WE=>'1'
                                                         
                                );
RFA_REG:register32
                      port map(
                       datain=>t_RF_A,
                       dataout=>t_RF_A_OUT,
                       clk=>clk,
                       rst=>reset,
                       WE=>'1'
                                                                                         
                      );     
RFB_REG:register32
                      port map(
                      datain=>t_RF_B,
                      dataout=>t_RF_B_OUT,
                      clk=>clk,
                      rst=>reset,
                      WE=>'1'
                                                                                                               
                      );                                                                              
                           
 EX: EXSTAGE port map ( RF_A        => t_RF_A_OUT,
                          RF_B        => t_RF_B_OUT,
                          Immed       => t_immed_out,
                          ALU_Bin_sel => ALU_Bin_sel,
                          ALU_func    => ALU_func,
                          ALU_out     => t_ALU,
                          ALU_zero    => ALU_zero );
ALU_OUT_REG:register32
                        port map(
                       datain=>t_ALU,
                       dataout=>t_ALU_out,
                        clk=>clk,
                       rst=>reset,
                       WE=>'1'
                                                                                                                                         
                       );      
                       
 WRDATA_REG:register32
                        port map(
                       datain=>t_RF_B_OUT,
                        dataout=>t_WRDATA,
                        clk=>clk,
                        rst=>reset,
                        WE=>'1'
                                                                                                                                                                
                        );                             
                          
 MEM: MEMSTAGE port map ( 
                           ByteOp       => ByteOp,
                           Mem_WrEn     => Mem_WrEn,
                           MM_WrEn      => MM_WrEn,
                           ALU_MEM_Addr => t_ALU_out,
                           MEM_DataIn   => t_WRDATA,
                           MEM_DataOut  => t_RDDATA,
                           MM_Addr      => MM_Addr,
                           MM_WrData    => MM_WrData,
                           MM_RdData    => MM_RdData );
                           
 RDDATA_REG:register32
                      port map(
                      datain=>t_RDDATA,
                      dataout=>t_MEM_Out,
                      clk=>clk,
                      rst=>reset,
                      WE=>'1'
                                                                                                                                                                                           
                      );                                
                           

end Behavioral;
