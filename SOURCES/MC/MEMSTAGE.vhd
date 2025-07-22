----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.03.2021 18:09:46
-- Design Name: 
-- Module Name: MEMSTAGE - Behavioral
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
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MEMSTAGE is
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
end MEMSTAGE;

architecture Behavioral of MEMSTAGE is

begin
--hardwriting WrEn
MM_WrEn<=Mem_WrEn;
--adding x"400" to ALU_OUT in order to get the address of the data segment
MM_Addr<= std_logic_vector(unsigned(ALU_MEM_Addr)+x"00001000");



--MM_WrData<=MEM_DataIn(7 downto 0) & MM_RdData(23 downto 0) when (ByteOp='1' and ALU_MEM_Addr(1 downto 0)="00") else
--            MM_RdData(31 downto 24) & MEM_DataIn(7 downto 0) & MM_RdData(15 downto 0) when (ByteOp='1' and ALU_MEM_Addr(1 downto 0)="01") else
--            MM_RdData(31 downto 16) & MEM_DataIn(7 downto 0) & MM_RdData(7 downto 0) when (ByteOp='1' and ALU_MEM_Addr(1 downto 0)="10") else
--            MM_RdData(31 downto 8) & MEM_DataIn(7 downto 0) when (ByteOp='1' and ALU_MEM_Addr(1 downto 0)="11") else 
--            MEM_DataIn;


--if byteOp =1 then WrData = zero fill(DataIn(7 downto 0)) else WrData = DataIn
MM_WrData<=x"000000" & MEM_DataIn(7 downto 0)  when (ByteOp='1' ) else
            MEM_DataIn;
--MEM_DataOut<=x"000000" & MM_RdData(31 downto 24) when (ByteOp='1' and ALU_MEM_Addr(1 downto 0)="00") else
--             x"000000" & MM_RdData(23 downto 16) when (ByteOp='1' and ALU_MEM_Addr(1 downto 0)="01") else   
--             x"000000" & MM_RdData(15 downto 8) when (ByteOp='1' and ALU_MEM_Addr(1 downto 0)="10") else
--             x"000000" & MM_RdData(7 downto 0) when (ByteOp='1' and ALU_MEM_Addr(1 downto 0)="11") else
--             MM_RdData;
             
 --if byteOp =1 then DataOut = zero fill(RdData(7 downto 0)) else DataOut = RdData            
 MEM_DataOut<=x"000000" & MM_RdData(7 downto 0) when (ByteOp='1') else
             MM_RdData;

end Behavioral;
