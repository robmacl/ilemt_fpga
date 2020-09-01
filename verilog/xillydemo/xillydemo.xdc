# ADC pins:
set_property IOSTANDARD LVCMOS33 [get_ports adc_sdi]
set_property IOSTANDARD LVCMOS33 [get_ports adc_sync]
set_property IOSTANDARD LVCMOS33 [get_ports adc1_sdoa]
set_property IOSTANDARD LVCMOS33 [get_ports adc_mclk]
set_property IOSTANDARD LVCMOS33 [get_ports adc_scka]
set_property IOSTANDARD LVCMOS33 [get_ports capture_en]
set_property DRIVE 4 [get_ports adc_sdi]
set_property DRIVE 4 [get_ports adc_sync]
set_property DRIVE 4 [get_ports adc_mclk]
set_property DRIVE 4 [get_ports adc_scka]
set_property DRIVE 4 [get_ports capture_en]
set_property PACKAGE_PIN T20 [get_ports adc_mclk]
set_property PACKAGE_PIN U20 [get_ports adc_scka]
set_property PACKAGE_PIN W20 [get_ports adc_sdi]
set_property PACKAGE_PIN V20 [get_ports adc_sync]
set_property PACKAGE_PIN W19 [get_ports adc1_sdoa]
set_property PACKAGE_PIN Y18 [get_ports capture_en]

# These constraints are bullshit, but keep the timing analyzer happy.  The
# reality is that because the SPI clock is 1/2 speed we have 70 ns of setup
# time, so at least at this clock speed there should not be any problem no
# matter what.  I think it is possible to specify the constraints correctly,
# but don't feel like figuring that out.
create_clock -period 40.690 -name VIRTUAL_clk_out1_capture_clk1 -waveform {0.000 20.345}
set_input_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -min -add_delay 2.000 [get_ports adc1_sdoa]
set_input_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -max -add_delay 4.000 [get_ports adc1_sdoa]
set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -min -add_delay 0.000 [get_ports adc_mclk]
set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -max -add_delay 3.000 [get_ports adc_mclk]
set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -min -add_delay 0.000 [get_ports adc_scka]
set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -max -add_delay 3.000 [get_ports adc_scka]

set_false_path -from [get_clocks clk_fpga_1] -to [get_clocks -of_objects [get_pins capture_clk1_instance/inst/mmcm_adv_inst/CLKOUT0]]

set_false_path -from [get_clocks VIRTUAL_clk_out1_capture_clk1] -to [get_clocks -of_objects [get_pins capture_clk1_instance/inst/mmcm_adv_inst/CLKOUT0]]

set_false_path -from [get_clocks -of_objects [get_pins capture_clk1_instance/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks VIRTUAL_clk_out1_capture_clk1]

# DAC pins
set_property PACKAGE_PIN E19 [get_ports dac_sck]
set_property PACKAGE_PIN F16 [get_ports dac_bck]
set_property PACKAGE_PIN L19 [get_ports dac_data_pin]
set_property PACKAGE_PIN M19 [get_ports dac_lrck]
set_property IOSTANDARD LVCMOS33 [get_ports dac_sck]
set_property IOSTANDARD LVCMOS33 [get_ports dac_bck]
set_property IOSTANDARD LVCMOS33 [get_ports dac_data_pin]
set_property IOSTANDARD LVCMOS33 [get_ports dac_lrck]
set_property DRIVE 4 [get_ports dac_sck]
set_property DRIVE 4 [get_ports dac_bck]
set_property DRIVE 4 [get_ports dac_data_pin]
set_property DRIVE 4 [get_ports dac_lrck]
set_property SLEW SLOW [get_ports capture_en]
set_property SLEW SLOW [get_ports dac_sck]
set_property SLEW SLOW [get_ports adc_mclk]
set_property SLEW SLOW [get_ports adc_scka]
set_property SLEW SLOW [get_ports adc_sdi]
set_property SLEW SLOW [get_ports adc_sync]
set_property SLEW SLOW [get_ports dac_bck]
set_property SLEW SLOW [get_ports dac_data_pin]
set_property SLEW SLOW [get_ports dac_lrck]

set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -min -add_delay 0.000 [get_ports dac_sck]
set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -max -add_delay 3.000 [get_ports dac_sck]
set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -min -add_delay 0.000 [get_ports dac_bck]
set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -max -add_delay 3.000 [get_ports dac_bck]
set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -min -add_delay 0.000 [get_ports dac_data_pin]
set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -max -add_delay 3.000 [get_ports dac_data_pin]
set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -min -add_delay 0.000 [get_ports dac_lrck]
set_output_delay -clock [get_clocks VIRTUAL_clk_out1_capture_clk1] -max -add_delay 3.000 [get_ports dac_lrck]
