--clock div
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div is
	generic(clk_in_freq : natural := 4;
				clk_out_freq : natural := 2);
	port (
			clk_in : in std_logic;
			clk_out : out std_logic;
			rst	: in std_logic;
			enable : in std_logic;
			bytes : in std_logic_vector(3 downto 0);
			polarity : in std_logic;
			clk_active :	out std_logic;
			byte_flag : out std_logic
			);
end clock_div;

architecture bhv of clock_div is

	
	constant max : natural := clk_in_freq / clk_out_freq / 2;
	signal count, lastByteCount : integer range 0 to max*2;
	signal clock_signal : std_logic;
	signal byte_count : std_logic_vector (3 downto 0);
	signal bit_count : integer range 0 to 8;
	
	
	
	
	begin
	
		process(clk_in, rst)
		begin
			if(rst = '1' or enable = '0') then
				count <= 0;
				lastByteCount <= 0;
				clk_active <= '0';
				clock_signal <= polarity;
				bit_count <= 0;
				byte_count <= (others => '0');
				byte_flag <= '0';
			
			elsif(clk_in'event and clk_in = '1') then
				if(enable = '1' and byte_count < bytes) then
				
					clk_active <= '1';
					if (count = max-1) then
						count <= 0;
						clock_signal <= not clock_signal;
						
						if((not clock_signal) = polarity) then
							--increment bit count
							--increment byte count after 8 bits and clean bit count
							--clear byte count after numOfBytes and clear active_clk
							
							byte_flag <= '0'; -- clear the byte flag
						
							if(bit_count = 7) then
								byte_count <= std_logic_vector(unsigned(byte_count) + 1);
								bit_count <= 0;
								byte_flag <= '1'; --set byte flag for one sclk cycle
								
								if( byte_count = std_logic_vector(unsigned(bytes) - 1)) then
									--clk_active <= '0';
									--clock_signal <=  clock_signal; --do not toggle clock 
									
								end if;
							
								
							else
								bit_count <= bit_count + 1;
							end if;
							
--							if( byte_count = bytes) then
--								clk_active <= '0';
--							end if;
							
						end if;
					else
						count <= count + 1;
					end if;
				
			
				elsif(enable = '1') then
			
					clk_active <= '1';
						if (lastByteCount = max-1) then
							lastByteCount <= 0;
							clk_active <= '0';
						else
							lastByteCount <= lastByteCount + 1;
						end if;
				end if;
				
				
				
			end if;
		
		
--			if(rst = '1' or enable = '0') then
--				count <= 0;
--				lastByteCount <= 0;
--				clk_active <= '0';
--				clock_signal <= polarity;
--				bit_count <= 0;
--				byte_count <= (others => '0');
--				byte_flag <= '0';
--			
--			elsif(rising_edge(clk_in) and enable = '1' and byte_count < bytes) then
--				
--					clk_active <= '1';
--					if (count = max-1) then
--						count <= 0;
--						clock_signal <= not clock_signal;
--						
--						if((not clock_signal) = polarity) then
--							--increment bit count
--							--increment byte count after 8 bits and clean bit count
--							--clear byte count after numOfBytes and clear active_clk
--							
--							byte_flag <= '0'; -- clear the byte flag
--						
--							if(bit_count = 7) then
--								byte_count <= std_logic_vector(unsigned(byte_count) + 1);
--								bit_count <= 0;
--								byte_flag <= '1'; --set byte flag for one cycle
--								
--								if( byte_count = std_logic_vector(unsigned(bytes) - 1)) then
--									--clk_active <= '0';
--									--clock_signal <=  clock_signal; --do not toggle clock 
--									
--								end if;
--							
--								
--							else
--								bit_count <= bit_count + 1;
--							end if;
--							
----							if( byte_count = bytes) then
----								clk_active <= '0';
----							end if;
--							
--						end if;
--					else
--						count <= count + 1;
--					end if;
--				
--			
--			elsif(rising_edge(clk_in) and enable = '1') then
--			
--				clk_active <= '1';
--					if (lastByteCount = max-1) then
--						lastByteCount <= 0;
--						clk_active <= '0';
--					else
--						lastByteCount <= lastByteCount + 1;
--					end if;
--				
--				
--				
--			end if;
		--clk_out <= clock_signal;
		end process;
		
		clk_out <= clock_signal;




end bhv;