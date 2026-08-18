-- libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- entity declaration to define ports
entity Controller is
    Port(
        Clk             : in  STD_LOGIC;

        -- datapath inputs
        Mem_Output      : in  STD_LOGIC_VECTOR(15 downto 0);
        IR              : in  STD_LOGIC_VECTOR(15 downto 0);
        PC_value        : in  STD_LOGIC_VECTOR(15 downto 0);
        ALU_Result      : in  STD_LOGIC_VECTOR(15 downto 0);
        Reg_A           : in  STD_LOGIC_VECTOR(15 downto 0);
        EQ_flag         : in  STD_LOGIC;

        -- program counter control
        PC_Sel          : out STD_LOGIC;
        PC_En           : out STD_LOGIC;
        PC_Write        : out STD_LOGIC_VECTOR(15 downto 0);

        -- memory control
        Mem_Set_Addr    : out STD_LOGIC_VECTOR(15 downto 0);
        Mem_Set_Addr_en : out STD_LOGIC;
        Mem_write       : out STD_LOGIC_VECTOR(15 downto 0);
        Mem_write_en    : out STD_LOGIC;

        -- instruction register control
        IR_En           : out STD_LOGIC;

        -- register file control
        Reg_Addr_A      : out STD_LOGIC_VECTOR(2 downto 0);
        Reg_Addr_B      : out STD_LOGIC_VECTOR(2 downto 0);
        Reg_Addr_C      : out STD_LOGIC_VECTOR(2 downto 0);
        Reg_Addr        : out STD_LOGIC_VECTOR(2 downto 0);
        Reg_write       : out STD_LOGIC_VECTOR(15 downto 0);
        Reg_w_en        : out STD_LOGIC;

        -- ALU control
        Opcode          : out STD_LOGIC_VECTOR(2 downto 0);
        Immediate       : out STD_LOGIC_VECTOR(15 downto 0);
        Read_Immediate  : out STD_LOGIC;
        Read_PC         : out STD_LOGIC
    );
end Controller;

Architecture Behavioral of Controller is

    type state_type is (FETCH, DECODE, RRR, ADDI, LUI, SW, LW, LOAD_A, BEQ, JALR);

    signal state      : state_type := FETCH;
    signal next_state : state_type;

    -- immediate formatting
    signal Imm_Sign : STD_LOGIC_VECTOR(15 downto 0);  -- sign-extended IR[6:0]
    signal Imm_Wide : STD_LOGIC_VECTOR(15 downto 0);  -- zero-extended IR[9:0]

