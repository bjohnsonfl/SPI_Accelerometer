--spi_master_tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master_tb is
end spi_master_tb;

architecture TB of spi_master_tb is

-----------------------------------
--signals
-----------------------------------
signal clk 			: std_logic := '0';
signal rst 			: std_logic;
signal mosi			: std_logic;
signal miso 		: std_logic := '0';
signal sclk 	: std_logic;
signal cs 		: std_logic;
signal int1			: std_logic;
signal int2 		: std_logic;
signal go 			: std_logic;
signal pol 			: std_logic;
signal pha 			: std_logic;
signal bytes		: std_logic_vector (3 downto 0);
signal rxData 		:  std_logic_vector (7 downto 0);
signal txData 		: std_logic_vector (7 downto 0);
signal rxDataReady :	std_logic;

signal misoData :std_logic_vector(7 downto 0) := "11001110";
signal bit : integer range -1 to 8 := 7;
signal rxDataReceived : std_logic_vector (7 downto 0) := "00000000";


begin


-----------------------------------
--units under test
-----------------------------------

U_SPI_MASTER : entity work.spi_master(FSM_2P)
	port map(
		clk				=> clk, 
		rst				=> rst,
      mosi				=> mosi,
		miso 				=> miso,
		sclk_out			=> sclk,
		cs_out			=> cs,
		int1 				=> int1,
		int2 				=> int2,
		go					=> go,
		pol				=> pol,
		pha				=> pha,
		bytes				=> bytes,
		rxData 			=> rxData,
		txData			=> txData,
		rxDataReady		=> rxDataReady
		);

	
clk <= not clk after 10 ns;
	
process
begin

	rst <= '1';
	--miso <= '1';
	int1 <= '0';
	int2 <= '0';
	go <= '0';
	pol <= '1';
	pha <= '1';
	bytes <= "0100";
	txData <= "01010101";
	
	wait for 1 ms;
	wait until clk'event and clk = '1';
	
	rst <= '0';
	int1 <= '1';
	wait until clk'event and clk = '1';
	
	int1 <= '0';
	wait until clk'event and clk = '1';
	
	
	wait until rising_edge(rxDataReady);
	txData <= "11000011";
	wait until falling_edge(rxDataReady);
	rxDataReceived <= rxData;
	wait until clk'event and clk = '1';
	
	wait until rising_edge(rxDataReady);
	txData <= "10100101";
	wait until falling_edge(rxDataReady);
	rxDataReceived <= rxData;
	wait until clk'event and clk = '1';
	
	wait until rising_edge(rxDataReady);
	txData <= "00111100";
	
	rst <= '1';											--simulate a reset mid stream
	wait until clk'event and clk = '1';
	bytes <= "0010";									--2/4 bytes were transferred up to this point, so update
	wait until clk'event and clk = '1';
	wait until clk'event and clk = '1';
	wait until clk'event and clk = '1';
	rst <= '0';
	int1 <= '1';
	wait until clk'event and clk = '1';
	int1 <= '0';
	
	wait until falling_edge(rxDataReady);
	rxDataReceived <= rxData;
	wait until clk'event and clk = '1';
	
	wait until falling_edge(rxDataReady);
	--for i in 0 to 900000000 loop
	for i in 0 to 50000 loop  						--simulate time between transactions with 1ms delay
		wait until clk'event and clk = '1';
				
	end loop;
	bytes <= "0001";
	pha <= '1';
	misoData <= "11101011";
	wait until clk'event and clk = '1';
	wait until clk'event and clk = '1';
	int1 <= '1';										--trigger 1 byte transfer
	wait until clk'event and clk = '1';
	
	int1 <= '0';
	wait until clk'event and clk = '1';
	wait until falling_edge(rxDataReady);
	rxDataReceived <= rxData;
	wait until clk'event and clk = '1';
	
			for i in 0 to 900000000 loop
				wait until clk'event and clk = '1';
				
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



end process;




end TB;