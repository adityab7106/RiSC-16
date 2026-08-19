library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU_tb is
end ALU_tb;

architecture Behavioral of ALU_tb is

    component ALU
        Port(
            RegB        : in  STD_LOGIC_VECTOR(15 downto 0);
            RegC_or_Imm : in  STD_LOGIC_VECTOR(15 downto 0);
            Opcode      : in  STD_LOGIC_VECTOR(2 downto 0);
            Result      : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    signal RegB        : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal RegC_or_Imm : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal Opcode      : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal Result      : STD_LOGIC_VECTOR(15 downto 0);

begin

    UUT: ALU
        port map(
            RegB        => RegB,
            RegC_or_Imm => RegC_or_Imm,
            Opcode      => Opcode,
            Result      => Result
        );

    process
    begin

        ------------------------------------------------------------
        -- ADD
        -- 10 + 5 = 15
        ------------------------------------------------------------

        RegB        <= x"000A";
        RegC_or_Imm <= x"0005";
        Opcode      <= "000";

        wait for 100 ns;


        ------------------------------------------------------------
        -- ADDI
        -- 10 + (-3) = 7
        ------------------------------------------------------------

        RegB        <= x"000A";
        RegC_or_Imm <= x"FFFD";
        Opcode      <= "001";

        wait for 100 ns;


        ------------------------------------------------------------
        -- NAND
        -- FFFF NAND 0000 = FFFF
        ------------------------------------------------------------

        RegB        <= x"FFFF";
        RegC_or_Imm <= x"0000";
        Opcode      <= "010";

        wait for 100 ns;


        ------------------------------------------------------------
        -- LUI
        -- 0155 << 6 = 5540
        ------------------------------------------------------------

        RegB        <= x"0000";
        RegC_or_Imm <= x"0155";
        Opcode      <= "011";

        wait for 100 ns;


        ------------------------------------------------------------
        -- SW
        -- 2000 + 0010 = 2010
        ------------------------------------------------------------

        RegB        <= x"2000";
        RegC_or_Imm <= x"0010";
        Opcode      <= "100";

        wait for 100 ns;


        ------------------------------------------------------------
        -- LW
        -- 1000 + (-16) = 0FF0
        ------------------------------------------------------------

        RegB        <= x"1000";
        RegC_or_Imm <= x"FFF0";
        Opcode      <= "101";

        wait for 100 ns;


        ------------------------------------------------------------
        -- BEQ
        -- ALU currently performs addition
        -- 10 + 10 = 20
        ------------------------------------------------------------

        RegB        <= x"000A";
        RegC_or_Imm <= x"000A";
        Opcode      <= "110";

        wait for 100 ns;


        ------------------------------------------------------------
        -- JALR / DEFAULT
        -- Opcode 111 currently produces 0000
        ------------------------------------------------------------

        RegB        <= x"1234";
        RegC_or_Imm <= x"5678";
        Opcode      <= "111";

        wait for 100 ns;


        ------------------------------------------------------------
        -- Hold simulation so waveform remains visible
        ------------------------------------------------------------

        wait;

    end process;

end Behavioral;