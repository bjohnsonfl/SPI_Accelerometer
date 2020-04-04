--spi_master

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
    port (
		clk	: in std_logic;
		rst	: in std_logic;
      mosi	: out std_logic;
		miso 	: in std_logic;
		sclk_out : out std_logic; 
		cs_out	: out std_logic;
		int1 	: in std_logic;
		int2 	: in std_logic;
		go		: in std_logic;
		pol	: in std_logic;
		pha   : in std_logic;
		bytes : in std_logic_vector (3 downto 0);
		rxData: out std_logic_vector(7 downto 0);
		txData: in  std_logic_vector(7 downto 0);
		rxDataReady: out std_logic
		);
end spi_master;


architecture FSM_1P of spi_master is


------------------------------------
-- State signals
------------------------------------
type STATE_TYPE is (S_IDLE, S_TXRX);
signal state, next_state : STATE_TYPE;


------------------------------------
-- Clock Div (spi clock) Signals
------------------------------------
signal sclk : std_logic;
signal enable : std_logic := '0';
--signal bytes : std_logic_vector (3 downto 0);
signal polarity : std_logic;
signal last_clk_active : std_logic;
signal clk_active : std_logic;
signal byte_flag : std_logic;

------------------------------------
-- SPI Data Signals
------------------------------------
signal rx_buffer	: std_logic_vector (7 downto 0) := (others => '1');
signal tx_buffer	: std_logic_vector (7 downto 0);
signal cs : std_logic := '1';
constant byte_w : natural := 8;
signal bit : integer range -1 to 8 := 7; --init to msb+1 idx
signal w_r : std_logic := '0'; --write = 0 read = 1
signal phase_Delay : std_logic := '0';
signal last_cs : std_logic := '1';
signal last_sclk : std_logic := '0';



