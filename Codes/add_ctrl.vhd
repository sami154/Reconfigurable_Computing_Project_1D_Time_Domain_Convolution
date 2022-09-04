-- Group Member - 1. Md Sami Ul Islam Sami (UFID: 17339475)
--                2. Tasnuva Farheen (UFID:62455813)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- This module is for controlling the registers of size and address signals and also the register of Address generator through handshake.
-- After go=1, the FSM goes to S_En_Reg state where size and start address register enable signal gets '1' and go signal of handshake gets '1'.
-- After that FSM goes to S_H_ack state where the register enable signals are turned off but when it receives ack signal from handshake, FSM goes to Done state.
-- ACK signal makes sure that after acknowledged from the destination clock domain, next size and start address can be captured safely.

entity add_ctrl is

port(
	go  : in std_logic;
	user_clk : in std_logic;
	rst : in std_logic; 
	clear : in std_logic;
	size_en : out std_logic;
	send_h : out std_logic;
	ack : in std_logic; 
	addr_en : out std_logic
);

end add_ctrl;

architecture BHV of add_ctrl is


type state_type is (S_Init, HND_S,S_H_ack, S_En_Reg, S_Done);
signal state, next_state : state_type;


begin 

process(user_clk, rst,clear)

begin

	if(rst = '1')then
		state <= S_Init;

	elsif(rising_edge(user_clk))then
		if(clear = '1')then
			state <= S_Init;
		else
			state <= next_state;

		end if;
	end if;
end process;

process(state, go, ack)

begin
	next_state <= state;

 
	case state is 

		when S_Init =>
-- When go=1 FSM goes to S_En_Reg state.
			if(go = '1')then
				next_state <= S_En_Reg;
			end if;
	
		when S_En_Reg =>
-- At S_En_Reg state, size register enable, address register enable, handshake bit is set to 1. FSM goes to S_H_ack state.	

			size_en <='1';
			addr_en <='1';
			send_h <='1';
			next_state <= S_H_ack;

		when S_H_ack =>
-- At S_H_ack state , size register enable, address register enable, handshake bit is set to 0. If ack signal is 1 then FSM goes to S_Done state.	
			size_en <='0';
			addr_en <='0';
			send_h <='0';
	 
			if(ack = '1')then
				next_state <= S_Done;
			end if;
	
		when S_Done	=>
-- At S_Done state , if go= 0, FSM goes back to initial state.	
			if(go = '0') then	
				next_state <= S_Init;
			end if;

		when others => null;	
	end case;
end process;


end  BHV;