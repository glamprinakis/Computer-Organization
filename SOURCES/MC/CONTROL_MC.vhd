----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.05.2021 17:24:23
-- Design Name: 
-- Module Name: CONTROL_MC - Behavioral
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

entity CONTROL_MC is
  Port (opcode : in STD_LOGIC_VECTOR (5 downto 0);
         zero: in std_logic;
         func : in STD_LOGIC_VECTOR (5 downto 0);
         Clock :in std_logic;
         Rst: in std_logic;
         ALU_func : out STD_LOGIC_VECTOR (3 downto 0);
         
         PC_sel : out STD_LOGIC;
         PC_LdEn : out STD_LOGIC;
         
          RF_WrEn : out std_logic;
          RF_WrData_sel : out std_logic;
          RF_B_sel : out std_logic;
          ImmExt : out std_logic_vector(1 downto 0);
          
          ALU_Bin_sel : out STD_LOGIC;
          
          ByteOp : out std_logic;
          Mem_WrEn : out std_logic  );
end CONTROL_MC;

architecture Behavioral of CONTROL_MC is
     type state_type is(instrFetch,instrDec,Rtype_state,StoreLoad,nandi_state,ori_state,li_lui_state,BEQ_BNE_state,Branch_state,
     RF_write_ALU,SW_state,LW_state,SB_state,
     LB_state, RF_write_MEM);
     
     signal state:state_type;
begin


process(Clock) is
begin
    if rising_edge(Clock) then
        
        
        if Rst = '1' then
           State <= instrFetch;
        else 
            case State is
               when instrFetch =>
                     state<=instrDec;  
               when instrDec =>
                    if opcode = "100000" then
                        state<=Rtype_state;  --if opcode is "100000" then it's an Rtype instruction 
                    elsif opcode ="110000" or opcode ="011111" or opcode ="001111" or opcode ="000111"or opcode ="000011" then
                        state<=StoreLoad; --SW,SB,LW,LB an andi
                    elsif opcode ="110010" then
                        state<=nandi_state;--nandi
                    elsif opcode ="110011" then
                        state<=ori_state ;   --ori
                    elsif (opcode ="000000" or opcode ="000001") then
                        state<=BEQ_BNE_state  ; 
                    elsif (opcode ="111111" ) then
                        state<=Branch_state  ;     
                    else 
                        state <= li_lui_state;
                    end if;
                    
               when Rtype_state =>
                     state<=RF_write_ALU;
               when StoreLoad =>
                    if opcode = "110000" then
                         state<=RF_write_ALU;
                    elsif opcode ="011111"  then
                         state<=SW_state;
                    elsif opcode ="001111" then
                         state<=LW_state;
                    elsif opcode ="000111" then
                         state<=SB_state;    
                    elsif opcode ="000011" then
                         state<=LB_state;    
    
                    end if ;   
               when nandi_state => 
                    state<=RF_write_ALU;
               when ori_state => 
                    state<=RF_write_ALU;
               when  BEQ_BNE_state=>
                    state<= instrFetch;
               when  Branch_state=>
                    state<= instrFetch;    
               when  li_lui_state=>
                    state<= RF_write_ALU; 
               when RF_write_ALU=>
                     state<= instrFetch;       
               when  SW_state=>
                    state<= instrFetch;                                                                                                
               when  SB_state=>
                    state<= instrFetch; 
               when  LW_state=>
                    state<= RF_write_MEM;
               when  LB_state=>
                    state<= RF_write_MEM; 
               when  RF_write_MEM =>
                    state<= instrFetch; 
               when others =>
                    state<= instrFetch;                                                                                                                    
            end case;
         end if; 
    end if;
end process;
  
process(State,zero) is
begin
    case State is
               when instrFetch =>
                     RF_WrEn<='0';
                     PC_LdEn<='0';
                     Mem_WrEn<='0';
                      PC_sel<='0';
               when instrDec =>
                    PC_LdEn<='0';
                    
                    if opcode = "100000" then
                        RF_B_sel<='0';
                        ImmExt<="01";
                    elsif opcode="110010" or opcode="110011" then
                        ImmExt<="00";
                        RF_B_sel<='1';
                    elsif opcode="111001" then
                        ImmExt<="11";
                        RF_B_sel<='1';
                    elsif opcode="000000" or opcode="111111"or opcode="000001" then
                        ImmExt<="10";
                        RF_B_sel<='1';        
                    else 
                        ImmExt<="01";
                        RF_B_sel<='1';
                    end if;
                    
               when Rtype_state =>
                      ALU_Bin_sel<='0';
                      ALU_func<=func(3 downto 0);
                      
               when StoreLoad =>
                      ALU_func<="0000";
                      ALU_Bin_sel<='1';  
                      
               when nandi_state => 
                    ALU_func<="0101";
                    ALU_Bin_sel<='1';
                    
               when ori_state => 
                     ALU_func<="0011";
                     ALU_Bin_sel<='1';
                     
               when  BEQ_BNE_state=>
                     ALU_func<="0001";
                     ALU_Bin_sel<='0';
                     if (opcode ="000000" and zero='0') or (opcode ="000001" and zero='1') then
                        PC_sel<='0';
                     elsif (opcode ="000000" and zero='1') or (opcode ="000001" and zero='0') then
                           PC_sel<='1'; 
                      end if; 
                      PC_LdEn<='1';      
               when  Branch_state=>
                    PC_sel<='1';  
                     PC_LdEn<='1';
                      
               when  li_lui_state=>
                      ALU_func<="1111";
                      ALU_Bin_sel<='1'; 
                      
               when RF_write_ALU=> 
                     RF_WrData_sel <= '0';
                     RF_WrEn<='1';
                     PC_sel<='0';  
                     PC_LdEn<='1';
                               
               when  SW_state=>
                      Mem_WrEn<='1'; 
                       ByteOp<= '0';
                       PC_sel<='0';  
                       PC_LdEn<='1';
                                                                                                                     
               when  SB_state=>
                      Mem_WrEn<='1'; 
                      ByteOp<= '1';
                      PC_sel<='0';  
                      PC_LdEn<='1'; 
                      
               when  LW_state=>
                      Mem_WrEn<='0'; 
                      ByteOp<= '0'; 
                      
               when  LB_state=>
                      Mem_WrEn<='0'; 
                      ByteOp<= '1'; 
                      
               when  RF_write_MEM =>
                     RF_WrData_sel <= '1';
                     RF_WrEn<='1';
                     PC_sel<='0';  
                     PC_LdEn<='1'; 
                     
               when others =>
                     PC_LdEn<='0';                                                                                                                   
            end case;
end process;

end Behavioral;
