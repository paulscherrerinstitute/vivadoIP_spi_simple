------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler, Radoslaw Rybaniec
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple SPI-master.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library work;
	use work.psi_common_math_pkg.all;
	use work.definitions_pkg.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity spi_simple is
	generic (
		ClockDivider_g	: natural range 4 to 1_000_000;		
		TransWidth_g	: positive;							
		CsHighCycles_g	: positive;							
		SpiCPOL_g		: natural range 0 to 1;				
		SpiCPHA_g		: natural range 0 to 1;				
		SlaveCnt_g		: positive := 1;					
		LsbFirst_g		: boolean := false;
		FifoDepth_g		: positive	:= 256;
		MosiIdleState_g : std_logic := '0';
	  ReadBitPol_g     : std_logic := '1';        
    TriStatePol_g    : std_logic := '1'; 
    SpiDataPos_g     : positive := 3         
	);
	port (
		-- Control Signals
		Clk			: in	std_logic;	
		Rst			: in	std_logic;	
		

		-- Config Interface
		CfgSlave		: in	std_logic_vector(log2ceil(SlaveCnt_g)-1 downto 0);
		CfgStoreRx		: in	std_logic;
		CfgTxAlmEmpty	: in 	std_logic_vector(log2ceil(FifoDepth_g) downto 0);
		CfgRxAlmFull	: in	std_logic_vector(log2ceil(FifoDepth_g) downto 0);
		
		-- IRQ Interface
		CfgIrqClr		: in	Irq_t;
		CfgIrqClrVld	: in	std_logic;
		CfgIrqVec		: out	Irq_t;
		CfgIrqEna		: in 	Irq_t;
		Irq				: out	std_logic;
		
		-- Status Interface
		Status			: out	Status_t;
		
		-- Fifo Interface
		RxData		: out	std_logic_vector(TransWidth_g-1 downto 0);
		RxAck		: in	std_logic;
		RxLevel		: out	std_logic_vector(log2ceil(FifoDepth_g) downto 0);
		TxData		: in	std_logic_vector(TransWidth_g-1 downto 0);
		TxWrite		: in	std_logic;
		TxLevel		: out	std_logic_vector(log2ceil(FifoDepth_g) downto 0);			
		
		-- SPI 
		SpiSck		: out	std_logic;
		SpiMosi		: out	std_logic;
		SpiMiso		: in 	std_logic;
    SpiTri    : out std_logic;
		SpiCs_n		: out	std_logic_vector(SlaveCnt_g-1 downto 0);
    SpiLe		  : out	std_logic_vector(SlaveCnt_g-1 downto 0)		
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of spi_simple is	

	-- *** Constants ***
	constant Cmd_StoreRx	: integer		:= 	0;
	subtype Cmd_Slave 		is natural range 	Cmd_StoreRx+log2ceil(SlaveCnt_g) downto Cmd_StoreRx+1;
	subtype Cmd_Data 		is natural range 	Cmd_Slave'high+TransWidth_g downto Cmd_Slave'high+1;

	-- *** Component Connection Signals ***
	signal SpiDone		: std_logic;
	signal SpiRxData	: std_logic_vector(TransWidth_g-1 downto 0);
	signal CmdIn		: std_logic_vector(Cmd_Data'high downto 0);
	signal CmdOut		: std_logic_vector(Cmd_Data'high downto 0);
	signal CmdSlave		: std_logic_vector(log2ceil(SlaveCnt_g)-1 downto 0);
	signal CmdData		: std_logic_vector(TransWidth_g-1 downto 0);
	signal CmdStoreRx	: std_logic;
	signal SpiBusy		: std_logic;
	signal TxLevel_I	: std_logic_vector(log2ceil(FifoDepth_g) downto 0);	
	signal TxEmpty		: std_logic;
	signal TxFull		: std_logic;
	signal RxFull		: std_logic;
	signal RxEmpty		: std_logic;
	signal RxLevel_I	: std_logic_vector(log2ceil(FifoDepth_g) downto 0);	
	
	
	-- *** Two Process Method ***
	type two_process_r is record
		SpiStart		: std_logic;
		StoreRx			: std_logic;
		RxWrite			: std_logic;
		IrqVec			: Irq_t;
		Irq				: std_logic;
		Status			: Status_t;
	end record;
	signal r, r_next : two_process_r;	
	
begin

	--------------------------------------------------------------------------
	-- Combinatorial Proccess
	--------------------------------------------------------------------------
	p_comb : process(r, SpiBusy, TxEmpty, CmdStoreRx, SpiDone, CfgIrqClr, CfgIrqClrVld, CfgTxAlmEmpty, TxLevel_I, RxFull, RxLevel_I, CfgRxAlmFull, CfgIrqEna, TxFull, RxEmpty)
		variable v : two_process_r;
	begin
		-- *** hold variables stable ***
		v := r;
		
		-- *** SPI Transaction Start ***
		v.SpiStart := '0';
		if (SpiBusy = '0') and (TxEmpty = '0') and (r.SpiStart = '0') then
			v.SpiStart := '1';
			v.StoreRx := CmdStoreRx;
		end if;
		
		-- *** Control RX data storage ***
		v.RxWrite := r.StoreRx and SpiDone;
		
		-- *** IRQ Vector and Status Handling ***
		v.Status := (others => '0');
		-- clearing
		if CfgIrqClrVld = '1' then
			v.IrqVec := r.IrqVec and not CfgIrqClr;
		end if;
		-- latching
		if TxEmpty = '1' then
			v.IrqVec(Irq_TxEmpty_c) := '1';
			v.Status(BitIdx_Status_TxEmpty_c) := '1';
		end if;
		if TxFull = '1' then
			v.Status(BitIdx_Status_TxFull_c) := '1';
		end if;
		if unsigned(TxLevel_I) <= unsigned(CfgTxAlmEmpty) then
			v.IrqVec(Irq_TxAlmEmpty_c) := '1';
			v.Status(BitIdx_Status_TxAlmEmpty_c) := '1';
		end if;
		if SpiDone = '1' then
			v.IrqVec(Irq_TfDone_c)	:= '1';
		end if;
		if RxFull = '1' then
			v.IrqVec(Irq_RxFull_c)	:= '1';
			v.Status(BitIdx_Status_RxFull_c) := '1';
		end if;
		if RxEmpty = '1' then
			v.Status(BitIdx_Status_RxEmpty_c) := '1';
		end if;
		if unsigned(RxLevel_I) >= unsigned(CfgRxAlmFull) then
			v.IrqVec(Irq_RxAlmFull_c) := '1';
			v.Status(BitIdx_Status_RxAlmFull_c) := '1';
		end if;
		
		-- *** IRQ Generation ***
		if unsigned(r.IrqVec and CfgIrqEna) /= 0 then
			v.Irq := '1';
		else
			v.Irq := '0';
		end if;		
		
		-- *** Busy Generation ***
		if (TxEmpty = '0') or (SpiBusy = '1') then
			v.Status(BitIdx_Status_Busy_c) := '1';
		else
			v.Status(BitIdx_Status_Busy_c) := '0';
		end if;
		
		-- *** assign signal ***
		r_next <= v;
	end process;
	
	--------------------------------------------------------------------------
	-- Outputs
	--------------------------------------------------------------------------
	CfgIrqVec 	<= r.IrqVec;
	Irq			<= r.Irq;
	RxLevel		<= RxLevel_I;
	TxLevel		<= TxLevel_I;	
	Status		<= r.Status;
	
	--------------------------------------------------------------------------
	-- Sequential Proccess
	--------------------------------------------------------------------------
	p_seq : process(Clk)
	begin
		if rising_edge(Clk) then
			r <= r_next;
			if Rst = '1' then
				r.SpiStart	<= '0';
				r.RxWrite	<= '0';
				r.IrqVec	<= (others => '0');
				r.Irq		<= '0';
			end if;			
		end if;
	end process;
	
	--------------------------------------------------------------------------
	-- Component Instantiations
	--------------------------------------------------------------------------	
	
	-- *** Command FIFO ***
	CmdIn(Cmd_StoreRx)	<= CfgStoreRx;
	CmdIn(Cmd_Slave)	<= CfgSlave;
	CmdIn(Cmd_Data)		<= TxData;
	
	i_tx_fifo : entity work.psi_common_sync_fifo
		generic map (
			width_g			=> CmdIn'length,
			depth_g			=> FifoDepth_g,
			ram_style_g		=> "auto",
			ram_behavior_g	=> "RBW"
		)
		port map (
			clk_i			=> Clk,
			rst_i			=> Rst,
			dat_i		=> CmdIn,
			vld_i		=> TxWrite,
			dat_o		=> CmdOut,
			rdy_i		=> r.SpiStart,
			empty_o		=> TxEmpty,
			full_o		=> TxFull,
			out_level_o	=> TxLevel_I
		);
		
	CmdSlave <= CmdOut(Cmd_Slave);
	CmdData <= CmdOut(Cmd_Data);
	CmdStoreRx <= CmdOut(Cmd_StoreRx);
	
	
	-- *** Response FIFO ***
	i_resp_fifo : entity work.psi_common_sync_fifo
		generic map (
			width_g			=> TransWidth_g,
			depth_g			=> FifoDepth_g,
			ram_style_g		=> "auto",
			ram_behavior_g	=> "RBW"
		)
		port map (
			clk_i			=> Clk,
			rst_i			=> Rst,
			dat_i		=> SpiRxData,
			vld_i		=> r.RxWrite,
			dat_o		=> RxData,
			rdy_i		=> RxAck,
			full_o		=> RxFull,
			empty_o		=> RxEmpty,
			in_level_o		=> RxLevel_I
		);
	
	-- *** SPI Interface ***
	i_spi : entity work.psi_common_spi_master
		generic map (
			clk_div_g 	=> ClockDivider_g,
			trans_width_g	=> TransWidth_g,
			cs_high_cycles_g	=> CsHighCycles_g,
			spi_cpol_g		=> SpiCPOL_g,
			spi_cpha_g		=> SpiCPHA_g,
			slave_cnt_g		=> SlaveCnt_g,
			lsb_first_g		=> LsbFirst_g,
			read_bit_pol_g      => ReadBitPol_g,
      tri_state_pol_g     => TriStatePol_g,
      spi_data_pos_g      => SpiDataPos_g,
			mosi_idle_state_g   => MosiIdleState_g
		)
		port map (
			clk_i			=> Clk,
			rst_i			=> Rst,
			start_i		=> r.SpiStart,
			slave_i		=> CmdSlave,
			busy_o		=> SpiBusy,
			done_o		=> SpiDone,
			dat_i		=> CmdData,
			dat_o		=> SpiRxData,
			spi_sck_o		=> SpiSck,
			spi_mosi_o		=> SpiMosi,
			spi_miso_i		=> SpiMiso,
      spi_tri_o        => SpiTri,
			spi_cs_n_o		=> SpiCs_n
		);
	
	
end;





