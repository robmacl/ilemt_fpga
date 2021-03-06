# Project setup related to this specific target (ilemt)

# save the script directory for relative filename use.
set origin_dir [file dirname [info script]]

# What project to create.
set proj_name ilemt

# Sources to add (by reference, in place)
set source_files [list \
 $origin_dir/ilemt.v \
 $origin_dir/multi_adc_interface.v \
 $origin_dir/adc_register.v \
 $origin_dir/multi_dac_interface.v \
 $origin_dir/dac_buffer_reg.v \
]

# Sources to copy into Vivado project tree.  We use this for IP to
# avoid cluttering the source tree with generated files.  If you
# re-customize the IP you must copy it back into the source tree for
# the changes to be committed.
# cd ~/Documents/Work/ilemt_fpga/verilog/ilemt
# cp -p vivado/ilemt.srcs/sources_1/ip/capture_clk1/capture_clk1.xci ip/capture_clk1/
set import_files [list \
 $origin_dir/ip/async_fifo_32/async_fifo_32.xci \
 $origin_dir/ip/capture_clk1/capture_clk1.xci \
]

set constraint_files [list \
 $origin_dir/ilemt.xdc \
]

# probably we should have a different sim set for each testbench or
# something, for now just having only one in the sim_1 set.
# $origin_dir/multi_adc_interface_tb.v \
# $origin_dir/multi_adc_interface.v \

set sim_files [list \
 $origin_dir/multi_dac_interface_tb.v \
 $origin_dir/dac_buffer_reg.v \
 $origin_dir/multi_dac_interface.v \
]

set sim_top_module multi_dac_interface_tb

# Do the rest of the setup, which is mostly xillybus specific.
source $origin_dir/../vivado_project_setup_xillybus.tcl
