library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration for a 2‑to‑1 multiplexer with 15‑bit wide data inputs
entity multiplexer2to1_15 is
    Port (
        input1 : in  STD_LOGIC_VECTOR(14 downto 0);  -- First 15‑bit data input
        input2 : in  STD_LOGIC_VECTOR(14 downto 0);  -- Second 15‑bit data input
        sel    : in  STD_LOGIC;                     -- Single‑bit select signal
        output : out STD_LOGIC_VECTOR(14 downto 0)   -- 15‑bit multiplexed output
    );
end multiplexer2to1_15;

-- Behavioral architecture: selects between input1 and input2 based on sel
architecture Behavioral of multiplexer2to1_15 is
begin
    -- Concurrent signal assignment using a when/else conditional:
    -- if sel = '0' then output <= input1;
    -- else             output <= input2.
    output <= input1 when (sel = '0') else
              input2;
end Behavioral;
