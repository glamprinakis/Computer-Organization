library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
Port ( 
 A: in std_logic_vector(31 downto 0);
 B: in std_logic_vector(31 downto 0);
 Op: in std_logic_vector(3 downto 0);
 Output: out std_logic_vector(31 downto 0);
 Zero: out std_logic;
 Cout: out std_logic;
 Ovf: out std_logic);
end ALU;

architecture Behavioral of ALU is
signal t_out:std_logic_vector(31 downto 0);
signal a32,b32,out32: signed(32 downto 0);
signal t_zero,t_ovf: std_logic;
 

begin
--33 bit signal in order to use the 32nd bit as the carry out. b32(32) changes according to the operation (0 when add, 1 when sub)
a32<= signed('0' & A);
b32<= signed(op(0) & B);

--calculate out32 depending on the operation
with Op select 
out32 <=(a32+b32) when "0000",
        (a32-b32) when "0001",
        a32 when others;


--getting the cout
cout<=out32(32) after 10ns; 

 --ovf = 1 when (in addition) A has the same sign as B(a(31) xor b(31)=0) but the result has different sign     
 --ovf = 1 when (in subtraction) A has not the same sign as B(a(31) xor b(31)=1) but the result has different sign from A 
t_Ovf<='1' when (op="0000")and( ((A(31) xor B(31) ) = '0') AND( out32(31) = not a(31) ))else
     '1' when (op="0001")and ( ((A(31) xor B(31) ) = '1') AND( out32(31) = not a(31) ))else
     '0' ;  
ovf<=t_ovf after 10ns ; 
--calculating out according to the op    
      with Op select 
            t_out<=std_logic_vector(out32(31 downto 0)) when  "0000" ,
                std_logic_vector(out32(31 downto 0))  when "0001",
                A and B when "0010" ,
                A or B when "0011" ,
                not A when "0100" ,
                A nand B when "0101" ,
                A nor B when "0110" ,
                A(31) & A(31 downto 1) when "1000" ,
                '0' & A(31 downto 1) when "1001" ,
                A(30 downto 0) & '0' when "1010",
                A(30 downto 0) & A(31) when "1100",
                A(0) & A(31 downto 1) when "1101",
                B when others;
        
              
t_zero<='1' when to_integer(unsigned(t_out))=0 else '0';
Output<=t_out after 10ns ;
Zero<=t_zero after 10ns  ;

end Behavioral;