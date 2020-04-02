--decoder7seg
library ieee;
use ieee.std_logic_1164.all;

entity decoder7seg is
    port (
        input  : in  std_logic_vector(3 downto 0);
        output : out std_logic_vector(6 downto 0));
end decoder7seg;

architecture BHV of decoder7seg is

begin  -- BHV

	process(input)
		begin
		
			case input is
				when "0000" =>  output <= "1000000";--"0000001";
				when "0001" =>  output <= "1111001";--"1001111";
				when "0010" =>  output <= "0100100";--"0010010";
				when "0011" =>  output <= "0110000";--"0000110";
				when "0100" =>  output <= "0011001";--"1001100";
				when "0101" =>  output <= "0010010";--"0100100";
				when "0110" =>  output <= "0000010";--"0100000";
				when "0111" =>  output <= "1111000";--"0001111";
				when "1000" =>  output <= "0000000";--"0000000";
				when "1001" =>  output <= "0011000";--"0001100";
				when "1010" =>  output <= "0001000";--"0001000";
				when "1011" =>  output <= "0000011";--"1100000";
				when "1100" =>  output <= "1000110";--"0110001";
				when "1101" =>  output <= "0100001";--"1000010";
				when "1110" =>  output <= "0000110";--"0110000";
				when "1111" =>  output <= "0001110";--"0111000";
				when others =>  output <= "XXXXXXX";
			end case;
		end process;

end BHV;
