-- libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Testbench has no ports
entity Memory_tb is
end Memory_tb;

architecture Behavioral of Memory_tb is

    -- Component declaration
    component Memory
        Port (
            Addr      : in  STD_LOGIC_VECTOR(15 downto 0);
            D_in      : in  STD_LOGIC_VECTOR(15 downto 0);
            w_enable  : in  STD_LOGIC;
            Clk       : in  STD_LOGIC;
            Q         : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Testbench signals
    signal Addr      : STD_LOGIC_VECTOR(15 downto 0) := x"0000";
    signal D_in      : STD_LOGIC_VECTOR(15 downto 0) := x"0000";
    signal w_enable  : STD_LOGIC := '0';
    signal Clk       : STD_LOGIC := '0';
    signal Q         : STD_LOGIC_VECTOR(15 downto 0);

begin

    ------------------------------------------------------------
    -- Instantiate Memory
    ------------------------------------------------------------

    UUT: Memory
        port map (
            Addr      => Addr,
            D_in      => D_in,
            w_enable  => w_enable,
            Clk       => Clk,
            Q         => Q
        );


    ------------------------------------------------------------
    -- Clock
    -- 10 ns period
    ------------------------------------------------------------

    Clk <= not Clk after 5 ns;


    ------------------------------------------------------------
    -- Test Process
    ------------------------------------------------------------

    process
    begin

        ------------------------------------------------------------
        -- TEST 1
        -- Write 0x1234 to address 0x0010
        ------------------------------------------------------------

        Addr     <= x"0010";
        D_in     <= x"1234";
        w_enable <= '1';

        wait for 20 ns;


        ------------------------------------------------------------
        -- TEST 2
        -- Disable writing
        -- Read address 0x0010
        --
        -- Q should be 0x1234
        ------------------------------------------------------------

        w_enable <= '0';

        wait for 20 ns;


        ------------------------------------------------------------
        -- TEST 3
        -- Change address to 0x0020
        --
        -- Nothing has been written here yet,
        -- so Q should be 0x0000.
        ------------------------------------------------------------

        Addr <= x"0020";

        wait for 20 ns;


        ------------------------------------------------------------
        -- TEST 4
        -- Write 0xABCD to address 0x0020
        ------------------------------------------------------------

        D_in     <= x"ABCD";
        w_enable <= '1';

        wait for 20 ns;


        ------------------------------------------------------------
        -- TEST 5
        -- Disable writing
        -- Read address 0x0020
        --
        -- Q should be 0xABCD
        ------------------------------------------------------------

        w_enable <= '0';

        wait for 20 ns;


        ------------------------------------------------------------
        -- TEST 6
        -- Return to address 0x0010
        --
        -- Q should still be 0x1234.
        -- This verifies that writing address 0x0020
        -- did not affect address 0x0010.
        ------------------------------------------------------------

        Addr <= x"0010";

        wait for 20 ns;


        ------------------------------------------------------------
        -- TEST 7
        -- Attempt to write while write enable is OFF
        --
        -- D_in changes to FFFF, but memory should NOT change.
        ------------------------------------------------------------

        D_in     <= x"FFFF";
        w_enable <= '0';

        wait for 20 ns;


        ------------------------------------------------------------
        -- TEST 8
        -- Read address 0x0010 again
        --
        -- Q should still be 0x1234.
        ------------------------------------------------------------

        Addr <= x"0010";

        wait for 20 ns;


        ------------------------------------------------------------
        -- TEST 9
        -- Write another value to address 0x0010
        ------------------------------------------------------------

        D_in     <= x"5555";
        w_enable <= '1';

        wait for 20 ns;


        ------------------------------------------------------------
        -- TEST 10
        -- Read updated value
        --
        -- Q should be 0x5555
        ------------------------------------------------------------

        w_enable <= '0';

        wait for 20 ns;


        ------------------------------------------------------------
        -- End simulation
        ------------------------------------------------------------

        wait;

    end process;

end Behavioral;