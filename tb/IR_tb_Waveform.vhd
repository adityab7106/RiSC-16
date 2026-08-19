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

    signal D_in : STD_LOGIC_VECTOR(15 downto 0) := x"0000";
    signal En   : STD_LOGIC := '0';
    signal Clk  : STD_LOGIC := '0';
    signal Q    : STD_LOGIC_VECTOR(15 downto 0);

begin

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

        ------------------------------------------------------------
        -- Initially disabled
        ------------------------------------------------------------

        En   <= '0';
        D_in <= x"0000";

        wait for 20 ns;


        ------------------------------------------------------------
        -- Load instruction 1
        ------------------------------------------------------------

        D_in <= x"1234";
        En   <= '1';

        wait for 20 ns;


        ------------------------------------------------------------
        -- Load instruction 2
        ------------------------------------------------------------

        D_in <= x"5678";

        wait for 20 ns;


        ------------------------------------------------------------
        -- Disable
        -- Q should remain 5678
        ------------------------------------------------------------

        En   <= '0';
        D_in <= x"ABCD";

        wait for 20 ns;


        ------------------------------------------------------------
        -- Re-enable
        -- Q should become ABCD
        ------------------------------------------------------------

        En <= '1';

        wait for 20 ns;


        ------------------------------------------------------------
        -- Load another instruction
        ------------------------------------------------------------

        D_in <= x"F123";

        wait for 20 ns;


        wait;

    end process;

end Behavioral;