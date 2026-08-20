----------------------------------------------------------------------------
-- Controller_tb.vhd
--
-- Testbench for the RiSC-16 Controller FSM.
-- Failures are reported and counted but do not abort the run; a pass/fail
-- summary is printed at the end.
----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Controller_tb is
end Controller_tb;

architecture Behavioral of Controller_tb is

    component Controller
        Port(
            Clk             : in  STD_LOGIC;
            Mem_Output      : in  STD_LOGIC_VECTOR(15 downto 0);
            IR              : in  STD_LOGIC_VECTOR(15 downto 0);
            PC_value        : in  STD_LOGIC_VECTOR(15 downto 0);
            ALU_Result      : in  STD_LOGIC_VECTOR(15 downto 0);
            Reg_A           : in  STD_LOGIC_VECTOR(15 downto 0);
            EQ_flag         : in  STD_LOGIC;
            PC_Sel          : out STD_LOGIC;
            PC_En           : out STD_LOGIC;
            PC_Write        : out STD_LOGIC_VECTOR(15 downto 0);
            Mem_Set_Addr    : out STD_LOGIC_VECTOR(15 downto 0);
            Mem_Set_Addr_en : out STD_LOGIC;
            Mem_write       : out STD_LOGIC_VECTOR(15 downto 0);
            Mem_write_en    : out STD_LOGIC;
            IR_En           : out STD_LOGIC;
            Reg_Addr_A      : out STD_LOGIC_VECTOR(2 downto 0);
            Reg_Addr_B      : out STD_LOGIC_VECTOR(2 downto 0);
            Reg_Addr_C      : out STD_LOGIC_VECTOR(2 downto 0);
            Reg_Addr        : out STD_LOGIC_VECTOR(2 downto 0);
            Reg_write       : out STD_LOGIC_VECTOR(15 downto 0);
            Reg_w_en        : out STD_LOGIC;
            Opcode          : out STD_LOGIC_VECTOR(2 downto 0);
            Immediate       : out STD_LOGIC_VECTOR(15 downto 0);
            Read_Immediate  : out STD_LOGIC;
            Read_PC         : out STD_LOGIC
        );
    end component;

    constant T_CLK : time := 10 ns;
    constant T_CHK : time := 1 ns;   -- sample outputs this long after an edge

    -- opcodes
    constant OP_ADD  : STD_LOGIC_VECTOR(2 downto 0) := "000";
    constant OP_ADDI : STD_LOGIC_VECTOR(2 downto 0) := "001";
    constant OP_NAND : STD_LOGIC_VECTOR(2 downto 0) := "010";
    constant OP_LUI  : STD_LOGIC_VECTOR(2 downto 0) := "011";
    constant OP_SW   : STD_LOGIC_VECTOR(2 downto 0) := "100";
    constant OP_LW   : STD_LOGIC_VECTOR(2 downto 0) := "101";
    constant OP_BEQ  : STD_LOGIC_VECTOR(2 downto 0) := "110";
    constant OP_JALR : STD_LOGIC_VECTOR(2 downto 0) := "111";

    -- test instructions, assembled field by field
    --                        op      rA      rB      (pad)   rC/imm
    constant I_ADD    : STD_LOGIC_VECTOR(15 downto 0) :=
        OP_ADD  & "011" & "101" & "0000" & "010";     -- add  r3, r5, r2
    constant I_NAND   : STD_LOGIC_VECTOR(15 downto 0) :=
        OP_NAND & "001" & "010" & "0000" & "111";     -- nand r1, r2, r7
    constant I_ADDI_N : STD_LOGIC_VECTOR(15 downto 0) :=
        OP_ADDI & "010" & "110" & "1111101";          -- addi r2, r6, -3
    constant I_ADDI_P : STD_LOGIC_VECTOR(15 downto 0) :=
        OP_ADDI & "001" & "000" & "0000101";          -- addi r1, r0, +5
    constant I_LUI    : STD_LOGIC_VECTOR(15 downto 0) :=
        OP_LUI  & "100" & "0101010101";               -- lui  r4, 0x155
    constant I_BEQ    : STD_LOGIC_VECTOR(15 downto 0) :=
        OP_BEQ  & "011" & "011" & "0000101";          -- beq  r3, r3, +5
    constant I_BEQ_N  : STD_LOGIC_VECTOR(15 downto 0) :=
        OP_BEQ  & "001" & "010" & "1111000";          -- beq  r1, r2, -8
    constant I_JALR   : STD_LOGIC_VECTOR(15 downto 0) :=
        OP_JALR & "111" & "010" & "0000000";          -- jalr r7, r2
    constant I_SW     : STD_LOGIC_VECTOR(15 downto 0) :=
        OP_SW   & "010" & "101" & "0000100";          -- sw   r2, r5, +4
    constant I_LW     : STD_LOGIC_VECTOR(15 downto 0) :=
        OP_LW   & "110" & "001" & "1111110";          -- lw   r6, r1, -2

    -- unique input values so the checks can tell which source an output is
    -- wired to, not just that it is non-zero
    constant V_ALU  : STD_LOGIC_VECTOR(15 downto 0) := x"1234";
    constant V_REGA : STD_LOGIC_VECTOR(15 downto 0) := x"A5A5";
    constant V_PC   : STD_LOGIC_VECTOR(15 downto 0) := x"0100";
    constant V_LOAD : STD_LOGIC_VECTOR(15 downto 0) := x"BEEF";

    -- DUT inputs
    signal Clk        : STD_LOGIC := '0';
    signal Mem_Output : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal IR         : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal PC_value   : STD_LOGIC_VECTOR(15 downto 0) := V_PC;
    signal ALU_Result : STD_LOGIC_VECTOR(15 downto 0) := V_ALU;
    signal Reg_A      : STD_LOGIC_VECTOR(15 downto 0) := V_REGA;
    signal EQ_flag    : STD_LOGIC := '0';

    -- DUT outputs
    signal PC_Sel          : STD_LOGIC;
    signal PC_En           : STD_LOGIC;
    signal PC_Write        : STD_LOGIC_VECTOR(15 downto 0);
    signal Mem_Set_Addr    : STD_LOGIC_VECTOR(15 downto 0);
    signal Mem_Set_Addr_en : STD_LOGIC;
    signal Mem_write       : STD_LOGIC_VECTOR(15 downto 0);
    signal Mem_write_en    : STD_LOGIC;
    signal IR_En           : STD_LOGIC;
    signal Reg_Addr_A      : STD_LOGIC_VECTOR(2 downto 0);
    signal Reg_Addr_B      : STD_LOGIC_VECTOR(2 downto 0);
    signal Reg_Addr_C      : STD_LOGIC_VECTOR(2 downto 0);
    signal Reg_Addr        : STD_LOGIC_VECTOR(2 downto 0);
    signal Reg_write       : STD_LOGIC_VECTOR(15 downto 0);
    signal Reg_w_en        : STD_LOGIC;
    signal Opcode          : STD_LOGIC_VECTOR(2 downto 0);
    signal Immediate       : STD_LOGIC_VECTOR(15 downto 0);
    signal Read_Immediate  : STD_LOGIC;
    signal Read_PC         : STD_LOGIC;

    signal sim_done : BOOLEAN := false;

