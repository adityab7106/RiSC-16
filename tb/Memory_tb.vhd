library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Memory_tb is
end Memory_tb;

architecture Behavioral of Memory_tb is

    component Memory
        Port (
            Addr      : in  STD_LOGIC_VECTOR(15 downto 0);
            D_in      : in  STD_LOGIC_VECTOR(15 downto 0);
            w_enable  : in  STD_LOGIC;
            Clk       : in  STD_LOGIC;
            Q         : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    signal Addr     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal D_in     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal w_enable : STD_LOGIC := '0';
    signal Clk      : STD_LOGIC := '0';
    signal Q        : STD_LOGIC_VECTOR(15 downto 0);

begin

    -- Instantiate Memory
    UUT: Memory
        port map (
            Addr     => Addr,
            D_in     => D_in,
            w_enable => w_enable,
            Clk      => Clk,
            Q        => Q
        );

    -- 10 ns clock
    Clk <= not Clk after 5 ns;

    process
    begin

        --------------------------------------------------
        -- TEST 1: Write 0x1234 to address 0x0010
        --------------------------------------------------

        Addr     <= x"0010";
        D_in     <= x"1234";
        w_enable <= '1';

        wait until rising_edge(Clk);
        wait for 1 ns;

        -- Disable writing
        w_enable <= '0';

        -- Check asynchronous read
        wait for 1 ns;

        assert Q = x"1234"
            report "ERROR: Memory read failed at address 0x0010"
            severity error;


        --------------------------------------------------
        -- TEST 2: Write 0xABCD to address 0x0020
        --------------------------------------------------

        Addr     <= x"0020";
        D_in     <= x"ABCD";
        w_enable <= '1';

        wait until rising_edge(Clk);
        wait for 1 ns;

        w_enable <= '0';

        assert Q = x"ABCD"
            report "ERROR: Memory read failed at address 0x0020"
            severity error;


        --------------------------------------------------
        -- TEST 3: Make sure address 0x0010 still
        -- contains 0x1234
        --------------------------------------------------

        Addr <= x"0010";

        wait for 1 ns;

        assert Q = x"1234"
            report "ERROR: Memory location 0x0010 was incorrectly modified"
            severity error;


        --------------------------------------------------
        -- TEST 4: Make sure writing is disabled
        --------------------------------------------------

        Addr     <= x"0030";
        D_in     <= x"FFFF";
        w_enable <= '0';

        wait until rising_edge(Clk);
        wait for 1 ns;

        -- Address 0x0030 should still contain 0
        assert Q = x"0000"
            report "ERROR: Memory changed when w_enable = 0"
            severity error;


        --------------------------------------------------
        -- TEST 5: Write 0x5555 to address 0x0030
        --------------------------------------------------

        D_in     <= x"5555";
        w_enable <= '1';

        wait until rising_edge(Clk);
        wait for 1 ns;

        w_enable <= '0';

        assert Q = x"5555"
            report "ERROR: Memory failed to write 0x5555"
            severity error;


        report "Memory testbench PASSED"
            severity note;

        wait;

    end process;

end Behavioral;