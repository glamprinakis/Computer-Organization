library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


-- Entity declaration for a 32-bit Arithmetic Logic Unit (ALU)
-- Supports: add, subtract, bitwise ops, shifts, rotates, flags

entity ALU is
  Port (
    A      : in  std_logic_vector(31 downto 0);  -- Operand A
    B      : in  std_logic_vector(31 downto 0);  -- Operand B
    Op     : in  std_logic_vector(3 downto 0);   -- Operation selector
    Output : out std_logic_vector(31 downto 0);  -- Result of the operation
    Zero   : out std_logic;                      -- Zero flag (1 if result = 0)
    Cout   : out std_logic;                      -- Carry-out / borrow flag
    Ovf    : out std_logic                       -- Overflow flag
  );
end ALU;


-- Behavioral architecture implementing the ALU operations

architecture Behavioral of ALU is

  -- Internal signals:
  signal t_out  : std_logic_vector(31 downto 0);      -- Latched output before delay
  signal a32    : signed(32 downto 0);                -- A extended to 33 bits (for carry)
  signal b32    : signed(32 downto 0);                -- B extended to 33 bits
  signal out32  : signed(32 downto 0);                -- Full result of add/sub (with carry)
  signal t_zero : std_logic;                          -- Temporary zero flag
  signal t_ovf  : std_logic;                          -- Temporary overflow flag

begin

  -----------------------------------------------------------------
  -- Sign‑extension (to detect carry/overflow)
  -- a32: prepend '0' so MSB of A fills sign bit area
  -- b32: use Op(0) as the top bit to invert B for subtraction when needed
  -----------------------------------------------------------------
  a32 <= signed('0' & A);
  b32 <= signed(Op(0) & B);

  -----------------------------------------------------------------
  -- Perform add or subtract based on Op:
  -- "0000" = add, "0001" = subtract, others pass A through
  -----------------------------------------------------------------
  with Op select
    out32 <= (a32 + b32)  when "0000",  -- ADD
             (a32 - b32)  when "0001",  -- SUBTRACT
             a32           when others;-- PASS A

  -- Carry/Borrow flag: the MSB of the 33‑bit result
  Cout <= out32(32) after 10 ns;

  -----------------------------------------------------------------
  -- Overflow detection:
  -- For ADD: overflow if signs of A and B are same AND result sign ≠ A sign
  -- For SUB: overflow if signs of A and B differ AND result sign ≠ A sign
  -----------------------------------------------------------------
  t_ovf <= '1'
           when (Op = "0000") and ((A(31) xor B(31)) = '0') and (out32(31) /= A(31))
      else '1'
           when (Op = "0001") and ((A(31) xor B(31)) = '1') and (out32(31) /= A(31))
      else '0';
  Ovf <= t_ovf after 10 ns;

  -----------------------------------------------------------------
  -- Multiplex various logic and shift/rotate operations:
  -- "0010": AND
  -- "0011": OR
  -- "0100": NOT A
  -- "0101": NAND
  -- "0110": NOR
  -- "1000": Arithmetic right shift (sign‑extend)
  -- "1001": Logical right shift
  -- "1010": Logical left shift
  -- "1100": Rotate left
  -- "1101": Rotate right
  -- Others: pass B
  -----------------------------------------------------------------
  with Op select
    t_out <= std_logic_vector(out32(31 downto 0)) when "0000",  -- ADD result
             std_logic_vector(out32(31 downto 0)) when "0001",  -- SUB result
             A and B                         when "0010",      -- AND
             A or B                          when "0011",      -- OR
             not A                           when "0100",      -- NOT
             A nand B                       when "0101",      -- NAND
             A nor B                        when "0110",      -- NOR
             A(31) & A(31 downto 1)         when "1000",      -- Arithmetic RSH
             '0' & A(31 downto 1)           when "1001",      -- Logical RSH
             A(30 downto 0) & '0'           when "1010",      -- Logical LSH
             A(30 downto 0) & A(31)         when "1100",      -- Rotate L
             A(0) & A(31 downto 1)          when "1101",      -- Rotate R
             B                              when others;      -- Default: pass B

  -- Zero flag: asserted if the operation result is zero
  t_zero <= '1' when to_integer(unsigned(t_out)) = 0 else '0';

  -- Drive outputs with a small propagation delay
  Output <= t_out  after 10 ns;
  Zero   <= t_zero after 10 ns;

end Behavioral;
