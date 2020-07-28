##############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
##############################################################################

###############################################################
# Include PSI packaging commands
###############################################################
source ../../../TCL/PsiIpPackage/PsiIpPackage.tcl
namespace import -force psi::ip_package::latest::*

###############################################################
# General Information
###############################################################
set IP_NAME spi_simple
set IP_VERSION 1.3
set IP_REVISION "auto"
set IP_LIBRARY PSI
set IP_DESCIRPTION "Simple SPI master interface"

init $IP_NAME $IP_VERSION $IP_REVISION $IP_LIBRARY
set_description $IP_DESCIRPTION
set_logo_relative "../doc/psi_logo_150.gif"
set_datasheet_relative "../doc/$IP_NAME.pdf"

###############################################################
# Add Source Files
###############################################################

#Relative Source Files
add_sources_relative { \
	../hdl/definitions_pkg.vhd \
	../hdl/spi_simple.vhd \
	../hdl/spi_vivado_wrp.vhd \
}

#PSI Common
add_lib_relative \
	"../../../VHDL/psi_common/hdl"	\
	{ \
		psi_common_array_pkg.vhd \
		psi_common_math_pkg.vhd \
		psi_common_sdp_ram.vhd \
		psi_common_sync_fifo.vhd \
		psi_common_logic_pkg.vhd \
		psi_common_spi_master.vhd \
		psi_common_pl_stage.vhd \
		psi_common_axi_slave_ipif.vhd \
	}

###############################################################
# Driver Files
###############################################################	

add_drivers_relative ../drivers/spi_simple { \
	src/spi_simple.c \
	src/spi_simple.h \
}
	

###############################################################
# GUI Parameters
###############################################################

#User Parameters
gui_add_page "Configuration"

gui_create_parameter "ClockDivider_g" "Divider between AXI- and SPI-clock (must be a multiple of 2)"
gui_parameter_set_range 4 1000000
gui_add_parameter

gui_create_parameter "TransWidth_g" "Number of bits per SPI transaction"
gui_parameter_set_range 1 32
gui_add_parameter

gui_create_parameter "CsHighCycles_g" "Minimum number of clock-cycles Cs_n high between transactions"
gui_add_parameter

gui_create_parameter "SpiCPOL_g" "SPI Clock polarity CPOL (see documentation)"
gui_parameter_set_widget_dropdown {0 1}
gui_add_parameter

gui_create_parameter "SpiCPHA_g" "SPI sampling edge CPHA (see documentation)"
gui_parameter_set_widget_dropdown {0 1}
gui_add_parameter

gui_create_parameter "SlaveCnt_g" "Number of slaves to support"
gui_parameter_set_range 1 128
gui_add_parameter

gui_create_parameter "LsbFirst_g" "Transmit LSB first (default is MSB first)"
gui_parameter_set_widget_checkbox
gui_add_parameter

gui_create_parameter "FifoDepth_g" "Depth of RX and TX FIFO"
gui_add_parameter

###############################################################
# Optional Ports
###############################################################

#None

###############################################################
# Package Core
###############################################################
set TargetDir ".."
#											Edit  	Synth	
package_ip $TargetDir 						true 	true




