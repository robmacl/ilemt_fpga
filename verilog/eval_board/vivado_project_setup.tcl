# save the script directory for relative filename use.
set origin_dir [file dirname [info script]]

# What project to create.
set proj_name eval_board

# Sources to add (by reference, in place)
set source_files [list \
 $origin_dir/eval_board.v \
 $origin_dir/adc_interface.v \
 $origin_dir/dac_interface.v \
 $origin_dir/interface_params.v \
]

# Sources to copy into Vivado project tree.  Use this for IP to avoid
# cluttering the source tree with generated files.  If you
# re-customize the IP you must copy it back into the source tree for
# the changes to be committed.
set import_files [list \
 $origin_dir/ip/async_fifo_32/async_fifo_32.xci \
 $origin_dir/ip/capture_clk1/capture_clk1.xci \
		     ]

set constraint_files [list \
 $origin_dir/eval_board.xdc \
]

# Do the rest of the setup, which is mostly xillybus specific.
source $origin_dir/../vivado_project_setup_xillybus.tcl
