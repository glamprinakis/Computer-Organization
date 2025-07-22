library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration for the Hazard Detection Unit
entity HAZARD_DETECTION_UNIT is
    Port (
        -- Control signals from register file indicating forwarding and write-back choices
        RF_B_sel      : in  std_logic;               -- selects B input for ALU (0 = from register, 1 = forwarded)
        RF_WrData_sel : in  std_logic;               -- indicates whether write-back data forwarding is active

        -- Branch control signals
        branch        : in  std_logic_vector(1 downto 0);  -- branch opcode bits
        zero          : in  std_logic;               -- zero flag from ALU (for beq/bne)

        -- Source and destination register fields from pipeline stages
        IFID_Rs       : in  std_logic_vector(4 downto 0);  -- source register Rs in IF/ID
        IFID_Rt       : in  std_logic_vector(4 downto 0);  -- source register Rt in IF/ID
        IFID_Rd       : in  std_logic_vector(4 downto 0);  -- dest register Rd in IF/ID (for R-type branches)
        IDEX_Rd       : in  std_logic_vector(4 downto 0);  -- dest register Rd in ID/EX

        -- Outputs controlling pipeline registers and PC mux
        PC_LdEn       : out std_logic;               -- enable loading of the PC register
        PC_sel        : out std_logic;               -- select signal for PC mux (0 = PC+4, 1 = branch/jump)
        IFID_LdEn     : out std_logic;               -- enable loading of IF/ID pipeline register
        Control_sel   : out std_logic                -- select signal to zero out control (stall insertion)
    );
end HAZARD_DETECTION_UNIT;

architecture Behavioral of HAZARD_DETECTION_UNIT is
begin

    ------------------------------------------------------------------------
    -- PC_LdEn: disables PC update (holds PC) on a load/use hazard or flush
    -- If forwarding is disabled (RF_WrData_sel='1') and
    --   - B-input not forwarded (RF_B_sel='0') and ID/EX writes to a register
    --     that IF/ID is about to read (load-use hazard), OR
    --   - B-input forwarded (RF_B_sel='1') and branch uses Rd and will read it here,
    -- then stall PC (hold).
    -- Otherwise PC updates normally.
    PC_LdEn <= '0'
        when (RF_WrData_sel = '1')
         and (RF_B_sel = '0'
              and (IDEX_Rd = IFID_Rs or IDEX_Rd = IFID_Rt))
     else '0'
        when (RF_WrData_sel = '1')
         and (RF_B_sel = '1'
              and (IDEX_Rd = IFID_Rs or IDEX_Rd = IFID_Rd))
     else '1';

    ------------------------------------------------------------------------
    -- IFID_LdEn: same stall logic applies to IF/ID register
    -- Hold IF/ID when we detect a hazard so that the instruction fetch is stalled.
    IFID_LdEn <= '0'
        when (RF_WrData_sel = '1')
         and (RF_B_sel = '0'
              and (IDEX_Rd = IFID_Rs or IDEX_Rd = IFID_Rt))
     else '0'
        when (RF_WrData_sel = '1')
         and (RF_B_sel = '1'
              and (IDEX_Rd = IFID_Rs or IDEX_Rd = IFID_Rd))
     else '1';

    ------------------------------------------------------------------------
    -- Control_sel: zeroes out control signals (inserts bubble) on hazard or
    -- flushes on taken branch
    Control_sel <= '1'
        when (RF_WrData_sel = '1')
         and (RF_B_sel = '0'
              and (IDEX_Rd = IFID_Rs or IDEX_Rd = IFID_Rt))
     else '1'
        when (RF_WrData_sel = '1')
         and (RF_B_sel = '1'
              and (IDEX_Rd = IFID_Rs or IDEX_Rd = IFID_Rd))
     -- Branch taken flush logic: if branch condition met, flush next stage
     else '1' when branch = "01" and zero = '1'    -- BEQ taken
     else '1' when branch = "10" and zero = '0'    -- BNE taken
     else '1' when branch = "11"                  -- unconditional branch (JUMP)
     else '0';                                    -- normal operation: pass controls through

    ------------------------------------------------------------------------
    -- PC_sel: selects between PC+4 and branch target
    -- PC_sel = '1' means take branch/jump; '0' means sequential PC
    PC_sel <= '1' when branch = "01" and zero = '1'  -- BEQ taken
           else '1' when branch = "10" and zero = '0'  -- BNE taken
           else '1' when branch = "11"                -- unconditional branch
           else '0';                                  -- PC+4
end Behavioral;
