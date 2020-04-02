--clock_div_tb
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div_tb is
end clock_div_tb;


architecture TB of clock_div_tb is


-----------------------------------
--signals
-----------------------------------
signal clk50MHz	:	std_logic := '0';
signal sclk	:	std_logic;
signal rst	:	std_logic;
signal enable 	:	std_logic;
signal bytes 	:	std_logic_vector (3 downto 0);
signal polarity 	:	std_logic;
signal clk_active	:	std_logic;
signal byte_flag 	:	std_logic;

begin

-----------------------------------
--units under test
-----------------------------------
	U_CLOCK_DIV : entity work.clock_div
		generic map(
			clk_in_freq => 50000000,
			clk_out_freq => 1000)
		port map(
			clk_in => clk50MHz,
			clk_out => sclk,
			rst	=> rst,
			enable => enable,
			bytes	=> bytes,
			polarity => polarity,
			clk_active => clk_active,
			byte_flag => byte_flag);

clk50MHz <= not clk50MHz after 10 ns;  --50MHz



process

begin
	--reset
	rst <= '1';
	enable <='0';
	bytes <= "0100";
	polarity <= '1';
	wait for 1 ms;
	
	--go
	rst <= '0';
	wait for 1 ms;
	
	enable <= '1';
	wait for 4 ms;
	
	wait until clk_active = '0';
	enable <= '0';
	
	
	wait for 4 ms;
	enable <= '1';
	polarity <= '0';
	wait for 4 ms;
	
	wait until clk_active = '0';
	enable <= '0';
	
	
	
	wait for 1 ms;
	
	
			for i in 0 to 900000000 loop
				wait until clk50MHz'event and clk50MHz = '1';
				
			end loop;
	
	




end process;


end TB;