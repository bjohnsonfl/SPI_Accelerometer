--top_level_tb
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_tb is
end top_level_tb;

architecture TB of top_level_tb is

-----------------------------------
--signals
-----------------------------------
	signal clk50MHz	:	std_logic := '0';
	signal rst			:	std_logic := '1';
	signal mosi			:	std_logic;
	signal miso			:	std_logic := '0';
	signal sclk			:	std_logic;
	signal cs			:	std_logic;
--	signal pol			:	std_logic;
--	signal pha			:	std_logic;
	signal int1 		:  std_logic := '0';
	signal led0			:	std_logic_vector (6 downto 0);
	signal led0_dp		:	std_logic;
	signal led1			:	std_logic_vector (6 downto 0);
	signal led1_dp		:	std_logic;
	signal led2			:	std_logic_vector (6 downto 0);
	signal led2_dp		:	std_logic;
	signal led3			:	std_logic_vector (6 downto 0);
	signal led3_dp		:	std_logic;
	signal led4			:	std_logic_vector (6 downto 0);
	signal led4_dp		:	std_logic;
	signal led5			:	std_logic_vector (6 downto 0);
	signal led5_dp		:	std_logic;
	signal rst_led 	:  std_logic;
--	signal led_int1	:  std_logic;
--	signal led_int2	:  std_logic;
	
	
	signal misoData :std_logic_vector(7 downto 0) := "11100101";--"11001110";
	signal bit : integer range -1 to 8 := 7;
	signal sentData : std_logic_vector (7 downto 0) := "00000000";
	
	signal mosi_test	:  std_logic;
	signal sclk_test	:  std_logic;
	signal cs_test 		:  std_logic;
	signal intBypass  : std_logic := '0';
	
begin

-----------------------------------
--units under test
-----------------------------------

U_TOP_LEVEL : entity work.top_level
	port map(
		clk50MHz 	=>		clk50MHz,
		rst 			=>		rst,		
		mosi			=>		mosi,
		miso 			=>		miso,
		sclk 			=>		sclk,
		cs 			=>		cs,
		int1			=> 	int1,
		mosi_test	=>		mosi_test,
		sclk_test	=>		sclk_test,
		cs_test 		=>		cs_test,
		intBypass  =>     intBypass,
		led0     	=> 	led0,
      led0_dp  	=> 	led0_dp,
		led1     	=> 	led1,
      led1_dp  	=>		led1_dp,
		led2     	=> 	led2,
      led2_dp  	=> 	led2_dp,
		led3     	=> 	led3,
      led3_dp  	=>		led3_dp,
		led4     	=> 	led4,
      led4_dp  	=> 	led4_dp,
		led5     	=> 	led5,
      led5_dp  	=>		led5_dp
	);

	
	
	clk50MHz <= not clk50MHz after 10 ns;
	
	rst_led <= not rst;
	
	process
	begin
		rst <= '1';
		
		
		
		wait for 1 ms;
		wait until clk50MHz'event and clk50MHz = '1';
		
		rst <= '0';
		
		
		
--		wait until cs'event and cs = '0';  --reg 1
--			--misoData <= "";
--		wait until cs'event and cs = '0';   -- reg 2
--		--	misoData <= "";
--		wait until cs'event and cs = '0';   -- reg 3
		--	misoData <= "";
		
--		wait until cs'event and cs = '0';  --reg 1  read
--			misoData <= "00001010";
--		wait until cs'event and cs = '0';   -- reg 2  read 
--			misoData <= "00000110";
--		wait until cs'event and cs = '0';   -- reg 3  read
--			misoData <= "00001000";
		
		
		
		for i in 0 to 50 loop
			wait for 20 us;
			int1 <= '1';
			wait until cs'event and cs = '0';
			int1 <= '0';
		end loop;
	
		
		
		wait for 3 ms;
			rst <= '1';
			
			wait for 1 ms;
		wait until clk50MHz'event and clk50MHz = '1';
		
		rst <= '0';
		
		for i in 0 to 500 loop
			wait for 20 us;
			int1 <= '1';
			wait until cs'event and cs = '0';
			int1 <= '0';
		end loop;
		
		
		for i in 0 to 900000000 loop
			wait until clk50MHz'event and clk50MHz = '1';
				
		end loop;
	
	
	
	
	
	end process;
	
	
	
	
	process (sclk, rst)											-- simulation of miso data, clocked only on sclk

	begin

	if(rst = '1') then
		bit <= 7;
	end if;

	if(sclk'event and sclk = '0' and cs = '0') then
		miso <= misoData(bit);									-- misoData is updated in test process above
		bit <= bit - 1;
		
		if(bit = 0) then
			bit <= 7;
		end if;
	end if;
	
	if(sclk'event and sclk = '1' and cs = '0') then
			sentData <= sentData(6 downto 0) & mosi;
	end if;



	end process;

	
	

end TB;