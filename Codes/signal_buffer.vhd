-- Group Member - 1. Md Sami Ul Islam Sami (UFID: 17339475)
--                2. Tasnuva Farheen (UFID:62455813)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.math_custom.all;


entity signal_buffer is
	generic (
		size_reg : positive  := 16;
		size_buff : positive := 128
	    );

	port (
		clk 		: in std_logic;
		rst 		: in std_logic;
		wr_en 		: in std_logic;
		rd_en 		: in std_logic; 
		empty 		: out std_logic;
		input_data 	: in std_logic_vector (size_reg-1 downto 0);
		output_data : out std_logic_vector ((size_reg * size_buff) - 1 downto 0);
		full 		: out std_logic
		);
end signal_buffer;

architecture BUFF of signal_buffer is
    type array_reg is array (0 to size_buff-1) of std_logic_vector(size_reg-1 downto 0);
	signal regs  : array_reg;
	signal count : std_logic_vector(clog2(size_buff) downto 0); 
	
begin
	
	process(clk, rst)
-- This process counts untill signal buffer is full. When wr_en=1 and count is less than size of signal buffer, count is incremented by 1.
-- When rd_en=1 and count is not equal to 0, count value is decremented by 1.
	variable count_s : std_logic_vector(clog2(size_buff) downto 0);
	begin
		if (rst = '1') then
			count<= (others => '0');
		elsif(rising_edge(clk)) then
			count_s := count;					
					
			if(rd_en= '1' and unsigned(count_s) /= 0) then
				count_s := std_logic_vector(unsigned(count_s) - 1);
			end if;
			
			if(wr_en= '1' and unsigned(count_s) < size_buff) then
				count_s := std_logic_vector(unsigned(count_s) + 1);
			end if;
			count <= count_s;
		end if;
	end process;
			  
	process(rst, count, rd_en)
-- In this process, the flag signals are assigned. Wehn count value is equal to buffer size and rd_en is 0, full signal is 1. when count value is less than buffer size 
-- empty signal is 1.
	variable temp : positive := size_buff;
	begin
	
		if(count =  std_logic_vector(to_unsigned(temp, clog2(size_buff)+1)) and rd_en = '0') then
			full <= '1';
		else
			full <= '0';
		end if;
		if(count < std_logic_vector(to_unsigned(temp, clog2(size_buff)+1))) then
			empty <= '1';
		else
			empty <= '0';
		end if;
		
	end process;
-- In this process, input data is written on the first register. For each rising clk edge, input data is shifted.
	process(clk, rst)
	begin
		if(rst = '1') then
			for i in 0 to size_buff-1 loop
				regs(i) <= (others => '0');
			end loop;
		elsif(rising_edge(clk)) then
			if(wr_en = '1') then
				regs(0) <= input_data;
				for i in 0 to size_buff-2 loop
					regs(i + 1) <= regs(i);
				end loop;
			end if;
		end if;
	end process;
	
	process(rst, rd_en, regs)
-- In this process, when rd_en=1 then signal buffer outputs the whole window of 128 register values.
	begin
		if(rst = '1') then
			output_data <= (others => '0');
		elsif(rd_en = '1') then
			for k in 0 to size_buff-1 loop
				output_data((size_buff-k)*size_reg - 1 downto (size_buff-1-k)*size_reg) <= regs(k);
			end loop;
		else 
			output_data <= (others => '0');
		end if;
	end process;
	
	
	
end BUFF;




