library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Memory is
    Port(
        Addr      : in  STD_LOGIC_VECTOR(15 downto 0);
        D_in      : in  STD_LOGIC_VECTOR(15 downto 0);
        w_enable  : in  STD_LOGIC;
        clk       : in  STD_LOGIC;
        Q         : out STD_LOGIC_VECTOR(15 downto 0)
    );
end Memory;

architecture Behavioral of Memory is
    -- 2^16 possible addresses yield 65536 combinations
    type memory_array is array (0 to 65535)
        of STD_LOGIC_VECTOR(15 downto 0);

    signal mem : memory_array := (others => (others => '0'));

BEGIN

    -- Write operation
    process(clk)
    begin
        if rising_edge(clk) then
            if w_enable = '1' then
                mem(to_integer(unsigned(Addr))) <= D_in;
            end if;
        end if;
    end process;

    -- Read operation
    Q <= mem(to_integer(unsigned(Addr)));

end Behavioral;