begin

    UUT: Controller
        port map(
            Clk             => Clk,
            Mem_Output      => Mem_Output,
            IR              => IR,
            PC_value        => PC_value,
            ALU_Result      => ALU_Result,
            Reg_A           => Reg_A,
            EQ_flag         => EQ_flag,
            PC_Sel          => PC_Sel,
            PC_En           => PC_En,
            PC_Write        => PC_Write,
            Mem_Set_Addr    => Mem_Set_Addr,
            Mem_Set_Addr_en => Mem_Set_Addr_en,
            Mem_write       => Mem_write,
            Mem_write_en    => Mem_write_en,
            IR_En           => IR_En,
            Reg_Addr_A      => Reg_Addr_A,
            Reg_Addr_B      => Reg_Addr_B,
            Reg_Addr_C      => Reg_Addr_C,
            Reg_Addr        => Reg_Addr,
            Reg_write       => Reg_write,
            Reg_w_en        => Reg_w_en,
            Opcode          => Opcode,
            Immediate       => Immediate,
            Read_Immediate  => Read_Immediate,
            Read_PC         => Read_PC
        );

    -- rising edges at 5 ns, 15 ns, 25 ns, ...
    Clk <= not Clk after T_CLK/2 when not sim_done else '0';

    process

        variable errors : integer := 0;

        procedure chk(cond : in boolean; msg : in string) is
        begin
            if not cond then
                report "ERROR: " & msg severity error;
                errors := errors + 1;
            end if;
        end procedure;

        -- nothing is written and no memory access is in flight
        procedure chk_quiet(ctx : in string) is
        begin
            chk(Reg_w_en        = '0', ctx & ": Reg_w_en must be 0");
            chk(Mem_write_en    = '0', ctx & ": Mem_write_en must be 0");
            chk(Mem_Set_Addr_en = '0', ctx & ": Mem_Set_Addr_en must be 0");
            chk(IR_En           = '0', ctx & ": IR_En must be 0");
        end procedure;

        -- the register write port, checked as a set
        procedure chk_reg_write(ctx  : in string;
                                addr : in STD_LOGIC_VECTOR(2 downto 0);
                                data : in STD_LOGIC_VECTOR(15 downto 0)) is
        begin
            chk(Reg_Addr  = addr, ctx & ": wrong register write address");
            chk(Reg_write = data, ctx & ": wrong register write data source");
            chk(Reg_w_en  = '1',  ctx & ": Reg_w_en should be 1");
        end procedure;

        -- Runs FETCH and DECODE for one instruction and leaves the FSM in its
        -- execute state, sampled T_CHK after the entering edge. Must be called
        -- T_CHK after the edge that entered FETCH.
        procedure exec_instr(instr : in STD_LOGIC_VECTOR(15 downto 0)) is
        begin
            -- FETCH: everything idle, PC holds while the read is in flight
            chk_quiet("FETCH");
            chk(PC_En  = '0', "FETCH: PC_En must be 0");
            chk(PC_Sel = '0', "FETCH: PC_Sel must be 0");

            Mem_Output <= instr;             -- memory returns the fetched word

            wait until rising_edge(Clk);     -- FETCH -> DECODE
            wait for T_CHK;

            -- DECODE: IR still holds the previous instruction, so if the DUT
            -- dispatched on IR instead of Mem_Output the checks below fail
            chk(IR_En = '1', "DECODE: IR_En must be 1");
            chk(PC_En = '0', "DECODE: PC_En must be 0");
            chk(Reg_w_en        = '0', "DECODE: Reg_w_en must be 0");
            chk(Mem_write_en    = '0', "DECODE: Mem_write_en must be 0");
            chk(Mem_Set_Addr_en = '0', "DECODE: Mem_Set_Addr_en must be 0");

            wait until rising_edge(Clk);     -- DECODE -> execute
            IR <= instr;                     -- the IR captured it on that edge
            wait for T_CHK;
        end procedure;

        procedure step is                    -- advance one state
        begin
            wait until rising_edge(Clk);
            wait for T_CHK;
        end procedure;

    begin

        wait for T_CHK;    -- FSM is in its power-up state, FETCH

        report "=== RiSC-16 Controller testbench starting ===" severity note;

        --------------------------------------------------------------------
        -- TEST 1: ADD (RRR)   add r3, r5, r2
        --------------------------------------------------------------------
        exec_instr(I_ADD);

        chk(Opcode     = OP_ADD, "ADD: Opcode should be 000");
        chk(Reg_Addr_B = "101",  "ADD: Reg_Addr_B should be rB = 5");
        chk(Reg_Addr_C = "010",  "ADD: Reg_Addr_C should be rC = 2");
        chk_reg_write("ADD", "011", V_ALU);
        chk(PC_En          = '1', "ADD: PC_En should be 1");
        chk(PC_Sel         = '0', "ADD: PC_Sel should be 0, next PC is sequential");
        chk(Read_Immediate = '0', "ADD: Read_Immediate should be 0");
        chk(Read_PC        = '0', "ADD: Read_PC should be 0");
        chk(Mem_write_en    = '0', "ADD: Mem_write_en should be 0");
        chk(Mem_Set_Addr_en = '0', "ADD: Mem_Set_Addr_en should be 0");

        step;

        --------------------------------------------------------------------
        -- TEST 2: NAND (RRR)   nand r1, r2, r7
        -- Shares the RRR state with ADD, so only the opcode and the register
        -- fields should differ.
        --------------------------------------------------------------------
        exec_instr(I_NAND);

        chk(Opcode     = OP_NAND, "NAND: Opcode should be 010");
        chk(Reg_Addr_B = "010",   "NAND: Reg_Addr_B should be rB = 2");
        chk(Reg_Addr_C = "111",   "NAND: Reg_Addr_C should be rC = 7");
        chk_reg_write("NAND", "001", V_ALU);
        chk(PC_En          = '1', "NAND: PC_En should be 1");
        chk(Read_Immediate = '0', "NAND: Read_Immediate should be 0");

        step;

        --------------------------------------------------------------------
        -- TEST 3: ADDI, negative immediate   addi r2, r6, -3
        --------------------------------------------------------------------
        exec_instr(I_ADDI_N);

        chk(Opcode         = OP_ADDI, "ADDI: Opcode should be 001");
        chk(Reg_Addr_B     = "110",   "ADDI: Reg_Addr_B should be rB = 6");
        chk(Immediate      = x"FFFD", "ADDI: -3 should sign-extend to 0xFFFD");
        chk(Read_Immediate = '1',     "ADDI: Read_Immediate should be 1");
        chk_reg_write("ADDI", "010", V_ALU);
        chk(PC_En = '1', "ADDI: PC_En should be 1");
        chk(Mem_write_en    = '0', "ADDI: Mem_write_en should be 0");
        chk(Mem_Set_Addr_en = '0', "ADDI: Mem_Set_Addr_en should be 0");

        step;

        --------------------------------------------------------------------
        -- TEST 4: ADDI, positive immediate   addi r1, r0, +5
        --------------------------------------------------------------------
        exec_instr(I_ADDI_P);

        chk(Immediate  = x"0005", "ADDI: +5 should zero-extend to 0x0005");
        chk(Reg_Addr_B = "000",   "ADDI: Reg_Addr_B should be rB = 0");
        chk_reg_write("ADDI", "001", V_ALU);

        step;

        --------------------------------------------------------------------
        -- TEST 5: LUI (RI)   lui r4, 0x155
        -- The ALU does the shift-by-6, so the immediate should arrive
        -- zero-extended as 0x0155 and not pre-shifted to 0x5540.
        --------------------------------------------------------------------
        exec_instr(I_LUI);

        chk(Opcode         = OP_LUI,  "LUI: Opcode should be 011");
        chk(Immediate      = x"0155", "LUI: imm10 should zero-extend to 0x0155");
        chk(Read_Immediate = '1',     "LUI: Read_Immediate should be 1");
        chk_reg_write("LUI", "100", V_ALU);
        chk(PC_En = '1', "LUI: PC_En should be 1");

        step;

        --------------------------------------------------------------------
        -- TEST 6: BEQ taken   beq r3, r3, +5
        -- Operands come out of the A and B read ports; the target arrives on
        -- PC_Write from the ALU, fed the PC and the immediate.
        --------------------------------------------------------------------
        EQ_flag <= '1';
        exec_instr(I_BEQ);

        chk(Opcode         = OP_BEQ,  "BEQ: Opcode should be 110");
        chk(Reg_Addr_A     = "011",   "BEQ: Reg_Addr_A should be rA = 3");
        chk(Reg_Addr_B     = "011",   "BEQ: Reg_Addr_B should be rB = 3");
        chk(Read_PC        = '1',     "BEQ: Read_PC should be 1");
        chk(Read_Immediate = '1',     "BEQ: Read_Immediate should be 1");
        chk(Immediate      = x"0005", "BEQ: +5 should sign-extend to 0x0005");
        chk(PC_Write       = V_ALU,   "BEQ: PC_Write should come from ALU_Result");
        chk(PC_Sel         = '1',     "BEQ taken: PC_Sel should follow EQ_flag");
        chk(PC_En          = '1',     "BEQ: PC_En should be 1");
        chk(Reg_w_en       = '0',     "BEQ: Reg_w_en must be 0");
        chk(Mem_write_en    = '0',    "BEQ: Mem_write_en must be 0");
        chk(Mem_Set_Addr_en = '0',    "BEQ: Mem_Set_Addr_en must be 0");

        step;

        --------------------------------------------------------------------
        -- TEST 7: BEQ not taken   beq r1, r2, -8
        --------------------------------------------------------------------
        EQ_flag <= '0';
        exec_instr(I_BEQ_N);

        chk(Reg_Addr_A = "001",   "BEQ: Reg_Addr_A should be rA = 1");
        chk(Reg_Addr_B = "010",   "BEQ: Reg_Addr_B should be rB = 2");
        chk(Immediate  = x"FFF8", "BEQ: -8 should sign-extend to 0xFFF8");
        chk(PC_Sel     = '0',     "BEQ not taken: PC_Sel should be 0");
        chk(PC_En      = '1',     "BEQ not taken: PC_En should still be 1");
        chk(Reg_w_en   = '0',     "BEQ: Reg_w_en must be 0");

        step;

        --------------------------------------------------------------------
        -- TEST 8: JALR   jalr r7, r2
        -- The link value comes from PC_value, not the ALU; the target comes
        -- from the ALU, which is given rB and r0.
        --------------------------------------------------------------------
        exec_instr(I_JALR);

        chk(Opcode     = OP_JALR, "JALR: Opcode should be 111");
        chk(Reg_Addr_B = "010",   "JALR: Reg_Addr_B should be rB = 2");
        chk(Reg_Addr_C = "000",   "JALR: Reg_Addr_C should be r0 so the ALU adds 0");
        chk_reg_write("JALR", "111", V_PC);
        chk(PC_Write = V_ALU, "JALR: PC_Write should come from ALU_Result");
        chk(PC_Sel   = '1',   "JALR: PC_Sel should be 1, the jump always takes");
        chk(PC_En    = '1',   "JALR: PC_En should be 1");
        chk(Read_Immediate  = '0', "JALR: Read_Immediate should be 0");
        chk(Mem_write_en    = '0', "JALR: Mem_write_en should be 0");
        chk(Mem_Set_Addr_en = '0', "JALR: Mem_Set_Addr_en should be 0");

        step;

        --------------------------------------------------------------------
        -- TEST 9: SW   sw r2, r5, +4
        -- Address from the ALU (rB + imm), stored data from the A read port.
        --------------------------------------------------------------------
        exec_instr(I_SW);

        chk(Opcode          = OP_SW,   "SW: Opcode should be 100");
        chk(Reg_Addr_A      = "010",   "SW: Reg_Addr_A should be rA = 2, the stored value");
        chk(Reg_Addr_B      = "101",   "SW: Reg_Addr_B should be rB = 5, the base");
        chk(Immediate       = x"0004", "SW: +4 should sign-extend to 0x0004");
        chk(Read_Immediate  = '1',     "SW: Read_Immediate should be 1");
        chk(Mem_Set_Addr    = V_ALU,   "SW: Mem_Set_Addr should come from ALU_Result");
        chk(Mem_Set_Addr_en = '1',     "SW: Mem_Set_Addr_en should be 1");
        chk(Mem_write       = V_REGA,  "SW: Mem_write should come from Reg_A");
        chk(Mem_write_en    = '1',     "SW: Mem_write_en should be 1");
        chk(PC_En           = '1',     "SW: PC_En should be 1");
        chk(PC_Sel          = '0',     "SW: PC_Sel should be 0");
        chk(Reg_w_en        = '0',     "SW: Reg_w_en must be 0");

        step;   -- single execute state, so this returns to FETCH

        --------------------------------------------------------------------
        -- TEST 10: LW   lw r6, r1, -2
        --------------------------------------------------------------------
        exec_instr(I_LW);

        chk(Opcode          = OP_LW,   "LW: Opcode should be 101");
        chk(Reg_Addr_B      = "001",   "LW: Reg_Addr_B should be rB = 1, the base");
        chk(Immediate       = x"FFFE", "LW: -2 should sign-extend to 0xFFFE");
        chk(Read_Immediate  = '1',     "LW: Read_Immediate should be 1");
        chk(Mem_Set_Addr    = V_ALU,   "LW: Mem_Set_Addr should come from ALU_Result");
        chk(Mem_Set_Addr_en = '1',     "LW: Mem_Set_Addr_en should be 1");
        chk(Mem_write_en    = '0',     "LW: Mem_write_en must be 0");
        chk(Reg_w_en        = '0',     "LW: Reg_w_en must be 0, the data is not back yet");
        chk(PC_En           = '0',     "LW: PC_En must be 0, the instruction is not done");

        wait until rising_edge(Clk);   -- LW -> LOAD_A
        Mem_Output <= V_LOAD;          -- the loaded word appears on the read port
        wait for T_CHK;

        chk_reg_write("LOAD_A", "110", V_LOAD);
        chk(PC_En = '1', "LOAD_A: PC_En should be 1, the instruction retires here");
        chk(PC_Sel = '0', "LOAD_A: PC_Sel should be 0");
        chk(Mem_write_en = '0', "LOAD_A: Mem_write_en must be 0");
        -- the memory read is asynchronous, so the data address has to stay
        -- selected or Mem_Output reverts to the instruction at the PC
        chk(Mem_Set_Addr    = V_ALU, "LOAD_A: the data address must still be driven");
        chk(Mem_Set_Addr_en = '1',   "LOAD_A: the data address must still be selected");

        step;   -- LOAD_A -> FETCH
        chk_quiet("FETCH after LW");

        --------------------------------------------------------------------
        -- Summary
        --------------------------------------------------------------------
        if errors = 0 then
            report "CONTROLLER TESTBENCH PASSED" severity note;
        else
            report "CONTROLLER TESTBENCH FAILED: "
                 & integer'image(errors) & " error(s)" severity error;
        end if;

        sim_done <= true;
        wait;

    end process;

end Behavioral;