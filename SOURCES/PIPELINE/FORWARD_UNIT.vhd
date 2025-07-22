library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-------------------------------------------------------------------------------
-- Entity Declaration
-- The FORWARD_UNIT handles data hazards in a pipelined processor by
-- selecting forwarded data from later pipeline stages (EX/MEM or MEM/WB)
-- when the Execute stage source registers (ID/EX Rs or Rt/Rd) match a
-- destination register in a later stage that will write back to the register file.
-------------------------------------------------------------------------------
entity FORWARD_UNIT is
  Port (
    -- Control signals indicating whether the EX/MEM or MEM/WB stage will write
    -- to the register file. If '1', that stage will perform a write-back.
    EXMEM_RF_WrEn  : in  std_logic;             -- Write-enable from EX/MEM stage
    MEMWB_RF_WrEn  : in  std_logic;             -- Write-enable from MEM/WB stage

    -- Selector for the second operand in the ALU stage (0 = register Rt, 1 = register Rd for certain instructions)
    RF_B_sel       : in  std_logic;

    -- Source register indices from the ID/EX pipeline latch
    IDEX_Rs        : in  std_logic_vector(4 downto 0);  -- First source register
    IDEX_Rt        : in  std_logic_vector(4 downto 0);  -- Second source register (register operand)
    IDEX_Rd        : in  std_logic_vector(4 downto 0);  -- Destination register for certain instruction formats

    -- Destination register indices carried in the EX/MEM and MEM/WB latches
    EXMEM_Rd       : in  std_logic_vector(4 downto 0);  -- Dest. reg in EX/MEM stage
    MEMWB_Rd       : in  std_logic_vector(4 downto 0);  -- Dest. reg in MEM/WB stage

    -- Output select signals that choose which data to forward into the ALU inputs:
    --   "00" = use data from the ID/EX register file outputs (no forwarding)
    --   "01" = forward from the EX/MEM stage
    --   "10" = forward from the MEM/WB stage
    forward_A_sel  : out std_logic_vector(1 downto 0);  -- Select for the ALU’s A input
    forward_B_sel  : out std_logic_vector(1 downto 0)   -- Select for the ALU’s B input
  );
end FORWARD_UNIT;

architecture Behavioral of FORWARD_UNIT is
begin

  ---------------------------------------------------------------------------
  -- Forwarding for ALU input A (first operand)
  --
  -- Priority:
  --   1) If the EX/MEM stage is writing back, its destination matches IDEX_Rs,
  --      and the dest register is not $zero, forward EX/MEM → A ("01").
  --   2) Else if the MEM/WB stage is writing back, its destination matches IDEX_Rs,
  --      and the dest register is not $zero, forward MEM/WB → A ("10").
  --   3) Otherwise, no forwarding ("00")—use the value read from the register file.
  ---------------------------------------------------------------------------
  forward_A_sel <=
       "01"  when EXMEM_RF_WrEn = '1'                                    -- EX/MEM will write back
                    and EXMEM_Rd /= "00000"                              -- Dest reg not $zero
                    and EXMEM_Rd = IDEX_Rs                             -- Hazard: dest = Rs
    else "10"  when MEMWB_RF_WrEn = '1'                                  -- MEM/WB will write back
                    and MEMWB_Rd /= "00000"                              -- Dest reg not $zero
                    and MEMWB_Rd = IDEX_Rs                             -- Hazard: dest = Rs
    else "00";                                                             -- No forwarding

  ---------------------------------------------------------------------------
  -- Forwarding for ALU input B (second operand)
  --
  -- The second operand can come from either IDEX_Rt (register operand) or
  -- IDEX_Rd (for instructions where the destination field is used as a source,
  -- e.g., shift instructions). RF_B_sel indicates which of those two registers
  -- is actually used as the "B" input.
  --
  -- Priority within each stage:
  --   1) Forward from EX/MEM if matching hazard, using RF_B_sel to choose Rs/Rd.
  --   2) Else forward from MEM/WB if matching hazard.
  --   3) Else no forwarding.
  --
  -- Note: We duplicate the select code for the two potential source registers.
  ---------------------------------------------------------------------------
  forward_B_sel <=
       -- Forward from EX/MEM if using Rt as B (RF_B_sel = '0')
       "01"  when EXMEM_RF_WrEn = '1'
                    and RF_B_sel = '0'
                    and EXMEM_Rd /= "00000"
                    and EXMEM_Rd = IDEX_Rt
    -- Forward from EX/MEM if using Rd as B (RF_B_sel = '1')
    else "01"  when EXMEM_RF_WrEn = '1'
                    and RF_B_sel = '1'
                    and EXMEM_Rd /= "00000"
                    and EXMEM_Rd = IDEX_Rd
    -- Forward from MEM/WB if using Rt as B
    else "10"  when MEMWB_RF_WrEn = '1'
                    and RF_B_sel = '0'
                    and MEMWB_Rd /= "00000"
                    and MEMWB_Rd = IDEX_Rt
    -- Forward from MEM/WB if using Rd as B
    else "10"  when MEMWB_RF_WrEn = '1'
                    and RF_B_sel = '1'
                    and MEMWB_Rd /= "00000"
                    and MEMWB_Rd = IDEX_Rd
    else "00";  -- No forwarding if no hazards detected

end Behavioral;
