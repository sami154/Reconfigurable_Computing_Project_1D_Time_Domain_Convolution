-- Group Member - 1. Md Sami Ul Islam Sami (UFID: 17339475)
--                2. Tasnuva Farheen (UFID:62455813)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.config_pkg.all;
use work.user_pkg.all;


-- all input and output ports of address generator
entity add_generator is
	port (
		clk         : in  std_logic;
		rst         : in  std_logic;
		go          : in  std_logic;
		size		: in std_logic_vector(16 downto 0);
		clear		: in std_logic;
		stall 		: in std_logic;
		start_add 	: in std_logic_vector(14 downto 0);
		dram_ready 	: in std_logic;
		rd_en		: out std_logic;	
		rd_add     : out std_logic_vector(14 downto 0); 
		flush		: out std_logic
		);    
end add_generator;

architecture ADD_BHV of add_generator is
-- three state has been created. For two process FSMD, two address and two count registers are initialized.
  type state_type is (S_INIT, S_Delay, S_BODY);
  signal state, next_state 			: state_type;
  signal size_divby2  				: unsigned(16 downto 0);
  signal add_start, add_start1    	: std_logic_vector(14 downto 0);
  signal cnt,next_cnt       		: unsigned(16 downto 0);

begin

	process (clk, rst,clear)
	begin
	-- At reset all register value is zero and state is at initial state.
		if (rst = '1') then
			add_start   <= (others => '0');
			cnt    <=  (others => '0');
			state    <= S_INIT;
	-- At rising clock, current state is assigned with next states.	
		elsif (rising_edge(clk)) then
		if (clear = '1') then
			add_start   <= (others => '0');
			cnt    <=  (others => '0');
			state    <= S_INIT;
		else 
			add_start   <= add_start1;
			state    <= next_state;
			cnt    <= next_cnt;
		end if;
		end if;
	end process;
	
	process(add_start, state, start_add, cnt, go, stall, dram_ready, size)
	begin
		next_cnt    	<= cnt;
		next_state    	<= state;
		add_start1   	<= add_start;
		rd_add  		<= add_start;
		rd_en    		<= '0';
		flush	<= '0';
		case state is
		-- At initial state when go = 0 it will remain in S_INIT state. When go=1, state goes to S_CNT_CHECK state. In this state the size is divided by 2. 
		
			when S_INIT =>	
				add_start1 <= start_add;
				next_cnt<=(others => '0');			
				if (go = '1') then
					flush <= '1';
					next_state    	<= S_Delay;
				end if;
				
			
		-- We know ram0 is 32 bit wide but the size is associated with 16 bit. So we need to divide size by two. If size is even number, a right shift will
		-- produce size/2. If size is odd number, 1 is added with a right shift of size so that all 16 bit values can be captured. 
		
				if(size(0) = '1') then
					size_divby2  <= shift_right(unsigned(size),1) + 1;
				else 
					size_divby2  <= shift_right(unsigned(size),1);
				end if;	

			when S_Delay => 
				add_start1 <= start_add;
				next_state    	<= S_BODY;
		-- In S_BODY state, if dram is not ready for data out due to refresh time or other reason and no stall signal comes from FIFO, start address is sent to
		-- output rd_add port and address is increased by 1 at each cycle. A counter starts counting so that the counter value can be matched with the half of size.
		
			when S_BODY =>
				
				flush <= '0';
				if (dram_ready <= '1' and stall <= '0') then
					rd_en <= '1';
					next_cnt  <=cnt+1;
					add_start1 <= std_logic_vector(unsigned(add_start)+1);
					
					rd_add <= std_logic_vector(add_start);
					next_state <= S_BODY;
		-- If counter value is matched with half of size, it moves back to S_INIT state.
				elsif (unsigned(cnt) = unsigned(size_divby2)) 	then 
					next_state <= S_INIT;
				end if;
		
		
			
				
				
			when others => null;
		end case;
	end process;	

end ADD_BHV;

