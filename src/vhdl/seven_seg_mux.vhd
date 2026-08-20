library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Time-multiplexes one 16-bit value across the four Basys3 digits.
-- The single-digit hex decoder from the Lab 3 shell is inlined here, so this
-- file has no external dependencies.
entity seven_seg_mux is
    Port( clk      : in  STD_LOGIC;
          value    : in  STD_LOGIC_VECTOR(15 downto 0);
          seg_port : out STD_LOGIC_VECTOR(0 to 6);
          an_port  : out STD_LOGIC_VECTOR(3 downto 0) );
end seven_seg_mux;

architecture Behavioral of seven_seg_mux is

    signal refresh : unsigned(17 downto 0) := (others => '0');
    signal sel     : STD_LOGIC_VECTOR(1 downto 0);
    signal nibble  : STD_LOGIC_VECTOR(3 downto 0);
    signal segh    : STD_LOGIC_VECTOR(0 to 6) := "0000000";  -- active high

begin

    -- ~380 Hz per digit, well above the flicker threshold
    process(clk)
    begin
        if rising_edge(clk) then
            refresh <= refresh + 1;
        end if;
    end process;

    sel <= STD_LOGIC_VECTOR(refresh(17 downto 16));

    -- pick the nibble for the digit currently being lit
    with sel select nibble <=
        value(3  downto 0)  when "00",
        value(7  downto 4)  when "01",
        value(11 downto 8)  when "10",
        value(15 downto 12) when others;

    -- anodes are active low, one digit lit at a time
    with sel select an_port <=
        "1110" when "00",
        "1101" when "01",
        "1011" when "10",
        "0111" when others;

    -- hex decoder, active-high truth table (segments a..g, index 0 = a)
    with nibble select segh <=
        "1111110" when x"0",
        "0110000" when x"1",
        "1101101" when x"2",
        "1111001" when x"3",
        "0110011" when x"4",
        "1011011" when x"5",
        "1011111" when x"6",
        "1110000" when x"7",
        "1111111" when x"8",
        "1111011" when x"9",
        "1110111" when x"a",
        "0011111" when x"b",
        "1001110" when x"c",
        "0111101" when x"d",
        "1001111" when x"e",
        "1000111" when x"f",
        "0000000" when others;

    seg_port <= not(segh);   -- convert to active low

end Behavioral;