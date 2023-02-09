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

library work;
	use work.psi_common_math_pkg.all;
	use work.psi_common_array_pkg.all;
	use work.definitions_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
entity spi_vivado_wrp is
	generic
	(	
		-- SPI Parameters
		ClockDivider_g	: natural range 4 to 1_000_000 	:= 4;		-- Must be a multiple of two	
		TransWidth_g	: positive					   	:= 32;		-- SPI Transaction width
		CsHighCycles_g	: positive					   	:= 20;		-- Minumum chip-select high-time between two transfers in clock-cycles
		SpiCPOL_g		: natural range 0 to 1		   	:= 0;		-- SPI clock polarity (0 = idle low, 1 = idle high)
		SpiCPHA_g		: natural range 0 to 1			:= 0;		-- SPI sample configuration (0 sample on leading edge, 1 sample on trailing edge)
		SlaveCnt_g		: positive 						:= 1;		-- Number of slaves to support
		LsbFirst_g		: boolean 						:= false;	-- LSB or MSB first transmission	
		FifoDepth_g		: positive						:= 256;		-- Depth of RX/TX FIFOs
		
		-- AXI Parameters
		C_S00_AXI_ID_WIDTH          : integer := 1					-- Width of ID for for write address, write data, read address and read data
	);
	port
	(
		-----------------------------------------------------------------------------
		-- SPI Ports
		-----------------------------------------------------------------------------
		spi_sck						: out	std_logic;
		spi_cs_n					: out	std_logic_vector(SlaveCnt_g-1 downto 0);
		spi_mosi					: out 	std_logic;
		spi_miso 					: in 	std_logic;
		spi_le	 					: out	std_logic_vector(SlaveCnt_g-1 downto 0);
		-----------------------------------------------------------------------------
		-- Misc
		-----------------------------------------------------------------------------
		irq							: out	std_logic;												-- Interrupt (high active)
		
		-----------------------------------------------------------------------------
		-- Axi Slave Bus Interface
		-----------------------------------------------------------------------------
		-- System
		s00_axi_aclk                : in    std_logic;                                             -- Global Clock Signal
		s00_axi_aresetn             : in    std_logic;                                             -- Global Reset Signal. This signal is low active.
		-- Read address channel
		s00_axi_arid                : in    std_logic_vector(C_S00_AXI_ID_WIDTH-1   downto 0);     -- Read address ID. This signal is the identification tag for the read address group of signals.
		s00_axi_araddr              : in    std_logic_vector(7 downto 0);                          -- Read address. This signal indicates the initial address of a read burst transaction.
		s00_axi_arlen               : in    std_logic_vector(7 downto 0);                          -- Burst length. The burst length gives the exact number of transfers in a burst
		s00_axi_arsize              : in    std_logic_vector(2 downto 0);                          -- Burst size. This signal indicates the size of each transfer in the burst
		s00_axi_arburst             : in    std_logic_vector(1 downto 0);                          -- Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
		s00_axi_arlock              : in    std_logic;                                             -- Lock type. Provides additional information about the atomic characteristics of the transfer.
		s00_axi_arcache             : in    std_logic_vector(3 downto 0);                          -- Memory type. This signal indicates how transactions are required to progress through a system.
		s00_axi_arprot              : in    std_logic_vector(2 downto 0);                          -- Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
		s00_axi_arvalid             : in    std_logic;                                             -- Write address valid. This signal indicates that the channel is signaling valid read address and control information.
		s00_axi_arready             : out   std_logic;                                             -- Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
		-- Read data channel
		s00_axi_rid                 : out   std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);       -- Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
		s00_axi_rdata               : out   std_logic_vector(31 downto 0);                         -- Read Data
		s00_axi_rresp               : out   std_logic_vector(1 downto 0);                          -- Read response. This signal indicates the status of the read transfer.
		s00_axi_rlast               : out   std_logic;                                             -- Read last. This signal indicates the last transfer in a read burst.
		s00_axi_rvalid              : out   std_logic;                                             -- Read valid. This signal indicates that the channel is signaling the required read data.
		s00_axi_rready              : in    std_logic;                                             -- Read ready. This signal indicates that the master can accept the read data and response information.
		-- Write address channel
		s00_axi_awid                : in    std_logic_vector(C_S00_AXI_ID_WIDTH-1   downto 0);     -- Write Address ID
		s00_axi_awaddr              : in    std_logic_vector(7 downto 0);                          -- Write address
		s00_axi_awlen               : in    std_logic_vector(7 downto 0);                          -- Burst length. The burst length gives the exact number of transfers in a burst
		s00_axi_awsize              : in    std_logic_vector(2 downto 0);                          -- Burst size. This signal indicates the size of each transfer in the burst
		s00_axi_awburst             : in    std_logic_vector(1 downto 0);                          -- Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
		s00_axi_awlock              : in    std_logic;                                             -- Lock type. Provides additional information about the atomic characteristics of the transfer.
		s00_axi_awcache             : in    std_logic_vector(3 downto 0);                          -- Memory type. This signal indicates how transactions are required to progress through a system.
		s00_axi_awprot              : in    std_logic_vector(2 downto 0);                          -- Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
		s00_axi_awvalid             : in    std_logic;                                             -- Write address valid. This signal indicates that the channel is signaling valid write address and control information.
		s00_axi_awready             : out   std_logic;                                             -- Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
		-- Write data channel
		s00_axi_wdata               : in    std_logic_vector(31    downto 0);                      -- Write Data
		s00_axi_wstrb               : in    std_logic_vector(3 downto 0);                          -- Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
		s00_axi_wlast               : in    std_logic;                                             -- Write last. This signal indicates the last transfer in a write burst.
		s00_axi_wvalid              : in    std_logic;                                             -- Write valid. This signal indicates that valid write data and strobes are available.
		s00_axi_wready              : out   std_logic;                                             -- Write ready. This signal indicates that the slave can accept the write data.
		-- Write response channel
		s00_axi_bid                 : out   std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);       -- Response ID tag. This signal is the ID tag of the write response.
		s00_axi_bresp               : out   std_logic_vector(1 downto 0);                          -- Write response. This signal indicates the status of the write transaction.
		s00_axi_bvalid              : out   std_logic;                                             -- Write response valid. This signal indicates that the channel is signaling a valid write response.
		s00_axi_bready              : in    std_logic                                              -- Response ready. This signal indicates that the master can accept a write response.		
	);

