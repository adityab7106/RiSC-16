library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Program_Counter is
    Port(
        D   : in  STD_LOGIC_VECTOR(15 downto 0);
        En  : in  STD_LOGIC;
        clk : in  STD_LOGIC;
        Q   : out STD_LOGIC_VECTOR(15 downto 0)
    );
end Program_Counter;

architecture Behavioral of Program_Counter is
	signal PC_reg : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

BEGIN

    process(clk)
    begin
        if rising_edge(clk) then
            if En = '1' then
                PC_reg <= D;
            end if;
        end if;
    end process;

    Q <= PC_reg;

end Behavioral;