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
    signal D_in     : STD_LOGIC_VECTOR(15 downto 0) := x"0000";
    signal w_enable : STD_LOGIC := '0';

    signal Read_A   : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal Read_B   : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal Read_C   : STD_LOGIC_VECTOR(2 downto 0) := "000";

    signal Clk      : STD_LOGIC := '0';

    signal Q_A      : STD_LOGIC_VECTOR(15 downto 0);
    signal Q_B      : STD_LOGIC_VECTOR(15 downto 0);
    signal Q_C      : STD_LOGIC_VECTOR(15 downto 0);

begin

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

        ------------------------------------------------------------
        -- Write r0 = 0x1111
        ------------------------------------------------------------

        Wr_addr  <= "000";
        D_in     <= x"1111";
        w_enable <= '1';

        wait for 20 ns;


        ------------------------------------------------------------
        -- Write r1 = 0x2222
        ------------------------------------------------------------

        Wr_addr <= "001";
        D_in    <= x"2222";

        wait for 20 ns;


        ------------------------------------------------------------
        -- Write r2 = 0x3333
        ------------------------------------------------------------

        Wr_addr <= "010";
        D_in    <= x"3333";

        wait for 20 ns;


        ------------------------------------------------------------
        -- Stop writing
        ------------------------------------------------------------

        w_enable <= '0';

        ------------------------------------------------------------
        -- Read r0, r1, r2 simultaneously
        ------------------------------------------------------------

        Read_A <= "000";
        Read_B <= "001";
        Read_C <= "010";

        wait for 30 ns;


        ------------------------------------------------------------
        -- Read r2, r0, r1 simultaneously
        ------------------------------------------------------------

        Read_A <= "010";
        Read_B <= "000";
        Read_C <= "001";

        wait for 30 ns;


        ------------------------------------------------------------
        -- Read r1 from all three ports
        ------------------------------------------------------------

        Read_A <= "001";
        Read_B <= "001";
        Read_C <= "001";

        wait for 30 ns;


        ------------------------------------------------------------
        -- Write r7 = ABCD
        ------------------------------------------------------------

        Wr_addr  <= "111";
        D_in     <= x"ABCD";
        w_enable <= '1';

        wait for 20 ns;


        ------------------------------------------------------------
        -- Stop writing and read r7
        ------------------------------------------------------------

        w_enable <= '0';

        Read_A <= "111";
        Read_B <= "000";
        Read_C <= "010";

        wait for 30 ns;


        wait;

    end process;

end Behavioral;