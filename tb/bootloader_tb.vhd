library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Bootloader_tb is
end Bootloader_tb;

architecture sim of Bootloader_tb is

    constant CP           : time    := 10 ns;           -- 100 MHz
    constant TB_BAUD      : integer := 10_000_000;      -- 10 clocks per bit
    constant BIT_TIME     : time    := 100 ns;

    signal clk, reset : STD_LOGIC := '0';
    signal RsRx       : STD_LOGIC := '1';
    signal Boot_Addr, Boot_Data : STD_LOGIC_VECTOR(15 downto 0);
    signal Boot_We, Boot_Done, Boot_Busy : STD_LOGIC;

    signal stop       : boolean := false;
    signal writes     : integer := 0;

begin

    UUT : entity work.Bootloader
        generic map( CLK_FREQ_HZ => 100_000_000,
                     BAUD_RATE   => TB_BAUD,
                     BASE_ADDR   => 0 )
        port map( clk => clk, reset => reset, RsRx => RsRx,
                  Boot_Addr => Boot_Addr, Boot_Data => Boot_Data,
                  Boot_We => Boot_We, Boot_Done => Boot_Done,
                  Boot_Busy => Boot_Busy );

    clk_proc : process begin
        while not stop loop
            clk <= '0'; wait for CP/2; clk <= '1'; wait for CP/2;
        end loop;
        wait;
    end process;

    -- watch the memory write port
    mon : process(clk)
        variable expect_addr : natural := 0;
    begin
        if rising_edge(clk) and Boot_We = '1' then
            report "WRITE addr=" & integer'image(to_integer(unsigned(Boot_Addr))) &
                   "  data=" & integer'image(to_integer(unsigned(Boot_Data)));
            assert to_integer(unsigned(Boot_Addr)) = expect_addr
                report "wrong address" severity failure;
            expect_addr := expect_addr + 1;
            writes <= writes + 1;
        end if;
    end process;

    stim : process

        -- one 8N1 frame, LSB first
        procedure send_byte(b : in STD_LOGIC_VECTOR(7 downto 0)) is
        begin
            RsRx <= '0';                        -- start bit
            wait for BIT_TIME;
            for i in 0 to 7 loop
                RsRx <= b(i);
                wait for BIT_TIME;
            end loop;
            RsRx <= '1';                        -- stop bit
            wait for BIT_TIME;
            wait for BIT_TIME;                  -- a little idle between frames
        end procedure;

        -- one 16-bit word, big-endian, as uploader.py sends it
        procedure send_word(w : in STD_LOGIC_VECTOR(15 downto 0)) is
        begin
            send_byte(w(15 downto 8));
            send_byte(w(7 downto 0));
        end procedure;

    begin
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        send_word(x"0004");     -- header: 4 instruction words follow
        send_word(x"1111");
        send_word(x"2222");
        send_word(x"3333");
        send_word(x"4444");
        send_word(x"DEAD");     -- MUST BE IGNORED

        wait for 2 us;
        assert Boot_Done = '1'
            report "Boot_Done never asserted" severity failure;
        assert writes = 4
            report "expected 4 writes, got " & integer'image(writes) severity failure;
        report "PASS: 4 words loaded at 0-3, extra word ignored, Boot_Done = 1";

        stop <= true;
        wait;
    end process;

end sim;