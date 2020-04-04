--accel_driver
-- TODO:
-- 1) Incorporate data range generic for calibration LSB/g for z axis
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accel_driver is
	port (
		rst			:		in std_logic;
		clk			:		in std_logic;
		int1			:		in std_logic;
		rxDataReady	:		in	std_logic;
		go				:		out std_logic;
		pol			:		out std_logic;
		pha			:		out std_logic;
		bytes 		:		out std_logic_vector (3 downto 0);
		txData 		:		out std_logic_vector (7 downto 0);
		rxData		: 		in std_logic_vector ( 7 downto 0);
		accel_data	:		out std_logic_vector (47 downto 0);
		
		stateID 		:      out std_logic_vector (2 downto 0);
		m				: out std_logic;
		c				: out std_logic;
		intBypass   : in std_logic
		
		
	);
end accel_driver;



architecture fsm_1p of accel_driver is
	
	constant max	: natural := 50000000 /  500000 ;
	signal count			:		integer range 0 to max;
	signal countSignal		: std_logic;
	type STATE_TYPE is (S_START, S_IDLE, S_CONFIG, S_WRITE, S_READ, S_READ_WAIT, S_CALIBRATE, S_OUTPUT); --S_CONFIG_TEST, S_WRITE_TEST);
	signal STATE, NEXT_STATE			:		STATE_TYPE;
	--signal accel_x, accel_y, accel_z	:		std_logic_vector(15 downto 0);
	signal accel_data_buff : std_logic_vector( 47 downto 0);
	signal byteCount	: integer range -1 to 16 := 0;
	constant byteCountRead : integer := 7;
	signal mode			: std_logic;
	signal reg	: integer range 0 to 8;
	signal regTest : integer range 0 to 16;
	signal regAddr		: std_logic_vector (5 downto 0);
	signal regData		: std_logic_vector (7 downto 0);
	signal rxDataReadyLast : std_logic := '0';
	
	constant sampleBits : natural := 4;
	constant samples  : natural := 2 ** sampleBits;
	--signal div_padding : std_logic_vector (sampleBits - 1 downto 0);
	signal sample_count : integer range 0 to samples + 1;
	signal calibrate : std_logic;
	--type NIBBLE is array (3 downto 0) of std_ulogic;
	type calibration_array is array (2 downto 0) of std_logic_vector (15 downto 0);  -- (0) X accumulate, (1) Y accumulate, (2) Z accumulate
	signal calibData : calibration_array;
	
begin




	process(clk, rst)
	begin
		if(rst = '1') then
			state <= S_START;
			accel_data <= (others => '0');
			accel_data_buff <= (others => '0');
			regData <= "00000000";
			regAddr <= "000000";
			bytes <= "0000";
			txData <= "00000000";
			mode <= '0';
			count <= 0;
			go <= '0';
			reg <= 0;
			regTest <= 0;
			byteCount <= 0;
			stateID <= "000";
			calibrate <= '0';
			calibData(0) <= (others => '0');
			calibData(1) <= (others => '0');
			calibData(2) <= (others => '0');
			sample_count <= 0;
			--div_padding <= (others => '0');
			
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
					
					stateID <= "001";
				
				when S_IDLE =>
					stateID <= "010";
					--if(mode = '1' and int1 = '1') then state <= S_READ;
					--end if;
		
					if(count = max - 1) then							-- delay between each transmission 
						--count <= 0;
						c <= '1';
						
						if(mode = '0') then
							state <= S_CONFIG;		-- mode 0 is config. after config mode goes to 1 for read
							count <= 0; 
						--elsif(int1 = '1')   then
						else
							state <= S_READ_WAIT;	-- mode 1, but only read if interrupt for data_ready is set
							count <= 0;
						--else count <= max - 1;							-- do not set count to 0 to prevent running the delay loop again
						end if;	
			
					else 
						count <= count + 1;
						c <= '0';
					end if;
					
