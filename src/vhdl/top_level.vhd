library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RiSC16_Top is
    Port(
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;                      -- btnC, active high
        RsRx     : in  STD_LOGIC;                      -- USB-UART receive line
        seg_port : out STD_LOGIC_VECTOR(0 to 6);
        an_port  : out STD_LOGIC_VECTOR(3 downto 0)
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

    component memory is
        Port( clka  : in  STD_LOGIC;
              wea   : in  STD_LOGIC_VECTOR(0 downto 0);
              addra : in  STD_LOGIC_VECTOR(15 downto 0);
              dina  : in  STD_LOGIC_VECTOR(15 downto 0);
              douta : out STD_LOGIC_VECTOR(15 downto 0));
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
              Q_C : out STD_LOGIC_VECTOR(15 downto 0);
              Q_R7 : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    component ALU is
        Port( RegB : in STD_LOGIC_VECTOR(15 downto 0);
              RegC_or_Imm : in STD_LOGIC_VECTOR(15 downto 0);
              Opcode : in STD_LOGIC_VECTOR(2 downto 0);
              Result : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    -- Start is new: the controller sits in FETCH until it goes high
    component Controller is
        Port( Clk : in STD_LOGIC;
              Start : in STD_LOGIC;
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

    component Bootloader is
        Generic( CLK_FREQ_HZ : natural := 100_000_000;
                 BAUD_RATE   : natural := 115_200;
                 BASE_ADDR   : natural := 0 );
        Port( clk : in STD_LOGIC;
              reset : in STD_LOGIC;
              RsRx : in STD_LOGIC;
              Boot_Addr : out STD_LOGIC_VECTOR(15 downto 0);
              Boot_Data : out STD_LOGIC_VECTOR(15 downto 0);
              Boot_We : out STD_LOGIC;
              Boot_Done : out STD_LOGIC;
              Boot_Busy : out STD_LOGIC);
    end component;

    component seven_seg_mux is
        Port( clk      : in  STD_LOGIC;
              value    : in  STD_LOGIC_VECTOR(15 downto 0);
              seg_port : out STD_LOGIC_VECTOR(0 to 6);
              an_port  : out STD_LOGIC_VECTOR(3 downto 0));
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
    -- bootloader signals
    ---------------------------------------------------------------------------
    signal b_Addr  : STD_LOGIC_VECTOR(15 downto 0);
    signal b_Data  : STD_LOGIC_VECTOR(15 downto 0);
    signal b_We    : STD_LOGIC;
    signal b_Done  : STD_LOGIC;
    signal b_Busy  : STD_LOGIC;

    ---------------------------------------------------------------------------
    -- datapath signals
    ---------------------------------------------------------------------------
    signal PC_Q       : STD_LOGIC_VECTOR(15 downto 0);
    signal PC_plus1   : STD_LOGIC_VECTOR(15 downto 0);
    signal PC_D       : STD_LOGIC_VECTOR(15 downto 0);
    signal PC_En_i    : STD_LOGIC;

    signal CPU_Addr   : STD_LOGIC_VECTOR(15 downto 0);  -- CPU side of the mux
    signal Mem_Addr   : STD_LOGIC_VECTOR(15 downto 0);  -- what the BRAM sees
    signal Mem_Din    : STD_LOGIC_VECTOR(15 downto 0);
    signal Mem_We     : STD_LOGIC;
    signal Mem_Q      : STD_LOGIC_VECTOR(15 downto 0);
    signal Mem_WEA    : STD_LOGIC_VECTOR(0 downto 0);   -- IP wea is a 1-bit vector

    signal IR_En_i    : STD_LOGIC;
    signal IR_Q       : STD_LOGIC_VECTOR(15 downto 0);

    signal Reg_w_en_i : STD_LOGIC;
    signal Q_A, Q_B, Q_C : STD_LOGIC_VECTOR(15 downto 0);
    signal R7         : STD_LOGIC_VECTOR(15 downto 0);  -- display tap

    signal ALU_A      : STD_LOGIC_VECTOR(15 downto 0);  -- ALU "RegB" port
    signal ALU_B      : STD_LOGIC_VECTOR(15 downto 0);  -- ALU "RegC_or_Imm" port
    signal ALU_Out    : STD_LOGIC_VECTOR(15 downto 0);

    signal EQ         : STD_LOGIC;

    signal disp_value : STD_LOGIC_VECTOR(15 downto 0);

begin

    ---------------------------------------------------------------------------
    -- incrementer: PC_value is PC+1 (link value for JALR, branch base for BEQ)
    ---------------------------------------------------------------------------
    PC_plus1 <= STD_LOGIC_VECTOR(unsigned(PC_Q) + 1);

    ---------------------------------------------------------------------------
    -- mux 1: next PC.  0 = sequential, 1 = branch/jump target.
    -- during the load the PC is force-fed zero every clock, so it is sitting at
    -- address 0 the instant Boot_Done goes high -- no reset port needed on the
    -- PC register itself.
    ---------------------------------------------------------------------------
    PC_D <= (others => '0') when b_Done = '0' else
            c_PC_Write      when c_PC_Sel = '1' else
            PC_plus1;

    PC_En_i <= '1' when b_Done = '0' else c_PC_En;

    ---------------------------------------------------------------------------
    -- mux 2: CPU memory address.  0 = instruction fetch from PC, 1 = LW/SW
    ---------------------------------------------------------------------------
    CPU_Addr <= c_Mem_Set_Addr when c_Mem_Set_Addr_en = '1' else PC_Q;

    ---------------------------------------------------------------------------
    -- BOOT MUX: the bootloader owns the memory port until Boot_Done goes high,
    -- then the CPU does.  Address, write data and write enable all switch
    -- together, so there is never a cycle where half the port belongs to each.
    ---------------------------------------------------------------------------
    Mem_Addr <= CPU_Addr      when b_Done = '1' else b_Addr;
    Mem_Din  <= c_Mem_write   when b_Done = '1' else b_Data;
    Mem_We   <= c_Mem_write_en when b_Done = '1' else b_We;

    Mem_WEA(0) <= Mem_We;

    ---------------------------------------------------------------------------
    -- CPU write enables, gated on Boot_Done.  The controller is already held in
    -- FETCH (which asserts nothing) while Start = '0'
    ---------------------------------------------------------------------------
    IR_En_i    <= c_IR_En    and b_Done;
    Reg_w_en_i <= c_Reg_w_en and b_Done;

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
    -- display: word count while loading, register 7 once running
    ---------------------------------------------------------------------------
    disp_value <= R7 when b_Done = '1' else b_Addr;

    ---------------------------------------------------------------------------
    -- component instantiations
    ---------------------------------------------------------------------------
    U_BOOT : Bootloader
        generic map( CLK_FREQ_HZ => 100_000_000,
                     BAUD_RATE   => 115_200,
                     BASE_ADDR   => 0 )
        port map( clk       => clk,
                  reset     => reset,
                  RsRx      => RsRx,
                  Boot_Addr => b_Addr,
                  Boot_Data => b_Data,
                  Boot_We   => b_We,
                  Boot_Done => b_Done,
                  Boot_Busy => b_Busy );

    U_PC : Program_Counter
        port map( D => PC_D, En => PC_En_i, clk => clk, Q => PC_Q );

    U_MEM : memory
        port map( clka  => clk,
                  wea   => Mem_WEA,
                  addra => Mem_Addr,
                  dina  => Mem_Din,
                  douta => Mem_Q );

    U_IR : Current_Instruction
        port map( D_in => Mem_Q, En => IR_En_i, clk => clk, Q => IR_Q );

    U_RF : Register_File
        port map( Wr_addr  => c_Reg_Addr,
                  D_in     => c_Reg_write,
                  w_enable => Reg_w_en_i,
                  Read_A   => c_Reg_Addr_A,
                  Read_B   => c_Reg_Addr_B,
                  Read_C   => c_Reg_Addr_C,
                  clk      => clk,
                  Q_A      => Q_A,
                  Q_B      => Q_B,
                  Q_C      => Q_C,
                  Q_R7     => R7 );

    U_ALU : ALU
        port map( RegB        => ALU_A,
                  RegC_or_Imm => ALU_B,
                  Opcode      => c_Opcode,
                  Result      => ALU_Out );

    U_CTRL : Controller
        port map( Clk             => clk,
                  Start           => b_Done,
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

    U_DISP : seven_seg_mux
        port map( clk      => clk,
                  value    => disp_value,
                  seg_port => seg_port,
                  an_port  => an_port );

end Structural;