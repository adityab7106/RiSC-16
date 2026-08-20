## This file is a general .xdc for the Basys3 rev B board for ENGS31/CoSc56
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project
## - these names should match the external ports (_ext_port) in the entity declaration of your shell/top level

##====================================================================
## External_Clock_Port
##====================================================================
## This is a 100 MHz external clock
set_property PACKAGE_PIN W5 [get_ports clk_ext_port]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk_ext_port]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_ext_port]

##====================================================================
## Switch_ports
##====================================================================
## SWITCH 0 (RIGHT MOST SWITCH)
##set_property PACKAGE_PIN V17 [get_ports {Read_A}]					
	##set_property IOSTANDARD LVCMOS33 [get_ports {Read_A}]
## SWITCH 1
##set_property PACKAGE_PIN V16 [get_ports {Read_B}]					
	##set_property IOSTANDARD LVCMOS33 [get_ports {Read_B}]
## SWITCH 2
##set_property PACKAGE_PIN W16 [get_ports {Read_C}]					
	##set_property IOSTANDARD LVCMOS33 [get_ports {Read_C}]
## SWITCH 3
#set_property PACKAGE_PIN W17 [get_ports {sw_ext_port[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[3]}]
## SWITCH 4
#set_property PACKAGE_PIN W15 [get_ports {sw_ext_port[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[4]}]
 
##====================================================================
## LED_ports
##====================================================================
## LED 0 (RIGHT MOST LED)
#set_property PACKAGE_PIN U16 [get_ports {LED_ext_port[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[0]}]
## LED 1
#set_property PACKAGE_PIN E19 [get_ports {LED_ext_port[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[1]}]
## LED 2
#set_property PACKAGE_PIN U19 [get_ports {LED_ext_port[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[2]}]
## LED 3
#set_property PACKAGE_PIN V19 [get_ports {LED_ext_port[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[3]}]
## LED 4
#set_property PACKAGE_PIN W18 [get_ports {LED_ext_port[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[4]}]
	
##====================================================================	
## 7 segment display
##====================================================================
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Segments
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#set_property PACKAGE_PIN W7 [get_ports {seg_ext_port[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[0]}]
#set_property PACKAGE_PIN W6 [get_ports {seg_ext_port[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[1]}]
#set_property PACKAGE_PIN U8 [get_ports {seg_ext_port[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[2]}]
#set_property PACKAGE_PIN V8 [get_ports {seg_ext_port[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[3]}]
#set_property PACKAGE_PIN U5 [get_ports {seg_ext_port[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[4]}]
#set_property PACKAGE_PIN V5 [get_ports {seg_ext_port[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[5]}]
#set_property PACKAGE_PIN U7 [get_ports {seg_ext_port[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[6]}]
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Decimal Point
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#set_property PACKAGE_PIN V7 [get_ports dp_ext_port]							
	#set_property IOSTANDARD LVCMOS33 [get_ports dp_ext_port]
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Anodes
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#set_property PACKAGE_PIN U2 [get_ports {an_ext_port[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[0]}]
#set_property PACKAGE_PIN U4 [get_ports {an_ext_port[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[1]}]
#set_property PACKAGE_PIN V4 [get_ports {an_ext_port[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[2]}]
#set_property PACKAGE_PIN W4 [get_ports {an_ext_port[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[3]}]

##====================================================================
## Buttons
##====================================================================
## CENTER BUTTON
#set_property PACKAGE_PIN U18 [get_ports btnC_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnC_ext_port]
## UP BUTTON
#set_property PACKAGE_PIN T18 [get_ports btnU_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnU_ext_port]
## LEFT BUTTON
#set_property PACKAGE_PIN W19 [get_ports btnL_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnL_ext_port]
## RIGHT BUTTON
#set_property PACKAGE_PIN T17 [get_ports btnR_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnR_ext_port]
## DOWN BUTTON
#set_property PACKAGE_PIN U17 [get_ports btnD_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnD_ext_port]
 

##====================================================================
## USB-RS232 Interface
##====================================================================
#set_property PACKAGE_PIN B18 [get_ports RsRx_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsRx_ext_port]
#set_property PACKAGE_PIN A18 [get_ports RsTx_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsTx_ext_port]

##====================================================================
## USB HID (PS/2)
##====================================================================
#set_property PACKAGE_PIN C17 [get_ports PS2Clk_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports PS2Clk_ext_port]
	#set_property PULLUP true [get_ports PS2Clk_ext_port]
#set_property PACKAGE_PIN B17 [get_ports PS2Data_ext_port]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PS2Data_ext_port]	
	#set_property PULLUP true [get_ports PS2Data_ext_port]

##====================================================================
## Implementation Assist
##====================================================================	
## These additional constraints are recommended by Digilent, DO NOT REMOVE!
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]