--					if(intBypass = '1') then state <= S_IDLE;
--					end if;
			
				when S_READ_WAIT =>
					stateID <= "111";
					if (calibrate = '1') then state <= S_CALIBRATE;
					elsif(int1 = '1' or intBypass = '1') then state <= S_READ;
					end if;
					
				when S_CALIBRATE => 
					case reg is								-- reg should be 0 from config state earlier, represents each offset register
						when 0 =>							-- calculate the negative of x and y offset. subtract 256 (1g) from z and shift 2 (8 bit conversion)
							if(calibData(0)(15) = '0') then  -- x axis negative conversion
								calibData(0) <= std_logic_vector(signed(not calibData(0)) + 1);	-- twos comp conversion from positive to negative
							else
								calibData(0) <= std_logic_vector(not(signed(calibData(0)) - 1));  -- twos comp conversion from negative to positive
							end if;
							
							if(calibData(1)(15) = '0') then -- y axis negative conversion
								calibData(1) <= std_logic_vector(signed(not calibData(1)) + 1);	-- twos comp conversion from positive to negative
							else
								calibData(1) <= std_logic_vector(not(signed(calibData(1)) - 1));  -- twos comp conversion from negative to positive
							end if;
							
							calibData(2) <=std_logic_vector(shift_right(signed(calibData(2)) - 256, 2));	-- find error realtive to gravity in z axis and divide by 4 for 10 to 8 bit conversion			
							reg <= reg + 1;
						
						when 1 =>																					-- calculate Z's negative, store x axis
						
							if(calibData(2)(15) = '0') then 													-- Z axis negative conversion
								calibData(2) <= std_logic_vector(signed(not calibData(2)) + 1);	-- twos comp conversion from positive to negative
							else
								calibData(2) <= std_logic_vector(not(signed(calibData(2)) - 1));  -- twos comp conversion from negative to positive
							end if;
							
							regAddr <= "011110";																	-- Register 0x1E: "X offset" 8 bit 2's comp offset for X axis
							regData <= calibData(0)(7 downto 0);															-- X offset data
							reg <= reg + 1;	
							state  <= S_WRITE;
						when 2 =>
							regAddr <= "011111";																	-- Register 0x1F: "Y offset" 8 bit 2's comp offset for Y axis
							regData <= calibData(1)(7 downto 0);
							reg <= reg + 1;
							state  <= S_WRITE;
						when 3 =>
							regAddr <= "100000";																	-- Register 0x20: "Z offset" 8 bit 2's comp offset for Z axis
							regData <= calibData(2)(7 downto 0);
							reg <= 0;
							state  <= S_WRITE;
							calibrate <= '0';																		-- de-assert calibration flag to continue reading normally
						when others => null;
						
					end case;
					
					
