library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Register_File is
    Port(
        Wr_addr  : in  STD_LOGIC_VECTOR(2 downto 0);
        D_in     : in  STD_LOGIC_VECTOR(15 downto 0);
        w_enable : in  STD_LOGIC;

        Read_A   : in  STD_LOGIC_VECTOR(2 downto 0);
        Read_B   : in  STD_LOGIC_VECTOR(2 downto 0);
        Read_C   : in  STD_LOGIC_VECTOR(2 downto 0);

        clk      : in  STD_LOGIC;

        Q_A      : out STD_LOGIC_VECTOR(15 downto 0);
        Q_B      : out STD_LOGIC_VECTOR(15 downto 0);
        Q_C      : out STD_LOGIC_VECTOR(15 downto 0)
    );
end Register_File;

architecture Behavioral of Register_File is

    type register_array is array (0 to 7)
        of STD_LOGIC_VECTOR(15 downto 0);

    signal registers : register_array := (others => (others => '0'));

begin

    -- Write port
    process(clk)
    begin
        if rising_edge(clk) then
            if w_enable = '1' then
                registers(to_integer(unsigned(Wr_addr))) <= D_in;
            end if;
        end if;
    end process;

    -- Three asynchronous read ports
    Q_A <= registers(to_integer(unsigned(Read_A)));
    Q_B <= registers(to_integer(unsigned(Read_B)));
    Q_C <= registers(to_integer(unsigned(Read_C)));

end Behavioral;
