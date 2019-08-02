------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library std;
	use std.textio.all;

library work;
	use work.psi_tb_txt_util.all;
	use work.psi_tb_axi_pkg.all;
	use work.definitions_pkg.all;
	use work.psi_tb_compare_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;

entity top_tb is
end entity top_tb;

architecture sim of top_tb is

	-------------------------------------------------------------------------
	-- AXI Definition
	-------------------------------------------------------------------------
	constant ID_WIDTH 		: integer 	:= 1;
	constant ADDR_WIDTH 	: integer	:= 8;
	constant USER_WIDTH		: integer	:= 1;
	constant DATA_WIDTH		: integer	:= 32;
	constant BYTE_WIDTH		: integer	:= DATA_WIDTH/8;
	
	subtype ID_RANGE is natural range ID_WIDTH-1 downto 0;
	subtype ADDR_RANGE is natural range ADDR_WIDTH-1 downto 0;
	subtype USER_RANGE is natural range USER_WIDTH-1 downto 0;
	subtype DATA_RANGE is natural range DATA_WIDTH-1 downto 0;
	subtype BYTE_RANGE is natural range BYTE_WIDTH-1 downto 0;
	
	signal axi_ms : axi_ms_r (	arid(ID_RANGE), awid(ID_RANGE),
								araddr(ADDR_RANGE), awaddr(ADDR_RANGE),
								aruser(USER_RANGE), awuser(USER_RANGE), wuser(USER_RANGE),
								wdata(DATA_RANGE),
								wstrb(BYTE_RANGE));
	
	signal axi_sm : axi_sm_r (	rid(ID_RANGE), bid(ID_RANGE),
								ruser(USER_RANGE), buser(USER_RANGE),
								rdata(DATA_RANGE));

	-------------------------------------------------------------------------
	-- TB Defnitions
	-------------------------------------------------------------------------
	constant	ClockFrequencyAxi_c	: real		:= 125.0e6;							-- Use slow clocks to speed up simulation
	constant	ClockPeriodAxi_c	: time		:= (1 sec)/ClockFrequencyAxi_c;
	constant 	SlaveCnt_c			: integer	:= 3;
	
	signal 		TbRunning			: boolean 	:= True;
	signal		SlaveTx				: std_logic_vector(7 downto 0)	:= (others => '0');
	signal		ExpectedSlaveRx		: std_logic_vector(7 downto 0)	:= (others => '0');
	signal 		SlaveNr				: integer						:= 0;

	
	-------------------------------------------------------------------------
	-- Interface Signals
	-------------------------------------------------------------------------
	signal aclk			: std_logic							:= '0';
	signal aresetn		: std_logic							:= '0';
	signal spi_sck		: std_logic							:= '0';
	signal spi_cs_n		: std_logic_vector(SlaveCnt_c-1 downto 0)		:= (others => '0');
	signal spi_mosi		: std_logic							:= '0';
	signal spi_miso		: std_logic							:= '0';
	signal irq			: std_logic							:= '0';