--				when S_CONFIG_TEST =>
--						stateID <= "111";
--					case regTest is
--						when 0 =>
--							regAddr <= "110001";			--	Off 		Off   A
--							regData <= "00001010";
--							regTest <= regTest + 1;
--							state <= S_WRITE;
--						when 1 => 
--							regAddr <= "101100";									-- 6
--							regData <= "00000110";
--							regTest <= regTest + 1;
--							state <= S_WRITE;
--						when 2 => 
--							regAddr <= "101101";                          --8
--							regData <= "00001011";
--							regTest <= regTest + 1;
--							state <= S_WRITE;
--						when 3 =>
--							--regAddr <= "000000";    -- A      OFF	ON
--							regAddr <= "110001";
--							regData <= "00001000";
--							regTest <= regTest + 1;
--							--regTest <= 0;
--							
--							state <= S_WRITE_TEST;					
--						when 4 => 						-- E5			ON     ON
--							--regAddr <= "101100";
--							regAddr <= "000000";
--							regData <= "00000000";
--							regTest <= regTest + 1;
--							state <= S_WRITE_TEST;
--							
--						when 5 => 						-- B			ON    OFF
--							regAddr <= "101101";
--							regData <= "00000000";
--							regTest <= 0;
--							state <= S_WRITE_TEST;
--							mode <= '1';
--							
--
--						when others => null;
--					end case;
--					
--				when S_WRITE_TEST =>
--					mode <= '0';
--					bytes <= "0010";
--					rxDataReadyLast <= rxDataReady;
--					if(byteCount = 0) then
--						txData <= "10" & regAddr;
--						go <= '1';
--						byteCount <= 1;
--					else
--						txData <= "00000000";
--						go <= '0';
--						
--						if((rxDataReadyLast = '1' and rxDataReady = '0') and byteCount <= 2) then
--	--						byteCount <= byteCount + 1;
--	--						accel_data_buff((byteCount * 8)  - 1 downto (byteCount-1) * 8) <= rxData;
--	--						if(byteCount = byteCountRead - 1) then
--	--							byteCount <= 0;
--	--							next_state <= S_OUTPUT;
--	--						end if;
--							if(byteCount = 2) then
--								byteCount <= 0;
--								state <= S_OUTPUT;
--							else
--								byteCount <= byteCount + 1;
--								accel_data_buff(23 downto 16) <= rxData;
--							end if;
--
--
--						end if;
--						
--						
--					end if;
--					
--				
				
				
				when S_CONFIG =>
						stateID <= "011";
					case reg is
						when 0 =>
							regAddr <= "110001"; -- Register 0x31: "Data_Format" sets data range (0b00) to +/- 2g and full resultion (0b1000)
							regData <= "00001000";   
							reg <= reg + 1;
							state <= S_WRITE;
						when 1 => 
							regAddr <= "101100";  -- Register 0x2C: "BW_RATE" sets rate (0b0100) to 1.56 Hz, ideal should be 100hz which is default at power reset, but too fast for 7seg's
							regData <= "00000100";
							reg <= reg + 1;
							state <= S_WRITE;
						when 2 =>
							regAddr <= "011110";					-- Register 0x1E: "X offset" 8 bit 2's comp offset for X axis
							regData <= "00000000";				-- Clear X offset register so calibration will not use data from previous resets
							reg <= reg + 1;
							state  <= S_WRITE;
							
						when 3 =>
							regAddr <= "011111";					-- Register 0x1F: "Y offset" 8 bit 2's comp offset for Y axis
							regData <= "00000000";				-- Clear Y offset register so calibration will not use data from previous resets
							reg <= reg + 1;
							state  <= S_WRITE;
						
						when 4 =>
							regAddr <= "100000";					-- Register 0x20: "Z offset" 8 bit 2's comp offset for Z axis
							regData <= "00000000";				-- Clear Z offset register so calibration will not use data from previous resets
							reg <= reg + 1;
							state  <= S_WRITE;
						
						when 5 => 
							regAddr <= "101101";	 -- Register 0x2D: "Power_CTL" sets measure bit (0b1000) to start sampling. 
							regData <= "00001000";
							reg <= reg + 1;
							state <= S_WRITE;
							--mode <= '1';			-- Switch to Read mode so IDLE turns to S_READ and not S_CONFIG
						when 6 => 
							regAddr <= "101110";	 -- Register 0x2E: "INT_ENABLE" enables Data_Ready interrupt (0b10000000) 
							regData <= "10000000";
							reg <= 0;
							state <= S_WRITE;
							mode <= '1';			-- Switch to Read mode so IDLE turns to S_READ and not S_CONFIG
						when others => null;
					end case;
				
				when S_WRITE =>
					stateID <= "100";
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
						txData <= regData;
					elsif((rxDataReadyLast = '0' and rxDataReady = '1') and byteCount = 2) then  -- rising edge, nothing is transmitted here
						byteCount <= 3;
							
						
					elsif((rxDataReadyLast = '1' and rxDataReady = '0') and byteCount = 3) then  --falling edge
						state <= S_IDLE;
						byteCount <= 0;
					end if;
				--00111101 00001000
				when S_READ =>
					stateID <= "101";
					
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
								accel_data_buff(((byteCount-1) * 8)  - 1 downto (byteCount-2) * 8) <=  rxData;-- std_logic_vector(to_unsigned(byteCount, bytes'length)); -- rxData;
							end if;


						end if;
						
						
					end if;
				when S_OUTPUT =>
					stateID <= "110";
					
					if(sample_count <= samples) then				-- enter for first n samples for calibration
						if(sample_count = samples) then			-- compare sample count to threshold 
							calibrate <= '1';							-- set flag to calibrate with new values
							calibData(0) <= std_logic_vector(shift_right(signed(calibData(0)), 2 + sampleBits)); -- divide by number of samples for average, and convert to 64 LSB/1g (shifting a 10 bit value right arithmetically for an 8 bit value)
							calibData(1) <= std_logic_vector(shift_right(signed(calibData(1)), 2 + sampleBits));
							calibData(2) <= std_logic_vector(shift_right(signed(calibData(2)), sampleBits)); -- get average. Next clock cycle will compare to 1g (2^8), and then convert to 64 LSB/1g
						else 												-- summation of samples
							calibData(0) <= std_logic_vector(signed(calibData(0)) + signed(accel_data_buff(15 downto   0))); -- summation of X data	
							calibData(1) <= std_logic_vector(signed(calibData(1)) + signed(accel_data_buff(31 downto  16))); -- summation of Y data	
							calibData(2) <= std_logic_vector(signed(calibData(2)) + signed(accel_data_buff(47 downto  32))); -- summation of Z data								
						end if;
						sample_count <= sample_count + 1;	-- increment count, if n samples have been collected, one more prevents entering this if statement
					accel_data <= accel_data_buff;
					else
						accel_data <= accel_data_buff;			-- clock collected accelerometer data for ouput
					end if;
						state <= S_IDLE;								-- go back to idle to repeat the cycle
					
				when others => 
					stateID <= "111";
						NULL;
				
			
			
			end case;


			pol <= '1';
			pha <= '1';
		
		end if;
		
	end process;

	
		m <= mode;





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