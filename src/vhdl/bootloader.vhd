-- Everything from the bootloader RTL diagram lives in this one file:
--   * UART Receiver   -- 8N1 receiver + byte pair assembler
--   * Payload TC      -- holds the word count sent in the first packet
--   * Payload Counter -- current write address
--   * Controller      -- Moore FSM: Idle -> Get_Size -> Arm -> (Write <-> Wait) -> Done
--
-- Protocol:
--   bytes 0,1     : N, the number of 16-bit instruction words that follow
--   bytes 2..2N+1 : the program
--   Every 16-bit word is sent big-endian, each byte goes out as one 8N1 UART frame at BAUD_RATE. 
--    Words land in memory at BASE_ADDR .. BASE_ADDR+N-1.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Bootloader is
    Generic(
        CLK_FREQ_HZ : integer := 100_000_000;   -- Basys-3 system clock
        BAUD_RATE   : integer := 115_200;       -- must match uploader.py
        BASE_ADDR   : integer := 0              -- first memory address the payload lands on
    );
    Port(
        clk       : in  STD_LOGIC;      -- 100 MHz system clock
        reset     : in  STD_LOGIC;      -- synchronous, active high (tie to '0' if unused)

        -- USB-UART bridge (asynchronous to clk)
        RsRx      : in  STD_LOGIC;      -- idles high

        -- memory write port: mux these into the BRAM while Boot_Done = '0'
        Boot_Addr : out STD_LOGIC_VECTOR(15 downto 0);
        Boot_Data : out STD_LOGIC_VECTOR(15 downto 0);
        Boot_We   : out STD_LOGIC;

        -- handshake to the rest of the machine
        Boot_Done : out STD_LOGIC;      -- '1' once the whole payload is in memory
        Boot_Busy : out STD_LOGIC       -- '1' while a load is in progress (LED/debug)
    );
end Bootloader;

architecture Behavioral of Bootloader is

    ---------------------------------------------------------------------------
    -- UART bit timing
    ---------------------------------------------------------------------------
    constant CLKS_PER_BIT : integer := CLK_FREQ_HZ / BAUD_RATE;   -- 868 @ 100M/115200
    constant HALF_BIT     : integer := CLKS_PER_BIT / 2;

    ---------------------------------------------------------------------------
    -- UART Receiver
    ---------------------------------------------------------------------------
    signal rx_sync    : STD_LOGIC_VECTOR(1 downto 0) := (others => '1');
    signal rx_bit     : STD_LOGIC;      -- synchronized line level

    type rx_state_type is (ST_IDLE, ST_START, ST_BITS, ST_STOP);
    signal rx_state   : rx_state_type := ST_IDLE;

    signal clk_count  : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal bit_index  : integer range 0 to 7 := 0;
    signal byte_reg   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal rx_byte    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal byte_valid : STD_LOGIC := '0';   -- one-clock pulse per good frame

    -- byte pair assembler: two 8N1 frames make one 16-bit word, high byte first
    signal byte_phase : STD_LOGIC := '0';   -- '0' = expecting high byte
    signal high_byte  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal rx_data    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

    -- "Packet_Ready" -- a clean one-clock pulse in the clk domain, so the
    -- controller never has to edge-detect a level that lasts many cycles
    signal word_valid : STD_LOGIC := '0';

    ---------------------------------------------------------------------------
    -- Payload TC / Payload Counter
    ---------------------------------------------------------------------------
    signal payload_tc : unsigned(15 downto 0) := (others => '0');
    signal payload_ct : unsigned(15 downto 0) := (others => '0');
    signal count_done : STD_LOGIC;      -- the "=" comparator

    ---------------------------------------------------------------------------
    -- Controller
    ---------------------------------------------------------------------------
    type state_type is (S_IDLE, S_GET_SIZE, S_ARM, S_WRITE, S_WAIT, S_DONE);
    signal state      : state_type := S_IDLE;
    signal next_state : state_type;

    signal tc_en      : STD_LOGIC;
    signal count_en   : STD_LOGIC;
    signal count_clr  : STD_LOGIC;
    signal w_en       : STD_LOGIC;
    signal done_flag  : STD_LOGIC;

