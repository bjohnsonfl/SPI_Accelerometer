--top_level.vhd
library ieee;
use ieee.std_logic_1164.all;

entity top_level is
	port(
		clk50MHz : in std_logic;
		rst 		: in std_logic;
		mosi		: out std_logic;
		miso 		: in std_logic;
		sclk 		: out std_logic;
		cs 		: out std_logic;
		
		mosi_test: out std_logic;
		sclk_test: out std_logic;
		cs_test 	: out std_logic;
		miso_test : out std_logic;
	
--		int1 		: in std_logic;
--		int2 		: in std_logic;
--		
--		pol		: in std_logic;
--		pha		: in std_logic;
--		bytes		: in std_logic_vector (1 downto 0);
		
		
		led0     : out std_logic_vector(6 downto 0);
      led0_dp  : out std_logic;
		led1     : out std_logic_vector(6 downto 0);
      led1_dp  : out std_logic;
		
		rst_led  : out std_logic
	
	);
	
end top_level;


architecture STR of top_level is

	
	signal go : std_logic;
	signal pol : std_logic;
	signal pha : std_logic;
	signal bytes : std_logic_vector (3 downto 0);
	signal rxData : std_logic_vector (7 downto 0);
	signal rxDataReady	: std_logic := '0';
	signal txData 		:		 std_logic_vector (7 downto 0);
	signal accel_data	:		 std_logic_vector (47 downto 0);-- := (others => '0');
	
	signal sclk_out : std_logic;
	
	signal sclk_buffer	:	std_logic;
	signal mosi_buffer	:	std_logic;
	signal cs_buffer	:	std_logic;
	signal miso_buffer : std_logic;

--	type state_type is (S_1, S_2, S_3);
--	signal state : state_type;
--	signal count : integer range 0 to 100000000;
begin

	------------------------------------
	--SPI MASTER
	------------------------------------
	U_SPI_MASTER	:	entity work.spi_master(FSM_1P)
		port map(
		clk	=> clk50MHz,
		rst	=> rst,
      mosi	=> mosi_buffer,
		miso 	=> miso,
		--sclk_out => sclk_buffer,
		sclk_out => sclk_out,
		cs_out	=> cs_buffer,
		int1 	=> '0',
		int2 	=> '0',
		go		=> go,
		pol	=> pol,
		pha   => pha,
		bytes => bytes,
		rxData	=> rxData,
		txData	=> txData,
		rxDataReady	=> rxDataReady
	);
	
	miso_test <= miso;
	mosi <= mosi_buffer;
	cs <= cs_buffer;
	sclk <= sclk_buffer;
	mosi_test <= mosi_buffer;
	sclk_test <= sclk_buffer;
	cs_test 	 <= cs_buffer;
	
	rst_led <= not rst;
	
	U_ACCEL_DRIVER : entity work.accel_driver(FSM_1P)
		port map(
			rst			=> rst,
			clk			=> clk50MHz,
			rxDataReady	=> rxDataReady,
			go				=> go,
			pol			=> pol,
			pha			=> pha,
			bytes 		=> bytes,
			txData 		=> txData,
			rxData		=> rxData,
			accel_data	=> accel_data,
			s1 => led0_dp,
			s2 => led1_dp
		);
	

	
	------------------------------------
	--LED's
	--      MSB       LSB
	--	XL =  7 downto  0
	--	XH = 15 downto  8
	--	YL = 23 downto 16
	--	YH = 31 downto 24
	--	ZL = 39 downto 32
	--	ZH = 47 downto 40
	------------------------------------
	U_LED0	:	entity work.decoder7seg
		port map(
			input => accel_data(19 downto 16),
			--input => accel_data(27 downto 24),
			output =>led0
		);
	--led0_dp <= '0';

	U_LED1	:	entity work.decoder7seg
		port map(
			--input => accel_data(31 downto 28),
			input => accel_data(23 downto 20),
			output =>led1
		);
	--led1_dp <= '0';


	
	process(clk50MHz, rst)
	begin
	
		if(rst = '1') then
			sclk_buffer <= '1';
		elsif(clk50MHz'event and clk50MHz = '1') then
			sclk_buffer <= sclk_out;
		end if;
	end process;
	
	
	
--	process(clk50MHz, rst)
--	begin
--	
--		if(rst = '1') then
--			count <= 0;
--			state <= S_1;
--		elsif(clk50MHz'event and clk50MHz = '1') then
--			
--			case state is
--				when S_1 =>
--					if(count = 10000000) then 
--						state <= S_2;
--						count <= 0;
--					else count <= count + 1;
--					end if;
--				when S_2 =>
--				if(count = 10000000) then 
--						state <= s_3;
--					
--						count <= 0;
--					else 
--						count <= count + 1;
--						led1_dp <= '0';
--					end if;
--					
--				when S_3 =>
--					state <= S_1;
--					led1_dp <= '1';
--					
--			end case;
--			
--		end if;
--	
--	end process;
	
	
end STR;
