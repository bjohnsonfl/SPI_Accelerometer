--accel_driver
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accel_driver is
	port (
		rst			:		in std_logic;
		clk			:		in std_logic;
		rxDataReady	:		in	std_logic;
		go				:		out std_logic;
		pol			:		out std_logic;
		pha			:		out std_logic;
		bytes 		:		out std_logic_vector (3 downto 0);
		txData 		:		out std_logic_vector (7 downto 0);
		rxData		: 		in std_logic_vector ( 7 downto 0);
		accel_data	:		out std_logic_vector (47 downto 0);
		
		s1				: out std_logic;
		s2				: out std_logic
		
	);
end accel_driver;

--
--config    = write and write
--reading   = write and read n - 1 times


architecture fsm_1p of accel_driver is
	
	constant max	: natural := 50000000 /  500000 ;
	signal count			:		integer range 0 to max;
	signal countSignal		: std_logic;
	type STATE_TYPE is (S_START, S_IDLE, S_CONFIG, S_WRITE, S_READ, S_OUTPUT, S_CONFIG_TEST, S_WRITE_TEST);-- S_TEST_IDLE, S_TEST_OUTPUT);
	signal STATE, NEXT_STATE			:		STATE_TYPE;
	--signal accel_x, accel_y, accel_z	:		std_logic_vector(15 downto 0);
	signal accel_data_buff : std_logic_vector( 47 downto 0);
	signal byteCount	: integer range -1 to 16 := 0;
	constant byteCountRead : integer := 7;
	signal mode			: std_logic;
	signal reg	: integer range 0 to 3;
	signal regTest : integer range 0 to 16;
	signal regAddr		: std_logic_vector (5 downto 0);
	signal regData		: std_logic_vector (3 downto 0);
	signal rxDataReadyLast : std_logic := '0';
