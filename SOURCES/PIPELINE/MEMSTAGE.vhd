library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Memory stage of a pipelined processor
entity MEMSTAGE is
  Port (
    -- When '1', perform a byte-sized operation (only lower 8 bits)
    ByteOp        : in  std_logic;
    -- Input memory write enable from the execute stage
    Mem_WrEn      : in  std_logic;
    -- Output memory write enable to the memory/memory‑mapped interface
    MM_WrEn       : out std_logic;
    -- 32‑bit address computed by the ALU for load/store
    ALU_MEM_Addr  : in  std_logic_vector(31 downto 0);
    -- 32‑bit data to be written (from execute stage)
    MEM_DataIn    : in  std_logic_vector(31 downto 0);
    -- 32‑bit data read out of this stage back to the write‑back stage
    MEM_DataOut   : out std_logic_vector(31 downto 0);
    -- 32‑bit address sent to the memory/memory‑mapped interface (with fixed offset)
    MM_Addr       : out std_logic_vector(31 downto 0);
    -- 32‑bit data to write into memory/memory‑mapped interface
    MM_WrData     : out std_logic_vector(31 downto 0);
    -- 32‑bit data read from memory/memory‑mapped interface
    MM_RdData     : in  std_logic_vector(31 downto 0)
  );
end MEMSTAGE;

architecture Behavioral of MEMSTAGE is
begin

  --------------------------------------------------------------------------
  -- Propagate the write‑enable signal directly to the memory interface
  --------------------------------------------------------------------------
  MM_WrEn <= Mem_WrEn;

  --------------------------------------------------------------------------
  -- Compute the actual memory address by adding a fixed offset (0x00001000).
  -- This could map ALU-generated addresses into a specific memory region
  -- (e.g., data segment base at 0x1000).
  --------------------------------------------------------------------------
  MM_Addr <= std_logic_vector(unsigned(ALU_MEM_Addr) + x"00001000");

  --------------------------------------------------------------------------
  -- Prepare write data for memory:
  --   - If ByteOp = '1', zero‑extend the lower 8 bits of MEM_DataIn to 32 bits.
  --   - Otherwise, pass the full 32‑bit word unchanged.
  --------------------------------------------------------------------------
  MM_WrData <= x"000000" & MEM_DataIn(7 downto 0)  when (ByteOp = '1') else
               MEM_DataIn;

  --------------------------------------------------------------------------
  -- Prepare read data back to the pipeline:
  --   - If ByteOp = '1', zero‑extend the lower 8 bits of the memory read data.
  --   - Otherwise, forward the full 32‑bit value unchanged.
  --------------------------------------------------------------------------
  MEM_DataOut <= x"000000" & MM_RdData(7 downto 0)  when (ByteOp = '1') else
                 MM_RdData;

end Behavioral;
