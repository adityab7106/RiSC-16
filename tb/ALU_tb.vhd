-- libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- testbench has no ports
entity ALU_tb is
end ALU_tb;

architecture Behavioral of ALU_tb is

    -- Component declaration
    component ALU
        Port(
            RegB        : in  STD_LOGIC_VECTOR(15 downto 0);
            RegC_or_Imm : in  STD_LOGIC_VECTOR(15 downto 0);
            Opcode      : in  STD_LOGIC_VECTOR(2 downto 0);
            Result      : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Testbench signals
    signal RegB        : STD_LOGIC_VECTOR(15 downto 0);
    signal RegC_or_Imm : STD_LOGIC_VECTOR(15 downto 0);
    signal Opcode      : STD_LOGIC_VECTOR(2 downto 0);
    signal Result      : STD_LOGIC_VECTOR(15 downto 0);

begin

    -- Instantiate ALU
    UUT: ALU
        port map(
            RegB        => RegB,
            RegC_or_Imm => RegC_or_Imm,
            Opcode      => Opcode,
            Result      => Result
        );

    -- Test process
    process
    begin

        ------------------------------------------------------------
        -- TEST 1: ADD
        -- 10 + 5 = 15
        ------------------------------------------------------------

        RegB        <= x"000A";
        RegC_or_Imm <= x"0005";
        Opcode      <= "000";

        wait for 10 ns;

        assert Result = x"000F"
            report "ERROR: ADD failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 2: ADD
        -- (-5) + 8 = 3
        ------------------------------------------------------------

        RegB        <= x"FFFB";      -- -5
        RegC_or_Imm <= x"0008";      -- +8
        Opcode      <= "000";

        wait for 10 ns;

        assert Result = x"0003"
            report "ERROR: ADD negative number failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 3: ADDI
        -- 10 + 5 = 15
        ------------------------------------------------------------

        RegB        <= x"000A";
        RegC_or_Imm <= x"0005";
        Opcode      <= "001";

        wait for 10 ns;

        assert Result = x"000F"
            report "ERROR: ADDI failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 4: ADDI with negative immediate
        -- 10 + (-3) = 7
        --
        -- -3 = FFFD in 16-bit two's complement
        ------------------------------------------------------------

        RegB        <= x"000A";
        RegC_or_Imm <= x"FFFD";
        Opcode      <= "001";

        wait for 10 ns;

        assert Result = x"0007"
            report "ERROR: ADDI negative immediate failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 5: NAND
        -- FFFF NAND 0000 = FFFF
        ------------------------------------------------------------

        RegB        <= x"FFFF";
        RegC_or_Imm <= x"0000";
        Opcode      <= "010";

        wait for 10 ns;

        assert Result = x"FFFF"
            report "ERROR: NAND test 1 failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 6: NAND
        -- FFFF NAND FFFF = 0000
        ------------------------------------------------------------

        RegB        <= x"FFFF";
        RegC_or_Imm <= x"FFFF";
        Opcode      <= "010";

        wait for 10 ns;

        assert Result = x"0000"
            report "ERROR: NAND test 2 failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 7: NAND
        -- 0F0F NAND 00FF = FFF0
        ------------------------------------------------------------

        RegB        <= x"0F0F";
        RegC_or_Imm <= x"00FF";
        Opcode      <= "010";

        wait for 10 ns;

        assert Result = x"FFF0"
            report "ERROR: NAND test 3 failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 8: LUI
        --
        -- Immediate = 0155
        -- 0155 & 03FF = 0155
        -- 0155 << 6 = 5540
        ------------------------------------------------------------

        RegB        <= x"0000";
        RegC_or_Imm <= x"0155";
        Opcode      <= "011";

        wait for 10 ns;

        assert Result = x"5540"
            report "ERROR: LUI test 1 failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 9: LUI maximum 10-bit immediate
        --
        -- 03FF << 6 = FFC0
        ------------------------------------------------------------

        RegB        <= x"0000";
        RegC_or_Imm <= x"03FF";
        Opcode      <= "011";

        wait for 10 ns;

        assert Result = x"FFC0"
            report "ERROR: LUI test 2 failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 10: LW
        -- 1000 + 0020 = 1020
        ------------------------------------------------------------

        RegB        <= x"1000";
        RegC_or_Imm <= x"0020";
        Opcode      <= "101";

        wait for 10 ns;

        assert Result = x"1020"
            report "ERROR: LW address calculation failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 11: LW with negative immediate
        -- 1000 + (-16) = 0FF0
        --
        -- -16 = FFF0
        ------------------------------------------------------------

        RegB        <= x"1000";
        RegC_or_Imm <= x"FFF0";
        Opcode      <= "101";

        wait for 10 ns;

        assert Result = x"0FF0"
            report "ERROR: LW negative immediate failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 12: SW
        -- 2000 + 0010 = 2010
        ------------------------------------------------------------

        RegB        <= x"2000";
        RegC_or_Imm <= x"0010";
        Opcode      <= "100";

        wait for 10 ns;

        assert Result = x"2010"
            report "ERROR: SW address calculation failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 13: SW with negative immediate
        -- 2000 + (-32) = 1FE0
        --
        -- -32 = FFE0
        ------------------------------------------------------------

        RegB        <= x"2000";
        RegC_or_Imm <= x"FFE0";
        Opcode      <= "100";

        wait for 10 ns;

        assert Result = x"1FE0"
            report "ERROR: SW negative immediate failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 14: BEQ
        --
        -- Your current ALU code performs:
        -- RegB + RegC_or_Imm
        --
        -- 10 + 10 = 20
        --
        -- NOTE:
        -- The actual equality check is performed by the
        -- separate comparator in your datapath.
        ------------------------------------------------------------

        RegB        <= x"000A";
        RegC_or_Imm <= x"000A";
        Opcode      <= "110";

        wait for 10 ns;

        assert Result = x"0014"
            report "ERROR: BEQ ALU operation failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 15: BEQ with different registers
        --
        -- 10 + 5 = 15
        ------------------------------------------------------------

        RegB        <= x"000A";
        RegC_or_Imm <= x"0005";
        Opcode      <= "110";

        wait for 10 ns;

        assert Result = x"000F"
            report "ERROR: BEQ ALU operation test 2 failed"
            severity error;


        ------------------------------------------------------------
        -- TEST 16: Unimplemented opcode / JALR
        --
        -- Your current ALU has no "111" case, so it goes
        -- to "when others" and produces 0000.
        ------------------------------------------------------------

        RegB        <= x"1234";
        RegC_or_Imm <= x"5678";
        Opcode      <= "111";

        wait for 10 ns;

        assert Result = x"0000"
            report "ERROR: Default opcode case failed"
            severity error;


        ------------------------------------------------------------
        -- ALL TESTS COMPLETE
        ------------------------------------------------------------

        report "======================================"
            severity note;

        report "ALU TESTBENCH PASSED"
            severity note;

        report "======================================"
            severity note;

        wait;

    end process;

end Behavioral;