begin

    -- RRI-type immediates are signed (-64 to 63); the ALU adds as signed
    Imm_Sign <= STD_LOGIC_VECTOR(resize(signed(IR(6 downto 0)), 16));

    -- RI-type immediate rides in the low 10 bits; the ALU does the shift-by-6
    Imm_Wide <= "000000" & IR(9 downto 0);

    -- state register
    process(Clk) begin
        if rising_edge(Clk) then
            state <= next_state;
        end if;
    end process;

    -- NEXT STATE LOGIC
    -- dispatch reads Mem_Output, not IR, as the IR is loaded on the edge leaving
    -- DECODE, so its output is not yet valid when the branch is decided
    process(state, Mem_Output) begin
        case state is

            when FETCH =>
                next_state <= DECODE;

            when DECODE =>
                case Mem_Output(15 downto 13) is
                    when "000"  => next_state <= RRR;       -- add
                    when "001"  => next_state <= ADDI;
                    when "010"  => next_state <= RRR;       -- nand
                    when "011"  => next_state <= LUI;
                    when "100"  => next_state <= SW;
                    when "101"  => next_state <= LW;
                    when "110"  => next_state <= BEQ;
                    when others => next_state <= JALR;      -- "111"
                end case;

            when LW =>
                next_state <= LOAD_A;

            when others =>
                next_state <= FETCH;

        end case;
    end process;

    -- output logic
    process(state, IR, Imm_Sign, Imm_Wide, ALU_Result, Mem_Output,
            PC_value, Reg_A, EQ_flag) begin
            
        -- defauts
        PC_Sel          <= '0';
        PC_En           <= '0';
        PC_Write        <= (others => '0');
        Mem_Set_Addr    <= (others => '0');
        Mem_Set_Addr_en <= '0';
        Mem_write       <= (others => '0');
        Mem_write_en    <= '0';
        IR_En           <= '0';
        Reg_Addr_A      <= (others => '0');
        Reg_Addr_B      <= (others => '0');
        Reg_Addr_C      <= (others => '0');
        Reg_Addr        <= (others => '0');
        Reg_write       <= (others => '0');
        Reg_w_en        <= '0';
        Opcode          <= (others => '0');
        Immediate       <= (others => '0');
        Read_Immediate  <= '0';
        Read_PC         <= '0';

        case state is

            -- Mem_Set_Addr_en = 0 selects the PC register path into the
            -- memory address mux; the read completes on the next edge
            when FETCH =>
                null;

            when DECODE =>
                IR_En <= '1';

            -- add (000) and nand (010) share a state, differentiated by the opcode;
            when RRR =>
                Opcode     <= IR(15 downto 13);
                Reg_Addr_B <= IR(9 downto 7);
                Reg_Addr_C <= IR(2 downto 0);
                Reg_Addr   <= IR(12 downto 10);
                Reg_write  <= ALU_Result;
                Reg_w_en   <= '1';
                PC_En      <= '1';

            when ADDI =>
                Opcode         <= IR(15 downto 13);
                Reg_Addr_B     <= IR(9 downto 7);
                Immediate      <= Imm_Sign;
                Read_Immediate <= '1';
                Reg_Addr       <= IR(12 downto 10);
                Reg_write      <= ALU_Result;
                Reg_w_en       <= '1';
                PC_En          <= '1';

            -- the ALU ignores RegB for opcode 011
            when LUI =>
                Opcode         <= IR(15 downto 13);
                Immediate      <= Imm_Wide;
                Read_Immediate <= '1';
                Reg_Addr       <= IR(12 downto 10);
                Reg_write      <= ALU_Result;
                Reg_w_en       <= '1';
                PC_En          <= '1';

            -- address from the ALU, stored data from Q_A
            when SW =>
                Opcode          <= IR(15 downto 13);
                Reg_Addr_A      <= IR(12 downto 10);
                Reg_Addr_B      <= IR(9 downto 7);
                Immediate       <= Imm_Sign;
                Read_Immediate  <= '1';
                Mem_Set_Addr    <= ALU_Result;
                Mem_Set_Addr_en <= '1';
                Mem_write       <= Reg_A;
                Mem_write_en    <= '1';
                PC_En           <= '1';

            -- address only; the data arrives one clock later
            when LW =>
                Opcode          <= IR(15 downto 13);
                Reg_Addr_B      <= IR(9 downto 7);
                Immediate       <= Imm_Sign;
                Read_Immediate  <= '1';
                Mem_Set_Addr    <= ALU_Result;
                Mem_Set_Addr_en <= '1';

            -- Mem_Output is registered, so it still holds the loaded word for one edge even
            -- after the address mux has reverted to the PC path
            when LOAD_A =>
                Reg_Addr  <= IR(12 downto 10);
                Reg_write <= Mem_Output;
                Reg_w_en  <= '1';
                PC_En     <= '1';

            -- the comparator sits off Q_A/Q_B and does not contend with the
            -- ALU, so the test and the branch fit in one state
            -- IF TIMING ISSUES, THIS IS LIKLEY LONGEST PATH
            when BEQ =>
                Opcode         <= IR(15 downto 13);
                Reg_Addr_A     <= IR(12 downto 10);
                Reg_Addr_B     <= IR(9 downto 7);
                Read_PC        <= '1';
                Immediate      <= Imm_Sign;
                Read_Immediate <= '1';
                PC_Write       <= ALU_Result;
                PC_Sel         <= EQ_flag;
                PC_En          <= '1';

            -- link value bypasses the ALU via PC_value, which frees the ALU to
            -- compute the target as Q_B + R0; the register file read is async,
            -- so jalr rA, rA captures Q_B before the write edge
            when JALR =>
                Opcode     <= IR(15 downto 13);
                Reg_Addr_B <= IR(9 downto 7);
                Reg_Addr_C <= "000";
                Reg_Addr   <= IR(12 downto 10);
                Reg_write  <= PC_value;
                Reg_w_en   <= '1';
                PC_Write   <= ALU_Result;
                PC_Sel     <= '1';
                PC_En      <= '1';

        end case;
    end process;

end Behavioral;