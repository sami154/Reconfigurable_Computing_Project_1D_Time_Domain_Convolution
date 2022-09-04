-- Group Member - 1. Md Sami Ul Islam Sami (UFID: 17339475)
--                2. Tasnuva Farheen (UFID:62455813)


-- This entity is the top level entity for ram0 read. 

library ieee;
use ieee.std_logic_1164.all;
use work.config_pkg.all;
use work.user_pkg.all;

  
entity dram_ram0_read is

port(
	
	 dram_clk   : in  std_logic;
	 user_clk   : in  std_logic;
	 rst        : in  std_logic;
	 clear      : in  std_logic;
	 go         : in  std_logic;
	 rd_en      : in  std_logic;
	 stall      : in  std_logic;
	 start_addr : in  std_logic_vector(14 downto 0);
	 size       : in  std_logic_vector(16 downto 0);
	 valid      : out std_logic;
	 data       : out std_logic_vector(15 downto 0);
	 done       : out std_logic;
	 dram_ready    : in  std_logic;
	 dram_rd_en    : out std_logic;
	 dram_rd_addr  : out std_logic_vector(14 downto 0);
	 dram_rd_data  : in  std_logic_vector(31 downto 0);
	 dram_rd_valid : in  std_logic;
	 dram_rd_flush : out std_logic
	 );
	 
end dram_ram0_read;

architecture top_rd of dram_ram0_read is

	signal size_en : std_logic;
	signal addr_en : std_logic;
	signal go_handshake : std_logic;
	signal rcv_handshake : std_logic;
	signal reg_en_d : std_logic;
	signal size_out_s : std_logic_vector(16 downto 0);
	signal addr_out_s : std_logic_vector(14 downto 0);
	signal full_prog : std_logic ;
	signal clear_s : std_logic;
	signal size_dram_out : std_logic_vector(16 downto 0);
	signal addr_dram_out : std_logic_vector(14 downto 0);
	signal valid_s : std_logic;
	signal temp_data : std_logic_vector(31 downto 0);
	signal not_empty : std_logic;
	signal full : std_logic;
begin


	U_REG_SIZE_SRC : entity work.reg 
		generic map ( 
			width => 17 )
		port map(
			clk => user_clk,
			rst => rst,
			en => size_en,
			input => size,
			output => size_out_s
			);
    

	U_REG_ADDR_SRC : entity work.reg 
		generic map ( 
			width => 15 )
		port map(
			clk => user_clk,
			rst => rst,
			en => addr_en,
			input => start_addr,
			output => addr_out_s
			);

	U_HND: entity work.handshake
		port map (
			clk_src   => user_clk,
			clk_dest  => dram_clk,
			rst       => rst,
			go        => go_handshake,
			delay_ack => '0',
			rcv       => reg_en_d,
			ack       => rcv_handshake
			);
		
		
	U_REG_SIZE_DES : entity work.reg 
		generic map ( 
			width => 17 )
		port map(
			clk => dram_clk,
			rst => rst,
			en => reg_en_d,
			input => size_out_s,
			output => size_dram_out
			);
 
	U_REG_ADDR_DES : entity work.reg 
		generic map ( 
			width => 15 )
		port map(
			clk => dram_clk,
			rst => rst,
			en => reg_en_d,
			input => addr_out_s,
			output =>addr_dram_out
			);

	U_ADDR_GEN: entity work.add_generator
		port map(
			go => reg_en_d,
			clk => dram_clk,
			rst => rst,
			clear => clear_s, 
			size => size_dram_out,
			start_add => addr_dram_out,
			dram_ready => dram_ready,
			rd_en => dram_rd_en,
			rd_add => dram_rd_addr,
			flush => dram_rd_flush,
			stall => full_prog
			);	

	U_CONTRL : entity work.add_ctrl
		port map(
			go => go,
			user_clk => user_clk,
			rst => rst,
			clear => clear,
			size_en => size_en,
			addr_en => addr_en,
			send_h => go_handshake,
			ack => rcv_handshake
			); 
 
 --changing first 16 bit to MSB and last 16 bit to LSB for FIFO output match with our desired order
		temp_data <=  dram_rd_data(15 downto 0) & dram_rd_data(31 downto 16);
		
	U_FIFO: entity work.fifo_generator_0
		port map( 
			rst => rst,
			wr_clk => dram_clk,
			rd_clk => user_clk,
			din => temp_data,
			wr_en => dram_rd_valid,
			rd_en => rd_en,
			dout => data,
			empty => valid_s,
			prog_full => full_prog,
			full => full
			);

	 valid <= not valid_s;
  
	U_CNT: entity work.counter
		port map(
			clk  => user_clk,
			rst  => rst,
			rd_en=> rd_en,
			size => size_out_s,
			valid => not_empty,
			done => done,
			clear => '0'
			);
 
	not_empty <= not valid_s;
 
 end top_rd;