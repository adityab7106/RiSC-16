----------------------------------------------------------------------------------
-- top_level_tb.vhd
--
-- End-to-end check: feed a real UART byte stream into RsRx, wait for the
-- bootloader to hand memory over, then confirm the CPU fetches from address 0
-- and executes the uploaded program.
--
-- Program uploaded:
--   ADDI r7, r0, 5   -> 0x3C05
--   ADDI r7, r7, 3   -> 0x3F83
-- so register 7 (the seven-seg tap) should end up holding 8.
--
-- Needs a simulation stub for the Block Memory Generator IP -- see
-- memory_stub.vhd.  Do NOT add that stub to the synthesis fileset.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top_Level_tb is
end Top_Level_tb;

architecture sim of Top_Level_tb is

    constant CP       : time := 10 ns;        -- 100 MHz
    constant BIT_TIME : time := 8680 ns;      -- 115200 baud

    signal clk      : STD_LOGIC := '0';
    signal reset    : STD_LOGIC := '0';
    signal RsRx     : STD_LOGIC := '1';
    signal seg_port : STD_LOGIC_VECTOR(0 to 6);
    signal an_port  : STD_LOGIC_VECTOR(3 downto 0);

    signal stop : boolean := false;

begin

    UUT : entity work.RiSC16_Top
        port map( clk => clk, reset => reset, RsRx => RsRx,
                  seg_port => seg_port, an_port => an_port );

    clk_proc : process begin
        while not stop loop
            clk <= '0'; wait for CP/2; clk <= '1'; wait for CP/2;
        end loop;
        wait;
    end process;

    stim : process

        procedure send_byte(b : in STD_LOGIC_VECTOR(7 downto 0)) is
        begin
            RsRx <= '0';
            wait for BIT_TIME;
            for i in 0 to 7 loop
                RsRx <= b(i);
                wait for BIT_TIME;
            end loop;
            RsRx <= '1';
            wait for 2 * BIT_TIME;
        end procedure;

        procedure send_word(w : in STD_LOGIC_VECTOR(15 downto 0)) is
        begin
            send_byte(w(15 downto 8));
            send_byte(w(7 downto 0));
        end procedure;

    begin
        reset <= '1';
        wait for 200 ns;
        reset <= '0';
        wait for 200 ns;

        send_word(x"0002");     -- two instructions follow
        send_word(x"3C05");     -- ADDI r7, r0, 5
        send_word(x"3F83");     -- ADDI r7, r7, 3

        -- give the CPU time to fetch and run both instructions
        wait for 20 us;

        report "upload complete; check R7 = 8 and the PC advancing in the waveform";
        stop <= true;
        wait;
    end process;

end sim;