library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Top‐level control unit that generates all control signals
entity MAIN_CONTROL_UNIT is
    Port (
        opcode         : in  STD_LOGIC_VECTOR(5 downto 0);  -- instruction opcode
        func           : in  STD_LOGIC_VECTOR(3 downto 0);  -- function field for R‐type
        ALU_func       : out STD_LOGIC_VECTOR(3 downto 0);  -- ALU operation code
        branch         : out STD_LOGIC_VECTOR(1 downto 0);  -- branch type: 00=no branch, 01=beq, 10=bne, 11=uncond
        RF_WrEn        : out STD_LOGIC;                     -- register file write enable
        RF_WrData_sel  : out STD_LOGIC;                     -- selects memory (1) or ALU (0) as write data
        RF_B_sel       : out STD_LOGIC;                     -- selects register (0) or immediate (1) for ALU B input
        ImmExt         : out STD_LOGIC_VECTOR(1 downto 0);  -- immediate extension control
        ALU_Bin_sel    : out STD_LOGIC;                     -- ALU B input select (0=reg, 1=imm)
        ByteOp         : out STD_LOGIC;                     -- byte operation indicator (lb/sb)
        Mem_WrEn       : out STD_LOGIC                      -- data memory write enable
    );
end MAIN_CONTROL_UNIT;

architecture Behavioral of MAIN_CONTROL_UNIT is
begin

    -- ALU_func: determine ALU operation based on opcode (and func for R‐type)
    ALU_func <=
          func      when opcode = "100000" else  -- R‐type: use function field
          "0000"    when opcode = "110000"       -- ADDI
                  or opcode = "011111"            -- SW
                  or opcode = "001111"            -- LW
                  or opcode = "000111"            -- SB
                  or opcode = "000011"            -- LB
                   else
          "0101"    when opcode = "110010" else  -- NANDI
          "0011"    when opcode = "110011" else  -- ORI
          "0001"    when opcode = "000000"        -- BEQ (subtract for comparison)
                  or opcode = "000001" else       -- BNE
          "1111";                                 -- LI / LUI (pass immediate)

    -- branch: control for branching
    branch <=
          "01" when opcode = "000000" and func = "0001" else  -- BEQ: branch if equal
          "10" when opcode = "000001"           else          -- BNE: branch if not equal
          "11" when opcode = "111111"           else          -- Unconditional branch
          "00";                                            -- No branch

    -- RF_WrEn: enable register write on R‐type, immediate‐write, or load
    RF_WrEn <=
          '1' when opcode = "100000" or  -- R‐type
                    opcode = "111000" or  -- LI
                    opcode = "111001" or  -- LUI
                    opcode = "110000" or  -- ADDI
                    opcode = "110010" or  -- NANDI
                    opcode = "110011" or  -- ORI
                    opcode = "000011" or  -- LB
                    opcode = "001111"     -- LW
               else '0';

    -- RF_WrData_sel: choose memory data for loads, otherwise ALU result
    RF_WrData_sel <=
          '1' when opcode = "000011" or  -- LB
                    opcode = "001111"     -- LW
               else '0';

    -- RF_B_sel: choose register value for R‐type, immediate for others
    RF_B_sel <=
          '0' when opcode = "100000" else  -- R‐type
          '1';

    -- ImmExt: immediate extension mode
    -- "00" = zero‐extend (NANDI, ORI)
    -- "01" = sign‐extend (most I‐type arithmetic)
    -- "10" = shift left by 2 and sign‐extend (branches)
    -- "11" = shift left by 16 (LUI)
    ImmExt <=
          "00" when opcode = "110010"   -- NANDI
                 or opcode = "110011"  -- ORI
               else
          "11" when opcode = "111001"  -- LUI
               else
          "10" when opcode = "000000"  -- BEQ
                 or opcode = "111111"  -- Uncond branch
                 or opcode = "000001"  -- BNE
               else
          "01";                          -- Sign‐extend for ADDI etc.

    -- ALU_Bin_sel: select ALU B input (0=register, 1=immediate)
    ALU_Bin_sel <=
          '0' when opcode = "100000"   -- R‐type
                 or opcode = "000000"  -- BEQ (subtract uses reg)
                 or opcode = "000001"  -- BNE
               else
          '1';

    -- ByteOp: indicates byte load/store (LB/SB)
    ByteOp <=
          '1' when opcode = "000011"   -- LB
                 or opcode = "000111"  -- SB
               else
          '0';

    -- Mem_WrEn: enable data memory write on store instructions
    Mem_WrEn <=
          '1' when opcode = "000111"   -- SB
                 or opcode = "011111"  -- SW
               else
          '0';

end Behavioral;