begin


	U_CLOCK_DIV : entity work.clock_div
		generic map(
			clk_in_freq => 50000000,
			clk_out_freq => 5000000)
		port map(
			clk_in => clk,
			clk_out => sclk,
			rst	=> rst,
			enable => enable,
			bytes	=> bytes,
			polarity => polarity,
			clk_active => clk_active,
			byte_flag => byte_flag);



	--enable <= int1 or int2 or go;
	
	process (clk, rst)
	begin
		
		if(rst = '1') then
			state <= S_IDLE;
			last_clk_active <= '0';
			enable <= '0';
			cs <= '1';
		elsif (clk'event and clk = '1') then
			
	
		--process(state, int1, int2, go, clk_active, byte_flag)--, txData)
		--begin
		
			rxDataReady <= '0'; --only high when data is ready
			polarity <= pol;
			--w_r <= not pha; --first write for phase 1 is pre toggled. 0 is default
		--	next_state <= state;
			enable <= '0';
			
			last_clk_active <= clk_active;
			
			case state is
				when S_IDLE =>
					
					--enable <= '0'; --default 
					cs <= '1';
					if((int1 = '1' or int2 = '1' or go = '1') and rst = '0') then
						state <= S_TXRX;
	--					polarity <= pol;
	--					w_r <= not pha; --first write for phase 1 is pre toggled. 0 is default
						enable <= '1';
						cs <= '0';
						tx_buffer <= txData; --TEST
						
					end if;
				
				
				when S_TXRX =>
					
					
					enable <= '1';
					
					if(last_clk_active = '1' and clk_active = '0') then  --falling edge of clk_active
						enable <= '0';
						cs <= '1';
						rxDataReady <= '1';
						state <= S_IDLE;
					
					else 
						enable <= '1';
						cs <= '0';
						if(byte_flag = '1') then
							rxDataReady <= '1';
							tx_buffer <= txData;
						end if;
					
					end if;
						
				when others => null;
				
				
			end case;
			
			
		end if;
		
	end process;
	
	cs_out <= cs;
	sclk_out <= sclk;
	
	
	
	
	process (clk, sclk, cs, rst)--, state)
	
	begin
		
		if( rst = '1') then
			bit <= 7;
			mosi <= '1';
		--else
		elsif(clk'event and clk = '1') then
		last_cs <= cs;
		last_sclk <= sclk;  --clk version
--		if(state'event and state = S_IDLE) then		-- entering idle init bit and rxbuffer
--			w_r <= pha;
--			bit <= 7;
--			rx_buffer <= (others => '1');
--			--initialize w/r
--			-- this will update whenever pha updates or state changes to re-init
--		
--		elsif ( state'event and state = S_TXRX) then -- state should not trigger any toggling
--			null;
--		else
		
			--pha 0 means write on falling cs
			--pha 1 means write on first clk edge
			-- w/r 0 means write
			--w/r 1 means read
			if(cs = '0' and last_cs = '1' ) then
				
				w_r <= not pha;				--pha 1 goes to write and pha 0 goes to read
				
				if(pha = '0') then
					mosi <= tx_buffer(bit); --write	
				end if;
				
			elsif(cs = '0' and (last_sclk /= sclk)) then									-- this point on are only clk events high or low
				
				if(w_r = '0') 	then				-- write
					mosi <= tx_buffer(bit);
					
				elsif (w_r = '1') then		-- read
					rx_buffer <= rx_buffer(6 downto 0) & miso;
					bit <= bit - 1;			-- only decrement after reads
					if(bit = 0) then			-- reset bit to 7 at end of byte instead of decrementing
						bit <= 7;
						--rxData <= rx_buffer;
					end if;
				else 
					null;							-- do nothing
				end if;
				
				w_r <= not w_r;				-- toggle write/read for next clock edge
				
			else 
				--mosi <= 'Z';
				null;
			end if;
			
			if(bit = 7) then
				rxData <= rx_buffer;
			end if;
			
		end if;
	
	
	
	end process;
	

	--rxData <= rx_buffer;
end FSM_1P;



architecture FSM_2P of spi_master is


------------------------------------
-- State signals
------------------------------------
type STATE_TYPE is (S_IDLE, S_TXRX);
signal state, next_state : STATE_TYPE;


------------------------------------
-- Clock Div (spi clock) Signals
------------------------------------
signal sclk : std_logic;
signal enable : std_logic := '0';
--signal bytes : std_logic_vector (3 downto 0);
signal polarity : std_logic;
signal clk_active : std_logic;
signal byte_flag : std_logic;

------------------------------------
-- SPI Data Signals
------------------------------------
signal rx_buffer	: std_logic_vector (7 downto 0) := (others => '1');
signal tx_buffer	: std_logic_vector (7 downto 0);
signal cs : std_logic := '1';
constant byte_w : natural := 8;
signal bit : integer range -1 to 8 := 7; --init to msb+1 idx
signal w_r : std_logic := '0'; --write = 0 read = 1
signal phase_Delay : std_logic := '0';
signal last_cs : std_logic := '1';
signal last_sclk : std_logic := '0';



begin


	U_CLOCK_DIV : entity work.clock_div
		generic map(
			clk_in_freq => 50000000,
			clk_out_freq => 5)
		port map(
			clk_in => clk,
			clk_out => sclk,
			rst	=> rst,
			enable => enable,
			bytes	=> bytes,
			polarity => polarity,
			clk_active => clk_active,
			byte_flag => byte_flag);



	--enable <= int1 or int2 or go;
	
	process (clk, rst)
	begin
		
		if(rst = '1') then
			state <= S_IDLE;
		elsif (clk'event and clk = '1') then
			state <= next_state;
		end if;
	
	
	end process;
	
	
	process(state, int1, int2, go, clk_active, byte_flag)--, txData)
	begin
	
		rxDataReady <= '0'; --only high when data is ready
		polarity <= pol;
		--w_r <= not pha; --first write for phase 1 is pre toggled. 0 is default
		next_state <= state;
		enable <= '0';
		
		
		case state is
			when S_IDLE =>
				
				--enable <= '0'; --default 
				cs <= '1';
				if((int1 = '1' or int2 = '1' or go = '1') and rst = '0') then
					next_state <= S_TXRX;
--					polarity <= pol;
--					w_r <= not pha; --first write for phase 1 is pre toggled. 0 is default
					enable <= '1';
					cs <= '0';
					tx_buffer <= txData; --TEST
					
				end if;
			
			
			when S_TXRX =>
				
				
				enable <= '1';
				
				if(clk_active = '0') then
					enable <= '0';
					cs <= '1';
					rxDataReady <= '1';
					next_state <= S_IDLE;
				
				else 
					enable <= '1';
					cs <= '0';
					if(byte_flag = '1') then
						rxDataReady <= '1';
						tx_buffer <= txData;
					end if;
				
				end if;
					
			when others => null;
			
			
		end case;
		
	end process;
	
	cs_out <= cs;
	sclk_out <= sclk;
	
	
	
	
	process (clk, sclk, cs, rst)--, state)
	
	begin
		
		if( rst = '1') then
			bit <= 7;
			mosi <= '1';
		--else
		elsif(clk'event and clk = '1') then
		last_cs <= cs;
		last_sclk <= sclk;  --clk version
--		if(state'event and state = S_IDLE) then		-- entering idle init bit and rxbuffer
--			w_r <= pha;
--			bit <= 7;
--			rx_buffer <= (others => '1');
--			--initialize w/r
--			-- this will update whenever pha updates or state changes to re-init
--		
--		elsif ( state'event and state = S_TXRX) then -- state should not trigger any toggling
--			null;
--		else
		
			--pha 0 means write on falling cs
			--pha 1 means write on first clk edge
			-- w/r 0 means write
			--w/r 1 means read
			if(cs = '0' and last_cs = '1' ) then
				
				w_r <= not pha;				--pha 1 goes to write and pha 0 goes to read
				
				if(pha = '0') then
					mosi <= tx_buffer(bit); --write	
				end if;
				
			elsif(cs = '0' and (last_sclk /= sclk)) then									-- this point on are only clk events high or low
				
				if(w_r = '0') 	then				-- write
					mosi <= tx_buffer(bit);
					
				elsif (w_r = '1') then		-- read
					rx_buffer <= rx_buffer(6 downto 0) & miso;
					bit <= bit - 1;			-- only decrement after reads
					if(bit = 0) then			-- reset bit to 7 at end of byte instead of decrementing
						bit <= 7;
					end if;
				else 
					null;							-- do nothing
				end if;
				
				w_r <= not w_r;				-- toggle write/read for next clock edge
				
			else 
				--mosi <= 'Z';
				null;
			end if;
		end if;
	
	
	
	end process;
	
--	
--	process (sclk, cs, state, pha)
--		variable clk_cs_event : std_logic;
--	
--	begin
--	
--		if(state = S_IDLE) then
--			w_r <= pha;
--			bit <= 7;
--			rx_buffer <= (others => '1');
--			--initialize w/r
--			-- this will update whenever pha updates or state changes to re-init
--		end if;
--			
--			clk_cs_event := '0';
--			
--		if(falling_edge(cs) or (sclk'event and cs = '0')) then
--			w_r <= not w_r;
--			clk_cs_event := '1';
--		end if;
--		--if sclk event, do w/r and then toggle it
--		-- if cs falls and pha = 1, write
--		
--		--write if w/r = 0 
--			--this works because at init w/r =  pha
--			-- so  pha = 0 is 1. no case will be true and w/r will toggle
--			--next event will be a clok edge
--		-- read if w/r = 1 
--			-- if cs event and pha
--			
--		if(clk_cs_event = '1') then
--			if(w_r = '0') then	--write
--				mosi <= tx_buffer(bit);
--				
--			elsif((falling_edge(cs) and (pha = '0')) or (sclk'event and w_r = '1')) then --read
--				rx_buffer <= rx_buffer(6 downto 0) & miso;
--				bit <= bit - 1;
--				if(bit = 0) then			-- reset bit to 7 at end of byte instead of decrementing
--					bit <= 7;
--				end if;
--				
--			end if;
--			
--
--		end if;
--		
--	
--	end process;
	
	
	
	
--	process(sclk, cs)
--	begin
--		
--		-- phase
--		-- 0 start : write on cs, read on first clock
--		--	0 normal: write on first edge, read on second edge
--		-- 1 start : write on first edge, read on second edge
--		-- 1 normal: write on first edge, read on second edge
--	
--		
--		phase_Delay <= '0'; --set delay to false
--		
--		if( bit = 0) then
--			bit <= 7;
--		end if;
--		
--		bit <= bit - 1;
--		
----	
--		
--		if ( sclk'event ) then
--		--	w_r <= not w_r; 
--		
--		elsif (falling_edge(cs) and pha = '0') then
--			--write
--			--next clock is going to be raising or falling
--			--if pol 0, then rising
--			--if pol 1, then falling
--			phase_Delay <= '1';
--		
--		end if;
--		
--		
--		if ( w_r = '0' and phase_Delay = '0') then --write except if pha = 1 and before first clk event
--			
--			mosi <= tx_buffer(bit);
--			
--		elsif(w_r = '1') then  --read
--			rx_buffer <= miso & rx_buffer(7 downto 1);
--		end if;
--	
--		
--	end process;
	
	--tx_buffer <= txData;
	rxData <= rx_buffer;


end FSM_2P;