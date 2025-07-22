library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration for a 3‑to‑1 multiplexer with 32‑bit wide data inputs
entity multiplexer3to1_32 is
    Port (
        input1 : in  STD_LOGIC_VECTOR(31 downto 0);  -- First 32‑bit data input
        input2 : in  STD_LOGIC_VECTOR(31 downto 0);  -- Second 32‑bit data input
        input3 : in  STD_LOGIC_VECTOR(31 downto 0);  -- Third 32‑bit data input

        sel    : in  STD_LOGIC_VECTOR(1 downto 0);   -- 2‑bit select signal
        output : out STD_LOGIC_VECTOR(31 downto 0)   -- 32‑bit multiplexed output
    );
end multiplexer3to1_32;

-- Behavioral architecture: chooses one of three inputs based on sel
architecture Behavioral of multiplexer3to1_32 is
begin
    -- Concurrent signal assignment using conditional (when/else) clauses:
    -- if sel = "00" then output <= input1;
    -- elsif sel = "01" then output <= input2;
    -- otherwise            output <= input3.
    output <= input1 when (sel = "00") else
              input2 when (sel = "01") else
              input3;
end Behavioral;
