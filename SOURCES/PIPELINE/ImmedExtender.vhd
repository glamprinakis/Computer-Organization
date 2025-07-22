library IEEE;
use IEEE.STD_LOGIC_1164.ALL;        -- Import standard logic definitions (std_logic, std_logic_vector, etc.)
use ieee.numeric_std.all;            -- Import numeric operations for converting between signed/unsigned and resizing

-- Entity declaration for immediate extender
entity ImmedExtender is
  Port (
    Immed     : in  std_logic_vector(15 downto 0);  -- 16-bit immediate input
    ImmedSel  : in  std_logic_vector(1 downto 0);   -- 2-bit selector for extension type
    Immed_out : out std_logic_vector(31 downto 0)   -- 32-bit extended immediate output
  );
end ImmedExtender;

architecture Behavioral of ImmedExtender is
  -- Internal signal holding a sign-extended version of Immed
  signal signExtend   : std_logic_vector(31 downto 0);
  -- Intermediate output before applying delay
  signal t_immed_out  : std_logic_vector(31 downto 0);
begin
  -- Perform sign extension by converting Immed to signed, resizing to 32 bits, then back to std_logic_vector
  signExtend <= std_logic_vector(resize(signed(Immed), 32));

  -- Use ImmedSel to choose between zero-extension, sign-extension, and shifted sign-extensions
  with ImmedSel select
    t_Immed_out <=
      std_logic_vector(resize(unsigned(Immed), 32))       when "00", -- Zero-extend Immed (fill high bits with 0)
      signExtend                                        when "01", -- Sign-extend Immed (propagate sign bit)
      std_logic_vector(shift_left(unsigned(signExtend), 2))  when "10", -- Sign-extend then shift left by 2 bits (e.g., for word alignment)
      std_logic_vector(shift_left(unsigned(signExtend), 16)) when others; -- Sign-extend then shift left by 16 bits (e.g., for load upper immediate)

  -- Assign the selected extension to the output with a 10 ns inertial delay
  Immed_out <= t_Immed_out after 10 ns;

end Behavioral;
