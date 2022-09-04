-- Group Member - 1. Md Sami Ul Islam Sami (UFID: 17339475)
--                2. Tasnuva Farheen (UFID:62455813)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.config_pkg.all;
use work.user_pkg.all;

entity counter is

	port (
		clk: in std_logic;
		rst : in std_logic;
		rd_en : in std_logic;
		valid : in std_logic;
		size : in std_logic_vector (16 downto 0);
		done : out std_logic;
		clear : in std_logic
	);
	
end counter;
-- This counter will count when rd_en from user_app is 1 and counts equal to size. If valid is 1 and re_en is 1 then it will check if the count is equal to size.
-- If count = size then it will generate done signal equal to 1 and count value is reset to 0 other wise it continues counting.
architecture CNT of counter is
begin
	
	process (clk, rst)
	
	variable cnt : std_logic_vector (16 downto 0);
	begin	
	done <= '0';
		if (rst = '1') then
			cnt := (others => '0');
			done <= '0';
		elsif (rising_edge(clk)) then
			if (clear = '1') then
				cnt := (others => '0');
				done <= '0';
			
			elsif (rd_en = '1' and valid = '1') then
				if (cnt = size) then
					cnt := (others => '0');
					done <= '1';
				else 
					cnt := std_logic_vector(unsigned(cnt) + 1);
				end if;
			end if;
		end if;
		
	end process;
end CNT;
				