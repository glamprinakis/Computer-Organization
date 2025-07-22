library ieee;
use ieee.std_logic_1164.all;        
use ieee.std_logic_unsigned.all;    
use std.textio.all;                 -- File I/O support
use ieee.std_logic_textio.all;      -- Text I/O routines for std_logic types

-- Top‐level RAM entity declaration
entity RAM is
    port (
        clk        : in  std_logic;                     -- Clock input
        inst_addr  : in  std_logic_vector(10 downto 0); -- Instruction read address
        inst_dout  : out std_logic_vector(31 downto 0); -- Instruction read data
        data_we    : in  std_logic;                     -- Data write enable
        data_addr  : in  std_logic_vector(10 downto 0); -- Data read/write address
        data_din   : in  std_logic_vector(31 downto 0); -- Data write input
        data_dout  : out std_logic_vector(31 downto 0)  -- Data read output
    );
end RAM;

architecture syn of RAM is

    -- Define a 2048‐word memory, each word 32 bits wide
    type ram_type is array (2047 downto 0) of std_logic_vector(31 downto 0);

    -- Function to initialize the lower half of RAM from a file, rest zeroed
    impure function InitRamFromFile (RamFileName : in string) return ram_type is
        FILE ramfile       : text is in RamFileName;    -- File handle
        variable RamFileLine : line;                    -- One line buffer
        variable ram         : ram_type;                -- Local RAM copy
    begin
        -- Read 1024 lines from file into ram(0) through ram(1023)
        for i in 0 to 1023 loop
            readline(ramfile, RamFileLine);             -- Read next line
            read   (RamFileLine, ram(i));               -- Parse hex into vector
        end loop;
        -- Initialize the upper half of the RAM to zero
        for i in 1024 to 2047 loop
            ram(i) := x"00000000";
        end loop;
        return ram;                                      -- Return initialized memory
    end function;

    -- Declare the actual RAM signal and call the init function on elaboration
    signal RAM : ram_type := InitRamFromFile("test.data");

begin

    -- Synchronous write process: writes data_din into RAM on rising clock,
    -- but only when data_we is asserted
    process (clk)
    begin
        if rising_edge(clk) then
            if data_we = '1' then
                RAM(conv_integer(data_addr)) <= data_din;
            end if;
        end if;
    end process;

    -- Asynchronous read ports with a modeled 12 ns access delay
    data_dout <= RAM(conv_integer(data_addr))  after 12 ns;  -- Data port read
    inst_dout <= RAM(conv_integer(inst_addr))  after 12 ns;  -- Instruction port read

end syn;
