library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Current_Instruction is
    Port (
        D_in : in  STD_LOGIC_VECTOR(15 downto 0);
        En   : in  STD_LOGIC;
        clk  : in  STD_LOGIC;
        Q    : out STD_LOGIC_VECTOR(15 downto 0)
    );
end Current_Instruction;

architecture Behavioral of Current_Instruction is

    signal IR_reg : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if En = '1' then
                IR_reg <= D_in;
            end if;
        end if;
    end process;

    Q <= IR_reg;

end Behavioral;