begin

    ---------------------------------------------------------------------------
    -- input synchronizer.  bit 0 is the fresh sample and is the one allowed to
    -- go metastable; bit 1 is the clean value the receiver uses.
    ---------------------------------------------------------------------------
    SYNC : process(clk)
    begin
        if rising_edge(clk) then
            rx_sync <= rx_sync(0) & RsRx;
        end if;
    end process;

    rx_bit <= rx_sync(1);

    ---------------------------------------------------------------------------
    -- UART receiver, 8N1, LSB first.
    -- ST_START re-checks the line at the midpoint of the start bit so a glitch
    -- cannot fake a frame; each data bit is then sampled a full bit later,
    -- keeping every sample in the middle of its bit.  A frame whose stop bit is
    -- not high is discarded.
    ---------------------------------------------------------------------------
    UART_RX : process(clk)
    begin
        if rising_edge(clk) then
            byte_valid <= '0';          -- default: the pulse is one clock wide

            if reset = '1' then
                rx_state  <= ST_IDLE;
                clk_count <= 0;
                bit_index <= 0;
                byte_reg  <= (others => '0');
                rx_byte   <= (others => '0');

            else
                case rx_state is

                    when ST_IDLE =>
                        clk_count <= 0;
                        bit_index <= 0;
                        if rx_bit = '0' then        -- start bit edge
                            rx_state <= ST_START;
                        end if;

                    when ST_START =>
                        if clk_count = HALF_BIT then
                            if rx_bit = '0' then    -- still low: a real start bit
                                clk_count <= 0;
                                rx_state  <= ST_BITS;
                            else
                                rx_state  <= ST_IDLE;
                            end if;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                    when ST_BITS =>
                        if clk_count = CLKS_PER_BIT - 1 then
                            clk_count <= 0;
                            byte_reg  <= rx_bit & byte_reg(7 downto 1);  -- LSB first
                            if bit_index = 7 then
                                bit_index <= 0;
                                rx_state  <= ST_STOP;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                    when ST_STOP =>
                        if clk_count = CLKS_PER_BIT - 1 then
                            clk_count <= 0;
                            if rx_bit = '1' then    -- good framing, keep the byte
                                rx_byte    <= byte_reg;
                                byte_valid <= '1';
                            end if;
                            rx_state <= ST_IDLE;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- byte pair assembler: high byte then low byte makes one 16-bit word
    ---------------------------------------------------------------------------
    BYTE_PAIR : process(clk)
    begin
        if rising_edge(clk) then
            word_valid <= '0';          -- default: the pulse is one clock wide

            if reset = '1' then
                byte_phase <= '0';
                high_byte  <= (others => '0');
                rx_data    <= (others => '0');

            elsif byte_valid = '1' then
                if byte_phase = '0' then
                    high_byte  <= rx_byte;
                    byte_phase <= '1';
                else
                    rx_data    <= high_byte & rx_byte;
                    word_valid <= '1';
                    byte_phase <= '0';
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Payload TC: latches the size word
    ---------------------------------------------------------------------------
    TC_REG : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                payload_tc <= (others => '0');
            elsif tc_en = '1' then
                payload_tc <= unsigned(rx_data);
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Payload Counter: write address, and the count compared against TC
    ---------------------------------------------------------------------------
    COUNT_REG : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' or count_clr = '1' then
                payload_ct <= (others => '0');
            elsif count_en = '1' then
                payload_ct <= payload_ct + 1;
            end if;
        end if;
    end process;

    count_done <= '1' when payload_ct = payload_tc else '0';

    ---------------------------------------------------------------------------
    -- state register
    ---------------------------------------------------------------------------
    STATE_REG : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= S_IDLE;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- next state logic
    ---------------------------------------------------------------------------
    NEXT_STATE_LOGIC : process(state, word_valid, count_done)
    begin
        next_state <= state;

        case state is

            -- wait for the first word: the payload size
            when S_IDLE =>
                if word_valid = '1' then
                    next_state <= S_GET_SIZE;
                end if;

            -- one clock with TC_en asserted; rx_data still holds the size word
            when S_GET_SIZE =>
                next_state <= S_ARM;

            -- counter cleared, waiting on the first data word
            -- (a size of zero means there is nothing to load)
            when S_ARM =>
                if count_done = '1' then
                    next_state <= S_DONE;
                elsif word_valid = '1' then
                    next_state <= S_WRITE;
                end if;

            -- one clock of w_enable; the counter advances on the way out
            when S_WRITE =>
                next_state <= S_WAIT;

            -- payload finished, or wait for the next word
            when S_WAIT =>
                if count_done = '1' then
                    next_state <= S_DONE;
                elsif word_valid = '1' then
                    next_state <= S_WRITE;
                end if;

            -- memory belongs to the CPU from here on; only reset leaves
            when S_DONE =>
                next_state <= S_DONE;

        end case;
    end process;

    ---------------------------------------------------------------------------
    -- Moore output logic
    ---------------------------------------------------------------------------
    OUTPUT_LOGIC : process(state)
    begin
        tc_en     <= '0';
        count_en  <= '0';
        count_clr <= '0';
        w_en      <= '0';
        done_flag <= '0';

        case state is
            when S_GET_SIZE => tc_en     <= '1';
            when S_ARM      => count_clr <= '1';
            when S_WRITE    => w_en      <= '1';
                               count_en  <= '1';
            when S_DONE     => done_flag <= '1';
            when others     => null;
        end case;
    end process;

    ---------------------------------------------------------------------------
    -- outputs
    ---------------------------------------------------------------------------
    Boot_Addr <= STD_LOGIC_VECTOR(payload_ct + to_unsigned(BASE_ADDR, 16));
    Boot_Data <= rx_data;
    Boot_We   <= w_en;
    Boot_Done <= done_flag;
    Boot_Busy <= '1' when (state /= S_IDLE and state /= S_DONE) else '0';

end Behavioral;