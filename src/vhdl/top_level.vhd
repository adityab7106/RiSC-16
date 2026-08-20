library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RiSC16_Top is
    Port(
        clk        : in  STD_LOGIC;
        -- debug ports for observing the internal state of the processor
        dbg_PC     : out STD_LOGIC_VECTOR(15 downto 0);
        dbg_IR     : out STD_LOGIC_VECTOR(15 downto 0);
        dbg_Result : out STD_LOGIC_VECTOR(15 downto 0)
    );
end RiSC16_Top;

architecture Structural of RiSC16_Top is

    ---------------------------------------------------------------------------
    -- component declarations
    ---------------------------------------------------------------------------
    component Program_Counter is
        Port( D : in STD_LOGIC_VECTOR(15 downto 0);
              En : in STD_LOGIC;
              clk : in STD_LOGIC;
              Q : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    component Memory is
        Port( Addr : in STD_LOGIC_VECTOR(15 downto 0);
              D_in : in STD_LOGIC_VECTOR(15 downto 0);
              w_enable : in STD_LOGIC;
              clk : in STD_LOGIC;
              Q : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    component Current_Instruction is
        Port( D_in : in STD_LOGIC_VECTOR(15 downto 0);
              En : in STD_LOGIC;
              clk : in STD_LOGIC;
              Q : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    component Register_File is
        Port( Wr_addr : in STD_LOGIC_VECTOR(2 downto 0);
              D_in : in STD_LOGIC_VECTOR(15 downto 0);
              w_enable : in STD_LOGIC;
              Read_A : in STD_LOGIC_VECTOR(2 downto 0);
              Read_B : in STD_LOGIC_VECTOR(2 downto 0);
              Read_C : in STD_LOGIC_VECTOR(2 downto 0);
              clk : in STD_LOGIC;
              Q_A : out STD_LOGIC_VECTOR(15 downto 0);
              Q_B : out STD_LOGIC_VECTOR(15 downto 0);
              Q_C : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    component ALU is
        Port( RegB : in STD_LOGIC_VECTOR(15 downto 0);
              RegC_or_Imm : in STD_LOGIC_VECTOR(15 downto 0);
              Opcode : in STD_LOGIC_VECTOR(2 downto 0);
              Result : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    component Controller is
        Port( Clk : in STD_LOGIC;
              Mem_Output : in STD_LOGIC_VECTOR(15 downto 0);
              IR : in STD_LOGIC_VECTOR(15 downto 0);
              PC_value : in STD_LOGIC_VECTOR(15 downto 0);
              ALU_Result : in STD_LOGIC_VECTOR(15 downto 0);
              Reg_A : in STD_LOGIC_VECTOR(15 downto 0);
              EQ_flag : in STD_LOGIC;
              PC_Sel : out STD_LOGIC;
              PC_En : out STD_LOGIC;
              PC_Write : out STD_LOGIC_VECTOR(15 downto 0);
              Mem_Set_Addr : out STD_LOGIC_VECTOR(15 downto 0);
              Mem_Set_Addr_en : out STD_LOGIC;
              Mem_write : out STD_LOGIC_VECTOR(15 downto 0);
              Mem_write_en : out STD_LOGIC;
              IR_En : out STD_LOGIC;
              Reg_Addr_A : out STD_LOGIC_VECTOR(2 downto 0);
              Reg_Addr_B : out STD_LOGIC_VECTOR(2 downto 0);
              Reg_Addr_C : out STD_LOGIC_VECTOR(2 downto 0);
              Reg_Addr : out STD_LOGIC_VECTOR(2 downto 0);
              Reg_write : out STD_LOGIC_VECTOR(15 downto 0);
              Reg_w_en : out STD_LOGIC;
              Opcode : out STD_LOGIC_VECTOR(2 downto 0);
              Immediate : out STD_LOGIC_VECTOR(15 downto 0);
              Read_Immediate : out STD_LOGIC;
              Read_PC : out STD_LOGIC);
    end component;

    ---------------------------------------------------------------------------
    -- control signals (controller -> datapath)
    ---------------------------------------------------------------------------
    signal c_PC_Sel          : STD_LOGIC;
    signal c_PC_En           : STD_LOGIC;
    signal c_PC_Write        : STD_LOGIC_VECTOR(15 downto 0);
    signal c_Mem_Set_Addr    : STD_LOGIC_VECTOR(15 downto 0);
    signal c_Mem_Set_Addr_en : STD_LOGIC;
    signal c_Mem_write       : STD_LOGIC_VECTOR(15 downto 0);
    signal c_Mem_write_en    : STD_LOGIC;
    signal c_IR_En           : STD_LOGIC;
    signal c_Reg_Addr_A      : STD_LOGIC_VECTOR(2 downto 0);
    signal c_Reg_Addr_B      : STD_LOGIC_VECTOR(2 downto 0);
    signal c_Reg_Addr_C      : STD_LOGIC_VECTOR(2 downto 0);
    signal c_Reg_Addr        : STD_LOGIC_VECTOR(2 downto 0);
    signal c_Reg_write       : STD_LOGIC_VECTOR(15 downto 0);
    signal c_Reg_w_en        : STD_LOGIC;
    signal c_Opcode          : STD_LOGIC_VECTOR(2 downto 0);
    signal c_Immediate       : STD_LOGIC_VECTOR(15 downto 0);
    signal c_Read_Immediate  : STD_LOGIC;
    signal c_Read_PC         : STD_LOGIC;

    ---------------------------------------------------------------------------
    -- datapath signals
    ---------------------------------------------------------------------------
    signal PC_Q       : STD_LOGIC_VECTOR(15 downto 0);
    signal PC_plus1   : STD_LOGIC_VECTOR(15 downto 0);
    signal PC_D       : STD_LOGIC_VECTOR(15 downto 0);

    signal Mem_Addr   : STD_LOGIC_VECTOR(15 downto 0);
    signal Mem_Q      : STD_LOGIC_VECTOR(15 downto 0);

    signal IR_Q       : STD_LOGIC_VECTOR(15 downto 0);

    signal Q_A, Q_B, Q_C : STD_LOGIC_VECTOR(15 downto 0);

    signal ALU_A      : STD_LOGIC_VECTOR(15 downto 0);  -- ALU "RegB" port
    signal ALU_B      : STD_LOGIC_VECTOR(15 downto 0);  -- ALU "RegC_or_Imm" port
    signal ALU_Out    : STD_LOGIC_VECTOR(15 downto 0);

    signal EQ         : STD_LOGIC;

begin

    ---------------------------------------------------------------------------
    -- incrementer: PC_value is PC+1 (link value for JALR, branch base for BEQ)
    ---------------------------------------------------------------------------
    PC_plus1 <= STD_LOGIC_VECTOR(unsigned(PC_Q) + 1);

    ---------------------------------------------------------------------------
    -- mux 1: next PC.  0 = sequential, 1 = branch/jump target
    ---------------------------------------------------------------------------
    PC_D <= c_PC_Write when c_PC_Sel = '1' else PC_plus1;

    ---------------------------------------------------------------------------
    -- mux 2: memory address.  0 = instruction fetch from PC, 1 = LW/SW address
    ---------------------------------------------------------------------------
    Mem_Addr <= c_Mem_Set_Addr when c_Mem_Set_Addr_en = '1' else PC_Q;

    ---------------------------------------------------------------------------
    -- mux 3: ALU second operand.  0 = Q_C (RRR), 1 = immediate (RRI/RI)
    ---------------------------------------------------------------------------
    ALU_B <= c_Immediate when c_Read_Immediate = '1' else Q_C;

    ---------------------------------------------------------------------------
    -- mux 4: ALU first operand.  0 = Q_B, 1 = PC+1 (BEQ target = PC+1+imm)
    ---------------------------------------------------------------------------
    ALU_A <= PC_plus1 when c_Read_PC = '1' else Q_B;

    ---------------------------------------------------------------------------
    -- comparator
    ---------------------------------------------------------------------------
    EQ <= '1' when Q_A = Q_B else '0';

    ---------------------------------------------------------------------------
    -- component instantiations
    ---------------------------------------------------------------------------
    U_PC : Program_Counter
        port map( D => PC_D, En => c_PC_En, clk => clk, Q => PC_Q );

    U_MEM : Memory
        port map( Addr     => Mem_Addr,
                  D_in     => c_Mem_write,
                  w_enable => c_Mem_write_en,
                  clk      => clk,
                  Q        => Mem_Q );

    U_IR : Current_Instruction
        port map( D_in => Mem_Q, En => c_IR_En, clk => clk, Q => IR_Q );

    U_RF : Register_File
        port map( Wr_addr  => c_Reg_Addr,
                  D_in     => c_Reg_write,
                  w_enable => c_Reg_w_en,
                  Read_A   => c_Reg_Addr_A,
                  Read_B   => c_Reg_Addr_B,
                  Read_C   => c_Reg_Addr_C,
                  clk      => clk,
                  Q_A      => Q_A,
                  Q_B      => Q_B,
                  Q_C      => Q_C );

    U_ALU : ALU
        port map( RegB        => ALU_A,
                  RegC_or_Imm => ALU_B,
                  Opcode      => c_Opcode,
                  Result      => ALU_Out );

    U_CTRL : Controller
        port map( Clk             => clk,
                  Mem_Output      => Mem_Q,
                  IR              => IR_Q,
                  PC_value        => PC_plus1,
                  ALU_Result      => ALU_Out,
                  Reg_A           => Q_A,
                  EQ_flag         => EQ,
                  PC_Sel          => c_PC_Sel,
                  PC_En           => c_PC_En,
                  PC_Write        => c_PC_Write,
                  Mem_Set_Addr    => c_Mem_Set_Addr,
                  Mem_Set_Addr_en => c_Mem_Set_Addr_en,
                  Mem_write       => c_Mem_write,
                  Mem_write_en    => c_Mem_write_en,
                  IR_En           => c_IR_En,
                  Reg_Addr_A      => c_Reg_Addr_A,
                  Reg_Addr_B      => c_Reg_Addr_B,
                  Reg_Addr_C      => c_Reg_Addr_C,
                  Reg_Addr        => c_Reg_Addr,
                  Reg_write       => c_Reg_write,
                  Reg_w_en        => c_Reg_w_en,
                  Opcode          => c_Opcode,
                  Immediate       => c_Immediate,
                  Read_Immediate  => c_Read_Immediate,
                  Read_PC         => c_Read_PC );

    dbg_PC     <= PC_Q;
    dbg_IR     <= IR_Q;
    dbg_Result <= ALU_Out;

end Structural;