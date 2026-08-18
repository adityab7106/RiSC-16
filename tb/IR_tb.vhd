library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Current_Instruction_tb is
end Current_Instruction_tb;

architecture Behavioral of Current_Instruction_tb is

    component Current_Instruction
        Port (
            D_in : in  STD_LOGIC_VECTOR(15 downto 0);
            En   : in  STD_LOGIC;
            Clk  : in  STD_LOGIC;
            Q    : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    signal D_in : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal En   : STD_LOGIC := '0';
    signal Clk  : STD_LOGIC := '0';
    signal Q    : STD_LOGIC_VECTOR(15 downto 0);

begin

    -- Instantiate Current Instruction Register
    UUT: Current_Instruction
        port map (
            D_in => D_in,
            En   => En,
            Clk  => Clk,
            Q    => Q
        );

    -- 10 ns clock
    Clk <= not Clk after 5 ns;

    process
    begin

        --------------------------------------------------
        -- TEST 1: Initial value
        --------------------------------------------------

        wait for 2 ns;

        assert Q = x"0000"
            report "ERROR: IR did not initialize to 0"
            severity error;


        --------------------------------------------------
        -- TEST 2: Load instruction
        --------------------------------------------------

        D_in <= x"1234";
        En   <= '1';

        wait until rising_edge(Clk);
        wait for 1 ns;

        assert Q = x"1234"
            report "ERROR: IR failed to load 0x1234"
            severity error;


        --------------------------------------------------
        -- TEST 3: Hold instruction when disabled
        --------------------------------------------------

        D_in <= x"5678";
        En   <= '0';

        wait until rising_edge(Clk);
        wait for 1 ns;

        assert Q = x"1234"
            report "ERROR: IR changed when En = 0"
            severity error;


        --------------------------------------------------
        -- TEST 4: Re-enable and load new instruction
        --------------------------------------------------

        En <= '1';

        wait until rising_edge(Clk);
        wait for 1 ns;

        assert Q = x"5678"
            report "ERROR: IR failed to load 0x5678"
            severity error;


        --------------------------------------------------
        -- TEST 5: Load another instruction
        --------------------------------------------------

        D_in <= x"ABCD";

        wait until rising_edge(Clk);
        wait for 1 ns;

        assert Q = x"ABCD"
            report "ERROR: IR failed to load 0xABCD"
            severity error;


        --------------------------------------------------
        -- TEST 6: Hold instruction
        --------------------------------------------------

        D_in <= x"FFFF";
        En   <= '0';

        wait until rising_edge(Clk);
        wait for 1 ns;

        assert Q = x"ABCD"
            report "ERROR: IR changed while disabled"
            severity error;


        report "Current Instruction testbench PASSED"
            severity note;

        wait;

    end process;

end Behavioral;