begin




	process(clk, rst)
	begin
		if(rst = '1') then
			state <= S_START;
			count <= 0;
			accel_data <= (others => '0');
			accel_data_buff <= (others => '0');
			regData <= "0000";
			regAddr <= "000000";
			bytes <= "0000";
			txData <= "00000000";
			mode <= '0';
			count <= 0;
			go <= '0';
			reg <= 0;
			regTest <= 0;
			byteCount <= 0;
			
		elsif(clk'event and clk = '1') then
			
			
			
			case state is
			
				when S_START =>
					byteCount <= 0;
					mode <= '0';
					reg <= 0;
					rxDataReadyLast <= '0';
					state <= S_IDLE;
					accel_data <= (others => '0');
					go <= '0';
				
				when S_IDLE =>
		
					if(count = max - 1) then							--delay between each transmission 
						count <= 0;
						
						if(mode = '0') then state <= S_CONFIG;
						else state <= S_READ;
						end if;	
			
					else 
						count <= count + 1;
					end if;
			
				
				when S_CONFIG_TEST =>
						s1 <= '1';
						s2 <= '1';
					case regTest is
						when 0 =>
							regAddr <= "110001";			--	Off 		Off   A
							regData <= "1010";
							regTest <= regTest + 1;
							state <= S_WRITE;
						when 1 => 
							regAddr <= "101100";									-- 6
							regData <= "0110";
							regTest <= regTest + 1;
							state <= S_WRITE;
						when 2 => 
							regAddr <= "101101";                          --8
							regData <= "1011";
							regTest <= regTest + 1;
							state <= S_WRITE;
						when 3 =>
							--regAddr <= "000000";    -- A      OFF	ON
							regAddr <= "110001";
							regData <= "1000";
							regTest <= regTest + 1;
							--regTest <= 0;
							s1 <= '0';
							state <= S_WRITE_TEST;					
						when 4 => 						-- E5			ON     ON
							--regAddr <= "101100";
							regAddr <= "000000";
							regData <= "0000";
							regTest <= regTest + 1;
							state <= S_WRITE_TEST;
							s1 <= '0';
							s2 <= '0';
						when 5 => 						-- B			ON    OFF
							regAddr <= "101101";
							regData <= "0000";
							regTest <= 0;
							state <= S_WRITE_TEST;
							mode <= '1';
							s2 <= '0';

						when others => null;
					end case;
					
				when S_WRITE_TEST =>
					mode <= '0';
					bytes <= "0010";
					rxDataReadyLast <= rxDataReady;
					if(byteCount = 0) then
						txData <= "10" & regAddr;
						go <= '1';
						byteCount <= 1;
					else
						txData <= "00000000";
						go <= '0';
						
						if((rxDataReadyLast = '1' and rxDataReady = '0') and byteCount <= 2) then
	--						byteCount <= byteCount + 1;
	--						accel_data_buff((byteCount * 8)  - 1 downto (byteCount-1) * 8) <= rxData;
	--						if(byteCount = byteCountRead - 1) then
	--							byteCount <= 0;
	--							next_state <= S_OUTPUT;
	--						end if;
							if(byteCount = 2) then
								byteCount <= 0;
								state <= S_OUTPUT;
							else
								byteCount <= byteCount + 1;
								accel_data_buff(23 downto 16) <= rxData;
							end if;


						end if;
						
						
					end if;
					
				
				
				
				when S_CONFIG =>
					case reg is
						when 0 =>
							regAddr <= "110001";  --"00"
							regData <= "1000";    -- "0000"
							reg <= reg + 1;
							state <= S_WRITE;
						when 1 => 
							regAddr <= "101100";
							regData <= "0100";
							reg <= reg + 1;
							state <= S_WRITE;
						when 2 => 
							regAddr <= "101101";
							regData <= "1000";
							reg <= 0;
							state <= S_WRITE;
							mode <= '1';
	--					when 3 =>
	--						regAddr <= "000000";
	--						regData <= "0000";
	--						reg <= 0;
	--						next_state <= S_WRITE;
	--						mode <= '1';
						when others => null;
					end case;
				
				when S_WRITE =>
					bytes <= "0010";
					rxDataReadyLast <= rxDataReady;
					if(byteCount = 0) then
						txData <= "00" & regAddr;
						go <= '1';
						byteCount <= 1;
					--elsif(rising_edge(rxDataReady) and byteCount = 1) then
					elsif((rxDataReadyLast = '0' and rxDataReady = '1') and byteCount = 1) then  -- rising edge
						byteCount <= 2;
						go <= '0';
						txData <= "0000" & regData;
					elsif((rxDataReadyLast = '0' and rxDataReady = '1') and byteCount = 2) then  -- rising edge, nothing is transmitted here
						byteCount <= 3;
							
						
					elsif((rxDataReadyLast = '1' and rxDataReady = '0') and byteCount = 3) then  --falling edge
						state <= S_IDLE;
						byteCount <= 0;
					end if;
				--00111101 00001000
				when S_READ =>
					mode <= '1';
					bytes <= std_logic_vector(to_unsigned(byteCountRead, bytes'length));
					rxDataReadyLast <= rxDataReady;
					if(byteCount = 0) then														-- Send Read Command
						txData <= "11110010";
						go <= '1';
						byteCount <= 1;
					elsif(byteCount = 1) then													--next system clock enters here
						txData <= "00000000";							
						go <= '0';
						if((rxDataReadyLast = '1' and rxDataReady = '0')) then		--wait until 8 bits are sent to update byte count 
							byteCount <= 2;
						end if;
						
					else																				--read bytes 2 3 4 5 6 and 7
						txData <= "00000000";
						go <= '0';
						
						if((rxDataReadyLast = '1' and rxDataReady = '0') and byteCount <= byteCountRead) then
	--						byteCount <= byteCount + 1;
	--						accel_data_buff((byteCount * 8)  - 1 downto (byteCount-1) * 8) <= rxData;
	--						if(byteCount = byteCountRead - 1) then
	--							byteCount <= 0;
	--							next_state <= S_OUTPUT;
	--						end if;
							if(byteCount = byteCountRead) then
								byteCount <= 0;
								state <= S_OUTPUT;
							else
								byteCount <= byteCount + 1;
								accel_data_buff(((byteCount-1) * 8)  - 1 downto (byteCount-2) * 8) <=  rxData;--std_logic_vector(to_unsigned(byteCount, bytes'length)); -- rxData;
							end if;


						end if;
						
						
					end if;
				when S_OUTPUT =>
					--mode <= '1';
					accel_data <= accel_data_buff;
					state <= S_IDLE;
				when others => 
					NULL;
				
			
			
			end case;


			pol <= '1';
			pha <= '1';
		
		end if;
		
	end process;







end fsm_1p;





architecture fsm_2p of accel_driver is
	
	constant max	: natural := 50000000 / 5000000 ;
	signal count			:		integer range 0 to max;
	signal countSignal		: std_logic;
	type STATE_TYPE is (S_START, S_IDLE, S_CONFIG, S_WRITE, S_READ, S_OUTPUT);-- S_TEST_IDLE, S_TEST_OUTPUT);
	signal STATE, NEXT_STATE			:		STATE_TYPE;
	--signal accel_x, accel_y, accel_z	:		std_logic_vector(15 downto 0);
	signal accel_data_buff : std_logic_vector( 47 downto 0);
	signal byteCount	: integer range -1 to 16;
	constant byteCountRead : integer := 7;
	signal mode			: std_logic;
	signal reg	: integer range 0 to 3;
	signal regAddr		: std_logic_vector (5 downto 0);
	signal regData		: std_logic_vector (3 downto 0);
	signal rxDataReadyLast : std_logic := '0';
begin




	process(clk, rst)
	begin
		if(rst = '1') then
			state <= S_START;
			count <= 0;
			
		elsif(clk'event and clk = '1') then
			
			
			if(state = S_IDLE) then
				if(count = max - 1) then
				count <= 0;
				state <= next_state;
			
				else 
				count <= count + 1;
				state <= S_IDLE;
				end if;
			
			else
			
			state <= next_state;
			end if;
				
				
		end if;
		
	end process;

	


	process(state, rxDataReady)
	begin
			next_state <= state;
			go <= '0';
			reg <= 0;
		--	byteCount <= 0;
			accel_data <= (others => '0');
			regData <= "0000";
			regAddr <= "000000";
			bytes <= "0000";
			txData <= "00000000";
			mode <= '0';
		case state is
		
			when S_START =>
				byteCount <= 0;
				mode <= '0';
				reg <= 0;
				rxDataReadyLast <= '0';
				next_state <= S_IDLE;
				--next_state <= S_TEST_IDLE;
				accel_data <= (others => '0');
				--go <= '0';
			
--			when S_TEST_IDLE =>
--				
--				bytes <= "0010";
--				rxDataReadyLast <= rxDataReady;
--				if(byteCount = 0) then
--					txData <= "10000000";
--					go <= '1';
--					byteCount <= 1;
--				--elsif(rising_edge(rxDataReady) and byteCount = 1) then
--				elsif((rxDataReadyLast = '0' and rxDataReady = '1') and byteCount = 1) then  -- rising edge
--					byteCount <= 2;
--					go <= '0';
--					txData <= "10000000";
--				elsif((rxDataReadyLast = '0' and rxDataReady = '1') and byteCount = 2) then  -- rising edge, nothing is transmitted here
--					byteCount <= 3;
--						
--					
--				elsif((rxDataReadyLast = '1' and rxDataReady = '0') and byteCount = 3) then  --falling edge
--					next_state <= S_TEST_OUTPUT;
--					byteCount <= 0;
--					accel_data_buff (7 downto 0) <= rxData;
--				end if;
--				
--			when S_TEST_OUTPUT =>
--				accel_data <= accel_data_buff;
--				--next_state <= S_IDLE;
				
			when S_IDLE =>
				mode <= mode;
				reg <= reg;
				if(mode = '0') then next_state <= S_CONFIG;
				else next_state <= S_READ;
				end if;	
				
					
			
			when S_CONFIG =>
				case reg is
					when 0 =>
						regAddr <= "110001";
						regData <= "1000";
						reg <= reg + 1;
						next_state <= S_WRITE;
					when 1 => 
						regAddr <= "101100";
						regData <= "0100";
						reg <= reg + 1;
						next_state <= S_WRITE;
					when 2 => 
						regAddr <= "101101";
						regData <= "1000";
						reg <= 0;
						next_state <= S_WRITE;
						mode <= '1';
--					when 3 =>
--						regAddr <= "000000";
--						regData <= "0000";
--						reg <= 0;
--						next_state <= S_WRITE;
--						mode <= '1';
					when others => null;
				end case;
			
			when S_WRITE =>
				bytes <= "0010";
				rxDataReadyLast <= rxDataReady;
				regAddr <= regAddr;
				regData <= regData;
				--byteCount <= byteCount;
				reg <= reg;
				mode <= mode;
				--txData <= txData;
				if(byteCount = 0) then
					txData <= "00" & regAddr;
					go <= '1';
					byteCount <= 1;
				--elsif(rising_edge(rxDataReady) and byteCount = 1) then
				elsif((rxDataReadyLast = '0' and rxDataReady = '1') and byteCount = 1) then  -- rising edge
					byteCount <= 2;
					go <= '0';
					txData <= "0000" & regData;
				elsif((rxDataReadyLast = '0' and rxDataReady = '1') and byteCount = 2) then  -- rising edge, nothing is transmitted here
					byteCount <= 3;
						
					
				elsif((rxDataReadyLast = '1' and rxDataReady = '0') and byteCount = 3) then  --falling edge
					next_state <= S_IDLE;
					byteCount <= 0;
				end if;
			--00111101 00001000
			when S_READ =>
				mode <= '1';
				bytes <= std_logic_vector(to_unsigned(byteCountRead, bytes'length));
				rxDataReadyLast <= rxDataReady;
				if(byteCount = 0) then
					txData <= "11110010";
					go <= '1';
					byteCount <= 1;
				else
					txData <= "00000000";
					go <= '0';
					--if(falling_edge(rxDataReady) and byteCount < byteCountRead) then		-- falling edge
					if((rxDataReadyLast = '1' and rxDataReady = '0') and byteCount <= byteCountRead) then
--						byteCount <= byteCount + 1;
--						accel_data_buff((byteCount * 8)  - 1 downto (byteCount-1) * 8) <= rxData;
--						if(byteCount = byteCountRead - 1) then
--							byteCount <= 0;
--							next_state <= S_OUTPUT;
--						end if;
						if(byteCount = byteCountRead) then
							byteCount <= 0;
							next_state <= S_OUTPUT;
						else
							byteCount <= byteCount + 1;
							accel_data_buff((byteCount * 8)  - 1 downto (byteCount-1) * 8) <= rxData;
						end if;


					end if;
					
					
				end if;
			when S_OUTPUT =>
				mode <= '1';
				accel_data <= accel_data_buff;
				next_state <= S_IDLE;
			when others => 
				NULL;
			
		
		
		end case;


		pol <= '1';
		pha <= '1';
		
		
		
	end process;







end fsm_2p;