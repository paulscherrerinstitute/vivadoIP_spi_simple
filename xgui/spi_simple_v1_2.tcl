# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Configuration [ipgui::add_page $IPINST -name "Configuration"]
  ipgui::add_param $IPINST -name "ClockDivider_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "TransWidth_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "CsHighCycles_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "SpiCPOL_g" -parent ${Configuration} -widget comboBox
  ipgui::add_param $IPINST -name "SpiCPHA_g" -parent ${Configuration} -widget comboBox
  ipgui::add_param $IPINST -name "SlaveCnt_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "LsbFirst_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "FifoDepth_g" -parent ${Configuration}


}

proc update_PARAM_VALUE.C_S00_AXI_ID_WIDTH { PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to update C_S00_AXI_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ID_WIDTH { PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to validate C_S00_AXI_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.ClockDivider_g { PARAM_VALUE.ClockDivider_g } {
	# Procedure called to update ClockDivider_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ClockDivider_g { PARAM_VALUE.ClockDivider_g } {
	# Procedure called to validate ClockDivider_g
	return true
}

proc update_PARAM_VALUE.CsHighCycles_g { PARAM_VALUE.CsHighCycles_g } {
	# Procedure called to update CsHighCycles_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CsHighCycles_g { PARAM_VALUE.CsHighCycles_g } {
	# Procedure called to validate CsHighCycles_g
	return true
}

proc update_PARAM_VALUE.FifoDepth_g { PARAM_VALUE.FifoDepth_g } {
	# Procedure called to update FifoDepth_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FifoDepth_g { PARAM_VALUE.FifoDepth_g } {
	# Procedure called to validate FifoDepth_g
	return true
}

proc update_PARAM_VALUE.LsbFirst_g { PARAM_VALUE.LsbFirst_g } {
	# Procedure called to update LsbFirst_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LsbFirst_g { PARAM_VALUE.LsbFirst_g } {
	# Procedure called to validate LsbFirst_g
	return true
}

proc update_PARAM_VALUE.SlaveCnt_g { PARAM_VALUE.SlaveCnt_g } {
	# Procedure called to update SlaveCnt_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SlaveCnt_g { PARAM_VALUE.SlaveCnt_g } {
	# Procedure called to validate SlaveCnt_g
	return true
}

proc update_PARAM_VALUE.SpiCPHA_g { PARAM_VALUE.SpiCPHA_g } {
	# Procedure called to update SpiCPHA_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SpiCPHA_g { PARAM_VALUE.SpiCPHA_g } {
	# Procedure called to validate SpiCPHA_g
	return true
}

proc update_PARAM_VALUE.SpiCPOL_g { PARAM_VALUE.SpiCPOL_g } {
	# Procedure called to update SpiCPOL_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SpiCPOL_g { PARAM_VALUE.SpiCPOL_g } {
	# Procedure called to validate SpiCPOL_g
	return true
}

proc update_PARAM_VALUE.TransWidth_g { PARAM_VALUE.TransWidth_g } {
	# Procedure called to update TransWidth_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TransWidth_g { PARAM_VALUE.TransWidth_g } {
	# Procedure called to validate TransWidth_g
	return true
}


proc update_MODELPARAM_VALUE.ClockDivider_g { MODELPARAM_VALUE.ClockDivider_g PARAM_VALUE.ClockDivider_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ClockDivider_g}] ${MODELPARAM_VALUE.ClockDivider_g}
}

proc update_MODELPARAM_VALUE.TransWidth_g { MODELPARAM_VALUE.TransWidth_g PARAM_VALUE.TransWidth_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TransWidth_g}] ${MODELPARAM_VALUE.TransWidth_g}
}

proc update_MODELPARAM_VALUE.CsHighCycles_g { MODELPARAM_VALUE.CsHighCycles_g PARAM_VALUE.CsHighCycles_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CsHighCycles_g}] ${MODELPARAM_VALUE.CsHighCycles_g}
}

proc update_MODELPARAM_VALUE.SpiCPOL_g { MODELPARAM_VALUE.SpiCPOL_g PARAM_VALUE.SpiCPOL_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SpiCPOL_g}] ${MODELPARAM_VALUE.SpiCPOL_g}
}

proc update_MODELPARAM_VALUE.SpiCPHA_g { MODELPARAM_VALUE.SpiCPHA_g PARAM_VALUE.SpiCPHA_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SpiCPHA_g}] ${MODELPARAM_VALUE.SpiCPHA_g}
}

proc update_MODELPARAM_VALUE.SlaveCnt_g { MODELPARAM_VALUE.SlaveCnt_g PARAM_VALUE.SlaveCnt_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SlaveCnt_g}] ${MODELPARAM_VALUE.SlaveCnt_g}
}

proc update_MODELPARAM_VALUE.LsbFirst_g { MODELPARAM_VALUE.LsbFirst_g PARAM_VALUE.LsbFirst_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LsbFirst_g}] ${MODELPARAM_VALUE.LsbFirst_g}
}

proc update_MODELPARAM_VALUE.FifoDepth_g { MODELPARAM_VALUE.FifoDepth_g PARAM_VALUE.FifoDepth_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FifoDepth_g}] ${MODELPARAM_VALUE.FifoDepth_g}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ID_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH}
}

