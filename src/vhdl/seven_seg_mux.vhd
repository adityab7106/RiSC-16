library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Time-multiplexes one 16-bit value across the four Basys3 digits, using the
-- course-provided single-digit decoder for the segment lookup.
entity seven_seg_mux is
    Port( clk        : in  STD_LOGIC;
          value      : in  STD_LOGIC_VECTOR(15 downto 0);
          seg_port   : out STD_LOGIC_VECTOR(0 to 6);
          an_port    : out STD_LOGIC_VECTOR(3 downto 0) );
end seven_seg_mux;

architecture Behavioral of seven_seg_mux is

    component small_seven_seg_driver is
        Port( count_port : in  std_logic_vector(3 downto 0);
              seg_port   : out std_logic_vector(0 to 6);
              an_port    : out std_logic );
    end component;

    signal refresh : unsigned(17 downto 0) := (others => '0');
    signal sel     : STD_LOGIC_VECTOR(1 downto 0);
    signal nibble  : STD_LOGIC_VECTOR(3 downto 0);

begin

    -- ~380 Hz per digit
    process(clk)
    begin
        if rising_edge(clk) then
            refresh <= refresh + 1;
        end if;
    end process;

    sel <= STD_LOGIC_VECTOR(refresh(17 downto 16));

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

    -- the decoder's own an_port is left open; the mux drives the anodes
    U_DEC : small_seven_seg_driver
        port map( count_port => nibble,
                  seg_port   => seg_port,
                  an_port    => open );

end Behavioral;