-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
-- Date        : Wed Sep 11 13:25:15 2019
-- Host        : rob running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub -rename_top capture_clk1 -prefix
--               capture_clk1_ capture_clk1_stub.vhdl
-- Design      : capture_clk1
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z010clg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity capture_clk1 is
  Port ( 
    clk_out1 : out STD_LOGIC;
    clk_fpga_1 : in STD_LOGIC
  );

end capture_clk1;

architecture stub of capture_clk1 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_out1,clk_fpga_1";
begin
end;
