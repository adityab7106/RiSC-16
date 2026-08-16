-- libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- entity declaration to define ports
entity ALU is
	Port(
        RegB       : in  STD_LOGIC_VECTOR(15 downto 0);
        RegC_or_Imm: in  STD_LOGIC_VECTOR(15 downto 0);
        Opcode     : in  STD_LOGIC_VECTOR(2 downto 0);
        Result     : out STD_LOGIC_VECTOR(15 downto 0)
    );
end ALU;

Architecture Behavioral of ALU is

BEGIN
	-- performs operations based on the opcode
	process(RegB, RegC_or_Imm, Opcode) begin
    	
        case Opcode is
        	when "000" =>
            	Result <= STD_LOGIC_VECTOR(unsigned(RegB) + unsigned(RegC_or_Imm));
            when "001" =>
            	Result <= STD_LOGIC_VECTOR(unsigned(RegB) + unsigned(RegC_or_Imm));
            when "010" =>
            	Result <= RegB nand RegC_or_Imm;
            when "011" =>
            	Result <= RegC_or_Imm(9 downto 0) & "000000";
            when "100" =>
            	Result <= STD_LOGIC_VECTOR(unsigned(RegB) + unsigned(RegC_or_Imm));
            when "101" =>
            	Result <= STD_LOGIC_VECTOR(unsigned(RegB) + unsigned(RegC_or_Imm));
            when "110" =>
            	Result <= STD_LOGIC_VECTOR(unsigned(RegB) + unsigned(RegC_or_Imm));
            when others =>
            	Result <= "0000000000000000";
        end case;
    end process;
end Behavioral;
     