end entity spi_vivado_wrp;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of spi_vivado_wrp is 

	-- Array of desired number of chip enables for each address range
	constant USER_SLV_NUM_REG               : integer              := 2**log2ceil(RegCount_c); 
	
	-- IP Interconnect (IPIC) signal declarations
	signal reg_rd                    		: std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
	signal reg_rdata                 		: t_aslv32(0 to USER_SLV_NUM_REG-1) := (others => (others => '0'));
	signal reg_wr                    		: std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
	signal reg_wdata                 		: t_aslv32(0 to USER_SLV_NUM_REG-1);	
	
	-- Ohter Signals 
	signal AxiRst							: std_logic;
	

begin

	AxiRst <= not s00_axi_aresetn;

   -----------------------------------------------------------------------------
   -- AXI decode instance
   -----------------------------------------------------------------------------
   axi_slave_reg_inst : entity work.psi_common_axi_slave_ipif
   generic map
   (
      -- Users parameters
      NumReg_g                             => USER_SLV_NUM_REG,
      UseMem_g                             => false,
      -- Parameters of Axi Slave Bus Interface
      AxiIdWidth_g                         => C_S00_AXI_ID_WIDTH,
      AxiAddrWidth_g                       => 8
   )
   port map
   (
      --------------------------------------------------------------------------
      -- Axi Slave Bus Interface
      --------------------------------------------------------------------------
      -- System
      s_axi_aclk                  => s00_axi_aclk,
      s_axi_aresetn               => s00_axi_aresetn,
      -- Read address channel
      s_axi_arid                  => s00_axi_arid,
      s_axi_araddr                => s00_axi_araddr,
      s_axi_arlen                 => s00_axi_arlen,
      s_axi_arsize                => s00_axi_arsize,
      s_axi_arburst               => s00_axi_arburst,
      s_axi_arlock                => s00_axi_arlock,
      s_axi_arcache               => s00_axi_arcache,
      s_axi_arprot                => s00_axi_arprot,
      s_axi_arvalid               => s00_axi_arvalid,
      s_axi_arready               => s00_axi_arready,
      -- Read data channel
      s_axi_rid                   => s00_axi_rid,
      s_axi_rdata                 => s00_axi_rdata,
      s_axi_rresp                 => s00_axi_rresp,
      s_axi_rlast                 => s00_axi_rlast,
      s_axi_rvalid                => s00_axi_rvalid,
      s_axi_rready                => s00_axi_rready,
      -- Write address channel
      s_axi_awid                  => s00_axi_awid,
      s_axi_awaddr                => s00_axi_awaddr,
      s_axi_awlen                 => s00_axi_awlen,
      s_axi_awsize                => s00_axi_awsize,
      s_axi_awburst               => s00_axi_awburst,
      s_axi_awlock                => s00_axi_awlock,
      s_axi_awcache               => s00_axi_awcache,
      s_axi_awprot                => s00_axi_awprot,
      s_axi_awvalid               => s00_axi_awvalid,
      s_axi_awready               => s00_axi_awready,
      -- Write data channel
      s_axi_wdata                 => s00_axi_wdata,
      s_axi_wstrb                 => s00_axi_wstrb,
      s_axi_wlast                 => s00_axi_wlast,
      s_axi_wvalid                => s00_axi_wvalid,
      s_axi_wready                => s00_axi_wready,
      -- Write response channel
      s_axi_bid                   => s00_axi_bid,
      s_axi_bresp                 => s00_axi_bresp,
      s_axi_bvalid                => s00_axi_bvalid,
      s_axi_bready                => s00_axi_bready,
      --------------------------------------------------------------------------
      -- Register Interface
      --------------------------------------------------------------------------
      o_reg_rd                    => reg_rd,
      i_reg_rdata                 => reg_rdata,
      o_reg_wr                    => reg_wr,
      o_reg_wdata                 => reg_wdata
   );
   
	-----------------------------------------------------------------------------
	-- Implementation
	-----------------------------------------------------------------------------
	-- register readback 
  reg_rdata(RegIdx_SlaveNr_c)(log2ceil(SlaveCnt_g)-1 downto 0)        <= reg_wdata(RegIdx_SlaveNr_c)(log2ceil(SlaveCnt_g)-1 downto 0);
  reg_rdata(RegIdx_StoreRx_c)(0)                                      <= reg_wdata(RegIdx_StoreRx_c)(0);
  reg_rdata(RegIdx_TxAlmEmptyLevel_c)(log2ceil(FifoDepth_g) downto 0) <= reg_wdata(RegIdx_TxAlmEmptyLevel_c)(log2ceil(FifoDepth_g) downto 0);
  reg_rdata(RegIdx_RxAlmFullLevel_c)(log2ceil(FifoDepth_g) downto 0)  <= reg_wdata(RegIdx_RxAlmFullLevel_c)(log2ceil(FifoDepth_g) downto 0);
  reg_rdata(RegIdx_IrqEna_c)(IrqSize_c-1 downto 0)                    <= reg_wdata(RegIdx_IrqEna_c)(IrqSize_c-1 downto 0);
 	
	i_spi : entity work.spi_simple
		generic map ( 
			ClockDivider_g	=> ClockDivider_g,
			TransWidth_g	=> TransWidth_g,				
			CsHighCycles_g	=> CsHighCycles_g,						
			SpiCPOL_g		=> SpiCPOL_g,			
			SpiCPHA_g		=> SpiCPHA_g,
			SlaveCnt_g		=> SlaveCnt_g,				
			LsbFirst_g		=> LsbFirst_g,
			FifoDepth_g		=> FifoDepth_g
		)
		port map (
			-- control signals
			Clk			=> s00_axi_aclk,
			Rst			=> AxiRst,
			
			-- Configuration
			CfgSlave		=> reg_wdata(RegIdx_SlaveNr_c)(log2ceil(SlaveCnt_g)-1 downto 0),
			CfgStoreRx		=> reg_wdata(RegIdx_StoreRx_c)(0),
			CfgTxAlmEmpty	=> reg_wdata(RegIdx_TxAlmEmptyLevel_c)(log2ceil(FifoDepth_g) downto 0),
			CfgRxAlmFull	=> reg_wdata(RegIdx_RxAlmFullLevel_c)(log2ceil(FifoDepth_g) downto 0),
			
			-- IRQ Interface
			CfgIrqClr		=> reg_wdata(RegIdx_IrqVec_c)(IrqSize_c-1 downto 0),
			CfgIrqClrVld	=> reg_wr(RegIdx_IrqVec_c),
			CfgIrqVec		=> reg_rdata(RegIdx_IrqVec_c)(IrqSize_c-1 downto 0),
			CfgIrqEna		=> reg_wdata(RegIdx_IrqEna_c)(IrqSize_c-1 downto 0),
			Irq				=> irq,
			
			-- Status Interface
			Status			=> reg_rdata(RegIdx_Status_c)(StatusSize_c-1 downto 0),
			
			-- Fifo Interface
			RxData			=> reg_rdata(RegIdx_Data_c)(TransWidth_g-1 downto 0),
			RxAck			=> reg_rd(RegIdx_Data_c),
			RxLevel			=> reg_rdata(RegIdx_RxLevel_c)(log2ceil(FifoDepth_g) downto 0),
			TxData			=> reg_wdata(RegIdx_Data_c)(TransWidth_g-1 downto 0),
			TxWrite			=> reg_wr(RegIdx_Data_c),
			TxLevel			=> reg_rdata(RegIdx_TxLevel_c)(log2ceil(FifoDepth_g) downto 0),		
				
			-- SPI 	
			SpiSck			=> spi_sck,
			SpiMosi			=> spi_mosi,
			SpiMiso			=> spi_miso,
			SpiCs_n			=> spi_cs_n,
            SpiLe			=> spi_le
		);
   
	
  
end rtl;