begin

	-------------------------------------------------------------------------
	-- DUT
	-------------------------------------------------------------------------
	i_dut : entity work.spi_vivado_wrp
		generic map
		(
			-- Component Generics
			ClockDivider_g	=> 20,
			TransWidth_g	=> 8,
			CsHighCycles_g	=> 50,
			SpiCPOL_g		=> 0,
			SpiCPHA_g		=> 0,
			SlaveCnt_g		=> SlaveCnt_c,
			LsbFirst_g		=> false,
			FifoDepth_g		=> 8,
			-- AXI
			C_S00_AXI_ID_WIDTH     	 	=> ID_WIDTH
		)
		port map
		(
			-- Clocks
			spi_sck				=> spi_sck,
			spi_cs_n			=> spi_cs_n,
			spi_mosi			=> spi_mosi,
			spi_miso 			=> spi_miso,
			irq					=> irq,
			-- Axi Slave Bus Interface
			s00_axi_aclk    	=> aclk,
			s00_axi_aresetn  	=> aresetn,
			s00_axi_arid        => axi_ms.arid,
			s00_axi_araddr      => axi_ms.araddr,
			s00_axi_arlen       => axi_ms.arlen,
			s00_axi_arsize      => axi_ms.arsize,
			s00_axi_arburst     => axi_ms.arburst,
			s00_axi_arlock      => axi_ms.arlock,
			s00_axi_arcache     => axi_ms.arcache,
			s00_axi_arprot      => axi_ms.arprot,
			s00_axi_arvalid     => axi_ms.arvalid,
			s00_axi_arready     => axi_sm.arready,
			s00_axi_rid         => axi_sm.rid,
			s00_axi_rdata       => axi_sm.rdata,
			s00_axi_rresp       => axi_sm.rresp,
			s00_axi_rlast       => axi_sm.rlast,
			s00_axi_rvalid      => axi_sm.rvalid,
			s00_axi_rready      => axi_ms.rready,
			s00_axi_awid    	=> axi_ms.awid,    
			s00_axi_awaddr      => axi_ms.awaddr,
			s00_axi_awlen       => axi_ms.awlen,
			s00_axi_awsize      => axi_ms.awsize,
			s00_axi_awburst     => axi_ms.awburst,
			s00_axi_awlock      => axi_ms.awlock,
			s00_axi_awcache     => axi_ms.awcache,
			s00_axi_awprot      => axi_ms.awprot,
			s00_axi_awvalid     => axi_ms.awvalid,
			s00_axi_awready     => axi_sm.awready,
			s00_axi_wdata       => axi_ms.wdata,
			s00_axi_wstrb       => axi_ms.wstrb,
			s00_axi_wlast       => axi_ms.wlast,
			s00_axi_wvalid      => axi_ms.wvalid,
			s00_axi_wready      => axi_sm.wready,
			s00_axi_bid         => axi_sm.bid,
			s00_axi_bresp       => axi_sm.bresp,
			s00_axi_bvalid      => axi_sm.bvalid,
			s00_axi_bready      => axi_ms.bready			
		);
	
	-------------------------------------------------------------------------
	-- Clock
	-------------------------------------------------------------------------
	p_aclk : process
	begin
		aclk <= '0';
		while TbRunning loop
			wait for 0.5*ClockPeriodAxi_c;
			aclk <= '1';
			wait for 0.5*ClockPeriodAxi_c;
			aclk <= '0';
		end loop;
		wait;
	end process;
	
	-------------------------------------------------------------------------
	-- TB Control
	-------------------------------------------------------------------------
	p_control : process
		variable Readback_v	: integer;
		variable ReadbackSlv_v : std_logic_vector(31 downto 0);
	begin
		-- Reset
		aresetn <= '0';
		wait for 1 us;
		wait until rising_edge(aclk);
		aresetn <= '1';
		wait for 1 us;
		wait until rising_edge(aclk);
		
		-- *** Write Only Transaction ***
		SlaveNr <= 1;
		axi_single_write(RegIdx_SlaveNr_c*4, 1, axi_ms, axi_sm, aclk);		
		ExpectedSlaveRx <= X"AB";
		axi_single_write(RegIdx_StoreRx_c*4, 0, axi_ms, axi_sm, aclk);
		axi_single_write(RegIdx_Data_c*4, 16#AB#, axi_ms, axi_sm, aclk);		
		wait for 100 ns;
		wait until rising_edge(aclk);
		Readback_v := 1;
		while Readback_v /= 0 loop
			axi_single_read(RegIdx_Status_c*4, Readback_v, axi_ms, axi_sm, aclk,BitIdx_Status_Busy_c, BitIdx_Status_Busy_c);
		end loop;
		
		-- *** Write/Read Transaction ***
		SlaveNr <= 0;
		axi_single_write(RegIdx_SlaveNr_c*4, 0, axi_ms, axi_sm, aclk);		
		ExpectedSlaveRx <= X"12";
		SlaveTx <= X"34";
		axi_single_write(RegIdx_StoreRx_c*4, 1, axi_ms, axi_sm, aclk);
		axi_single_write(RegIdx_Data_c*4, 16#12#, axi_ms, axi_sm, aclk);		
		wait for 20 ns;
		wait until rising_edge(aclk);
		Readback_v := 1;
		while Readback_v /= 0 loop
			axi_single_read(RegIdx_Status_c*4, Readback_v, axi_ms, axi_sm, aclk,BitIdx_Status_Busy_c, BitIdx_Status_Busy_c);
		end loop;	
		axi_single_expect(RegIdx_Data_c*4, 16#34#, axi_ms, axi_sm, aclk, "Wrong Read Data", 7, 0); 
		
		-- *** Fill FIFO and check status, IRQ on every transfer ***
		-- Setup IRQ on every transfer
		wait until rising_edge(aclk);
		wait until rising_edge(aclk);
		wait until rising_edge(aclk);
		axi_single_write(RegIdx_IrqVec_c*4, 16#FF#, axi_ms, axi_sm, aclk);	
		axi_single_write(RegIdx_IrqEna_c*4, 2**Irq_TfDone_c, axi_ms, axi_sm, aclk);
		axi_single_write(RegIdx_TxAlmEmptyLevel_c*4, 3, axi_ms, axi_sm, aclk);
		axi_single_write(RegIdx_RxAlmFullLevel_c*4, 2, axi_ms, axi_sm, aclk);
		-- Setup Transfers
		SlaveNr <= 0;
		axi_single_write(RegIdx_SlaveNr_c*4, 0, axi_ms, axi_sm, aclk);
		SlaveTx <= std_logic_vector(to_unsigned(16#11#, 8));
		ExpectedSlaveRx <= std_logic_vector(to_unsigned(16#01#, 8));
		for i in 1 to 9 loop						
			-- read/write only for every second transaction
			axi_single_write(RegIdx_StoreRx_c*4, i mod 2, axi_ms, axi_sm, aclk);
			axi_single_write(RegIdx_Data_c*4, i, axi_ms, axi_sm, aclk);	
		end loop;
		axi_single_write(RegIdx_IrqVec_c*4, 16#FF#, axi_ms, axi_sm, aclk);
		-- Do Checks
		for i in 1 to 9 loop
			-- Status before TF Done
			axi_single_expect(RegIdx_RxLevel_c*4, i/2, axi_ms, axi_sm, aclk, "RxLevel before", 7, 0); 
			axi_single_expect(RegIdx_TxLevel_c*4, 9-i, axi_ms, axi_sm, aclk, "TxLevel before", 7, 0); 
			axi_single_read(RegIdx_Status_c*4, Readback_v, axi_ms, axi_sm, aclk, 7, 0);
			ReadbackSlv_v := std_logic_vector(to_signed(Readback_v, 32));
			StdlCompare(choose(i=9, 1, 0), ReadbackSlv_v(BitIdx_Status_TxEmpty_c), "TxEmpty not correct before " & to_string(i));
			StdlCompare(choose(i=1, 1, 0), ReadbackSlv_v(BitIdx_Status_TxFull_c), "TxFull not correct before " & to_string(i));
			StdlCompare(choose(i>=9-3, 1, 0), ReadbackSlv_v(BitIdx_Status_TxAlmEmpty_c), "TxAlmEmpty not correct before " & to_string(i));
			StdlCompare(1, ReadbackSlv_v(BitIdx_Status_Busy_c), "Busy not correct before " & to_string(i));
			StdlCompare(0, ReadbackSlv_v(BitIdx_Status_RxFull_c), "RxFull not correct before " & to_string(i));
			StdlCompare(choose(i>=4, 1, 0), ReadbackSlv_v(BitIdx_Status_RxAlmFull_c), "RxAlmFull not correct before " & to_string(i));
			StdlCompare(choose(i=1, 1, 0), ReadbackSlv_v(BitIdx_Status_RxEmpty_c), "RxEmpty not correct before " & to_string(i));
			axi_single_read(RegIdx_IrqVec_c*4, Readback_v, axi_ms, axi_sm, aclk, 7, 0);
			ReadbackSlv_v := std_logic_vector(to_signed(Readback_v, 32));		
			StdlCompare(choose(i=9, 1, 0), ReadbackSlv_v(Irq_TxEmpty_c), "Vec TxEmpty not correct before " & to_string(i)); 
			StdlCompare(choose(i>=9-3, 1, 0), ReadbackSlv_v(Irq_TxAlmEmpty_c), "Vec TxAlmEmpty not correct before " & to_string(i));
			StdlCompare(choose(i>=4, 1, 0), ReadbackSlv_v(Irq_RxAlmFull_c), "Vec RxAlmFull not correct before " & to_string(i));			
			-- Expectations for next transfer
			ExpectedSlaveRx <= std_logic_vector(to_unsigned(16#01#+i, 8));
			SlaveTx <= std_logic_vector(to_unsigned(16#11#+i, 8));			
			-- Wait for TF done
			wait until rising_edge(aclk) and irq = '1';
			axi_single_write(RegIdx_IrqVec_c*4, 16#FF#, axi_ms, axi_sm, aclk);	
			wait for 20 ns;
			wait until rising_edge(aclk); 			
			-- Status after TF Done
			axi_single_expect(RegIdx_RxLevel_c*4, (i+1)/2, axi_ms, axi_sm, aclk, "RxLevel after", 7, 0); 
			axi_single_expect(RegIdx_TxLevel_c*4, max(9-i-1, 0), axi_ms, axi_sm, aclk, "TxLevel after", 7, 0);
			axi_single_read(RegIdx_Status_c*4, Readback_v, axi_ms, axi_sm, aclk, 7, 0);
			ReadbackSlv_v := std_logic_vector(to_signed(Readback_v, 32));
			StdlCompare(choose(i>=8, 1, 0), ReadbackSlv_v(BitIdx_Status_TxEmpty_c), "TxEmpty not correct after " & to_string(i));
			StdlCompare(0, ReadbackSlv_v(BitIdx_Status_TxFull_c), "TxFull not correct after " & to_string(i));
			StdlCompare(choose(i>=8-3, 1, 0), ReadbackSlv_v(BitIdx_Status_TxAlmEmpty_c), "TxAlmEmpty not correct after " & to_string(i));
			StdlCompare(choose(i=9, 0, 1), ReadbackSlv_v(BitIdx_Status_Busy_c), "Busy not correct after " & to_string(i));
			StdlCompare(0, ReadbackSlv_v(BitIdx_Status_RxFull_c), "RxFull not correct after " & to_string(i));
			StdlCompare(choose(i>=3, 1, 0), ReadbackSlv_v(BitIdx_Status_RxAlmFull_c), "RxAlmFull not correct after " & to_string(i));
			StdlCompare(0, ReadbackSlv_v(BitIdx_Status_RxEmpty_c), "RxEmpty not correct after " & to_string(i));
			axi_single_read(RegIdx_IrqVec_c*4, Readback_v, axi_ms, axi_sm, aclk, 7, 0);
			ReadbackSlv_v := std_logic_vector(to_signed(Readback_v, 32));	
			StdlCompare(choose(i>=8, 1, 0), ReadbackSlv_v(Irq_TxEmpty_c), "Vec TxEmpty not correct after " & to_string(i));
			StdlCompare(choose(i>=8-3, 1, 0), ReadbackSlv_v(Irq_TxAlmEmpty_c), "Vec TxAlmEmpty not correct after " & to_string(i));
			StdlCompare(choose(i>=3, 1, 0), ReadbackSlv_v(Irq_RxAlmFull_c), "Vec RxAlmFull not correct after " & to_string(i));			
		end loop;		
		-- Check RX Data
		axi_single_expect(RegIdx_Data_c*4, 16#11#, axi_ms, axi_sm, aclk, "Wrong Read Data", 7, 0); 
		axi_single_expect(RegIdx_Data_c*4, 16#13#, axi_ms, axi_sm, aclk, "Wrong Read Data", 7, 0); 
		axi_single_expect(RegIdx_Data_c*4, 16#15#, axi_ms, axi_sm, aclk, "Wrong Read Data", 7, 0); 
		axi_single_expect(RegIdx_Data_c*4, 16#17#, axi_ms, axi_sm, aclk, "Wrong Read Data", 7, 0); 
		axi_single_expect(RegIdx_Data_c*4, 16#19#, axi_ms, axi_sm, aclk, "Wrong Read Data", 7, 0); 
		
		-- *** Test RX Full ***
		SlaveNr <= 0;
		axi_single_write(RegIdx_SlaveNr_c*4, 0, axi_ms, axi_sm, aclk);		
		ExpectedSlaveRx <= X"12";
		SlaveTx <= X"34";
		axi_single_write(RegIdx_StoreRx_c*4, 1, axi_ms, axi_sm, aclk);
		for i in 0 to 7 loop
			axi_single_write(RegIdx_Data_c*4, 16#12#, axi_ms, axi_sm, aclk);		
		end loop;
		wait for 20 ns;
		wait until rising_edge(aclk);
		Readback_v := 1;
		while Readback_v /= 0 loop
			axi_single_read(RegIdx_Status_c*4, Readback_v, axi_ms, axi_sm, aclk,BitIdx_Status_Busy_c, BitIdx_Status_Busy_c);
		end loop;
		axi_single_expect(RegIdx_IrqVec_c*4, 1, axi_ms, axi_sm, aclk, "RX full IRQ not set", Irq_RxFull_c, Irq_RxFull_c); 	
		axi_single_expect(RegIdx_Status_c*4, 1, axi_ms, axi_sm, aclk, "RX full status not set", BitIdx_Status_RxFull_c, BitIdx_Status_RxFull_c); 
		axi_single_expect(RegIdx_Data_c*4, 16#34#, axi_ms, axi_sm, aclk, "Wrong Read Data", 7, 0); 
		axi_single_expect(RegIdx_IrqVec_c*4, 1, axi_ms, axi_sm, aclk, "RX full IRQ not set after read", Irq_RxFull_c, Irq_RxFull_c); 	
		axi_single_write(RegIdx_IrqVec_c*4, 2**Irq_RxFull_c, axi_ms, axi_sm, aclk);
		axi_single_expect(RegIdx_IrqVec_c*4, 0, axi_ms, axi_sm, aclk, "RX full IRQ not cleared", Irq_RxFull_c, Irq_RxFull_c); 
		axi_single_expect(RegIdx_Status_c*4, 0, axi_ms, axi_sm, aclk, "RX full status not cleared", BitIdx_Status_RxFull_c, BitIdx_Status_RxFull_c); 	
		for i in 1 to 7 loop
			axi_single_expect(RegIdx_Data_c*4, 16#34#, axi_ms, axi_sm, aclk, "Wrong Read Data", 7, 0); 		
		end loop;
		
		-- *** Test IRQ clearing ***
		-- Individual clearing of bits
		axi_single_expect(RegIdx_IrqVec_c*4, 16#17#, axi_ms, axi_sm, aclk, "IRQ Vec has unexpected value before clearing", 7, 0); 
		axi_single_write(RegIdx_IrqVec_c*4, 16#0C#, axi_ms, axi_sm, aclk);
		axi_single_expect(RegIdx_IrqVec_c*4, 16#13#, axi_ms, axi_sm, aclk, "IRQ Vec has unexpected value after clearing", 7, 0); 
		-- IRQs whoes condition is still valid are reset
		axi_single_write(RegIdx_IrqVec_c*4, 16#02#, axi_ms, axi_sm, aclk);
		axi_single_expect(RegIdx_IrqVec_c*4, 16#13#, axi_ms, axi_sm, aclk, "IRQ Vec has unexpected value after autoreset", 7, 0); 
		
		-- TB done
		TbRunning <= false;
		wait;
	end process;
	
	-------------------------------------------------------------------------
	-- SPI Emulation
	-------------------------------------------------------------------------
	p_spi : process
		constant TransWidth_c 	: integer := 8;
		constant SpiCPHA_c		: integer := 0;
		constant SpiCPOL_c		: integer := 0;
		constant LsbFirst_c		: boolean := false;
		variable ShiftRegRx_v 	: std_logic_vector(TransWidth_c-1 downto 0);
		variable ShiftRegTx_v 	: std_logic_vector(TransWidth_c-1 downto 0);
		variable ExpLatch_v		: std_logic_vector(TransWidth_c-1 downto 0);
	begin	
		wait until aresetn = '1';
		wait until rising_edge(aclk);
		
		while TbRunning loop
			-- If start of transfer
			if spi_cs_n /= OnesVector(SlaveCnt_c) then
				ShiftRegTx_v := SlaveTx;
				ShiftRegRx_v := (others => 'U');
				ExpLatch_v := ExpectedSlaveRx;
				
				-- Check correct slave
				for s in 0 to SlaveCnt_c-1 loop
					if s = SlaveNr then
						StdlCompare(0, spi_cs_n(s), "Slave " & to_string(s) & " not selected");
					else
						StdlCompare(1, spi_cs_n(s), "Slave " & to_string(s) & " selected wrongly");
					end if;
				end loop;
				
				-- loop over bits
				for i in 0 to TransWidth_c-1 loop
					-- Wait for apply edge 
					if (SpiCPHA_c = 1) and (i /= TransWidth_c-1) then	
						if SpiCPOL_c = 0 then
							wait until rising_edge(spi_sck);
						else
							wait until falling_edge(spi_sck);
						end if;
					elsif (SpiCPHA_c = 0) and (i /= 0) then	
						if SpiCPOL_c = 0 then
							wait until falling_edge(spi_sck);
						else
							wait until rising_edge(spi_sck);
						end if;					
					end if;
					-- Shift TX
					if LsbFirst_c then
						spi_miso <= ShiftRegTx_v(0);
						ShiftRegTx_v := 'U' & ShiftRegTx_v(TransWidth_c-1 downto 1);
					else
						spi_miso <= ShiftRegTx_v(TransWidth_c-1);
						ShiftRegTx_v := ShiftRegTx_v(TransWidth_c-2 downto 0) & 'U';
					end if;					
					-- Wait for transfer edge
					if ((SpiCPOL_c = 0) and (SpiCPHA_c = 0)) or
					   ((SpiCPOL_c = 1) and (SpiCPHA_c = 1)) then
					    wait until rising_edge(spi_sck);
					else
						wait until falling_edge(spi_sck);
					end if;
					-- Shift RX
					if LsbFirst_c then
						ShiftRegRx_v := spi_mosi & ShiftRegRx_v(TransWidth_c-1 downto 1);
					else
						ShiftRegRx_v := ShiftRegRx_v(TransWidth_c-2 downto 0) & spi_mosi;
					end if;
				end loop;
				
				-- wait fir CS going high
				wait until spi_cs_n = OnesVector(SlaveCnt_c);
				StdlvCompareStdlv (ExpLatch_v, ShiftRegRx_v, "SPI slave received wrong data");
			else
				wait until rising_edge(aclk);
			end if;
		end loop;	
		wait;
	end process;
	
	

end sim;
