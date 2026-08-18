library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Program_Counter_tb is
end Program_Counter_tb;

architecture Behavioral of Program_Counter_tb is

    -- Component declaration
    component Program_Counter
        Port (
            D   : in  STD_LOGIC_VECTOR(15 downto 0);
            En  : in  STD_LOGIC;
            Clk : in  STD_LOGIC;
            Q   : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Testbench signals
    signal D   : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal En  : STD_LOGIC := '0';
    signal Clk : STD_LOGIC := '0';
    signal Q   : STD_LOGIC_VECTOR(15 downto 0);

begin

    -- Instantiate the PC
    UUT: Program_Counter
        port map (
            D   => D,
            En  => En,
            Clk => Clk,
            Q   => Q
        );

    -- Clock generation: 10 ns period
    Clk <= not Clk after 5 ns;

    -- Test process
    process
    begin

        -- Initial condition
        wait for 2 ns;

        assert Q = x"0000"
            report "ERROR: PC did not initialize to 0"
            severity error;

        -- Test 1: Load 0x1234
        D  <= x"1234";
        En <= '1';

        wait until rising_edge(Clk);
        wait for 1 ns;

        assert Q = x"1234"
            report "ERROR: PC failed to load 0x1234"
            severity error;

        -- Test 2: Disable PC and change D
        D  <= x"5678";
        En <= '0';

        wait until rising_edge(Clk);
        wait for 1 ns;

        assert Q = x"1234"
            report "ERROR: PC changed when En = 0"
            severity error;

        -- Test 3: Re-enable PC
        En <= '1';

        wait until rising_edge(Clk);
        wait for 1 ns;

        assert Q = x"5678"
            report "ERROR: PC failed to load 0x5678"
            severity error;

        -- Test 4: Load another value
        D <= x"ABCD";

        wait until rising_edge(Clk);
        wait for 1 ns;

        assert Q = x"ABCD"
            report "ERROR: PC failed to load 0xABCD"
            severity error;

        report "Program Counter testbench PASSED"
            severity note;

        wait;

    end process;

end Behavioral;
