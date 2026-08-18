library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Register_File_tb is
end Register_File_tb;

architecture Behavioral of Register_File_tb is

    component Register_File
        Port (
            Wr_addr  : in  STD_LOGIC_VECTOR(2 downto 0);
            D_in     : in  STD_LOGIC_VECTOR(15 downto 0);
            w_enable : in  STD_LOGIC;

            Read_A   : in  STD_LOGIC_VECTOR(2 downto 0);
            Read_B   : in  STD_LOGIC_VECTOR(2 downto 0);
            Read_C   : in  STD_LOGIC_VECTOR(2 downto 0);

            Clk      : in  STD_LOGIC;

            Q_A      : out STD_LOGIC_VECTOR(15 downto 0);
            Q_B      : out STD_LOGIC_VECTOR(15 downto 0);
            Q_C      : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    signal Wr_addr  : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal D_in     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal w_enable : STD_LOGIC := '0';

    signal Read_A   : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal Read_B   : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal Read_C   : STD_LOGIC_VECTOR(2 downto 0) := "000";

    signal Clk      : STD_LOGIC := '0';

    signal Q_A      : STD_LOGIC_VECTOR(15 downto 0);
    signal Q_B      : STD_LOGIC_VECTOR(15 downto 0);
    signal Q_C      : STD_LOGIC_VECTOR(15 downto 0);

begin

    -- Instantiate Register File
    UUT: Register_File
        port map (
            Wr_addr  => Wr_addr,
            D_in     => D_in,
            w_enable => w_enable,

            Read_A   => Read_A,
            Read_B   => Read_B,
            Read_C   => Read_C,

            Clk      => Clk,

            Q_A      => Q_A,
            Q_B      => Q_B,
            Q_C      => Q_C
        );

    -- 10 ns clock
    Clk <= not Clk after 5 ns;

    process
    begin

        --------------------------------------------------
        -- TEST 1: Write 0x1111 to r0
        --------------------------------------------------

        Wr_addr  <= "000";
        D_in     <= x"1111";
        w_enable <= '1';

        wait until rising_edge(Clk);
        wait for 1 ns;

        w_enable <= '0';

        Read_A <= "000";

        wait for 1 ns;

        assert Q_A = x"1111"
            report "ERROR: r0 was not written correctly"
            severity error;


        --------------------------------------------------
        -- TEST 2: Write 0x2222 to r1
        --------------------------------------------------

        Wr_addr  <= "001";
        D_in     <= x"2222";
        w_enable <= '1';

        wait until rising_edge(Clk);
        wait for 1 ns;

        w_enable <= '0';

        Read_A <= "001";

        wait for 1 ns;

        assert Q_A = x"2222"
            report "ERROR: r1 was not written correctly"
            severity error;


        --------------------------------------------------
        -- TEST 3: Write 0x3333 to r2
        --------------------------------------------------

        Wr_addr  <= "010";
        D_in     <= x"3333";
        w_enable <= '1';

        wait until rising_edge(Clk);
        wait for 1 ns;

        w_enable <= '0';


        --------------------------------------------------
        -- TEST 4: Read r0, r1, r2 simultaneously
        --------------------------------------------------

        Read_A <= "000";
        Read_B <= "001";
        Read_C <= "010";

        wait for 1 ns;

        assert Q_A = x"1111"
            report "ERROR: Q_A did not read r0 correctly"
            severity error;

        assert Q_B = x"2222"
            report "ERROR: Q_B did not read r1 correctly"
            severity error;

        assert Q_C = x"3333"
            report "ERROR: Q_C did not read r2 correctly"
            severity error;


        --------------------------------------------------
        -- TEST 5: Make sure writing is disabled
        --------------------------------------------------

        Wr_addr  <= "000";
        D_in     <= x"FFFF";
        w_enable <= '0';

        wait until rising_edge(Clk);
        wait for 1 ns;

        Read_A <= "000";

        wait for 1 ns;

        assert Q_A = x"1111"
            report "ERROR: Register changed when w_enable = 0"
            severity error;


        --------------------------------------------------
        -- TEST 6: Read same register from all ports
        --------------------------------------------------

        Read_A <= "001";
        Read_B <= "001";
        Read_C <= "001";

        wait for 1 ns;

        assert Q_A = x"2222"
            report "ERROR: Q_A failed same-register read"
            severity error;

        assert Q_B = x"2222"
            report "ERROR: Q_B failed same-register read"
            severity error;

        assert Q_C = x"2222"
            report "ERROR: Q_C failed same-register read"
            severity error;


        --------------------------------------------------
        -- TEST 7: Write to r7
        --------------------------------------------------

        Wr_addr  <= "111";
        D_in     <= x"ABCD";
        w_enable <= '1';

        wait until rising_edge(Clk);
        wait for 1 ns;

        w_enable <= '0';

        Read_C <= "111";

        wait for 1 ns;

        assert Q_C = x"ABCD"
            report "ERROR: r7 was not written correctly"
            severity error;


        report "Register File testbench PASSED"
            severity note;

        wait;

    end process;

end Behavioral;
