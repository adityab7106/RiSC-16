library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Program_Counter_tb is
end Program_Counter_tb;

architecture Behavioral of Program_Counter_tb is

    component Program_Counter
        Port (
            D   : in  STD_LOGIC_VECTOR(15 downto 0);
            En  : in  STD_LOGIC;
            Clk : in  STD_LOGIC;
            Q   : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    signal D   : STD_LOGIC_VECTOR(15 downto 0) := x"0000";
    signal En  : STD_LOGIC := '0';
    signal Clk : STD_LOGIC := '0';
    signal Q   : STD_LOGIC_VECTOR(15 downto 0);

begin

    UUT: Program_Counter
        port map (
            D   => D,
            En  => En,
            Clk => Clk,
            Q   => Q
        );

    -- 10 ns clock
    Clk <= not Clk after 5 ns;

    process
    begin

        ------------------------------------------------------------
        -- PC initially disabled
        ------------------------------------------------------------

        En <= '0';
        D  <= x"0000";

        wait for 10 ns;


        ------------------------------------------------------------
        -- Load 0x1000
        ------------------------------------------------------------

        D  <= x"1000";
        En <= '1';

        wait for 10 ns;


        ------------------------------------------------------------
        -- Load 0x1001
        ------------------------------------------------------------

        D <= x"1001";

        wait for 10 ns;


        ------------------------------------------------------------
        -- Disable PC
        -- D changes, but Q should remain 1001
        ------------------------------------------------------------

        En <= '0';
        D  <= x"2000";

        wait for 10 ns;


        ------------------------------------------------------------
        -- Re-enable PC
        -- Q should become 2000
        ------------------------------------------------------------

        En <= '1';

        wait for 10 ns;


        ------------------------------------------------------------
        -- Load another value
        ------------------------------------------------------------

        D <= x"ABCD";

        wait for 10 ns;


        ------------------------------------------------------------
        -- Stop driving changes
        ------------------------------------------------------------

        wait;

    end process;

end Behavioral;