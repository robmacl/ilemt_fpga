module multi_adc_interface_tb ();
`include "adc_params.v"

   // pins:  Direction r.e. adc_interface module
   wire adc_mclk, // out
	adc_scka, // out
	adc_sync, // out 
	adc_sdi; // out

   reg [adc_channels-1:0] adc_sdoa = 0; // in
   
   // clocks
   reg capture_clk = 0;
   initial begin
      forever capture_clk = #(capture_clk_period / 2) ~capture_clk;
   end

   reg bus_clk = 0;
   initial begin
      forever bus_clk = #(bus_clk_period / 2) ~bus_clk;
   end

   reg user_r_read_32_open = 0; // in from Xillybus

   initial begin
      if (convert_cycles + 2 + 2*acquire_nbits > adc_cycles) begin
	 $display("Not enough time in adc_cycle for acqusition.");
	 $stop;
      end
      if (adc_decimate * acquire_nbits < adc_bits) begin
	 $display("Not enough bits acquired during decimate cycle.");
	 $stop;
      end
	 
      #(100*capture_clk_period)
	user_r_read_32_open = 1;
      #(4*adc_decimate*adc_cycles*capture_clk_period);
      $stop;
   end


   /// Xillybus/FIFO interface:
   // in/out directions r.e. multi_adc_interface module

   // write side (capture_clk domain)
   wire [31:0] capture_data; // out, FIFO
   wire        capture_en; // out, FIFO
   reg 	       capture_full = 0; // in, fifo handshaking

   // read side of FIFO (bus_clk domain)
   wire        user_r_read_32_rden = 1;
   wire [31:0] user_r_read_32_data;
   wire        user_r_read_32_valid;

   // Number of words captured. 
   reg [31:0] capture_count = 1;

   /*
   // ### couldn't figure out how to get FIFO IP working in simulator
   // ADC output data FIFO
   async_fifo_32 adc_fifo
     (
      .rst(!user_r_read_32_open),
      .wr_clk(capture_clk),
      .wr_en(capture_en),
      .din(capture_data),
      .full(capture_full),

      .rd_clk(bus_clk),
      .rd_en(user_r_read_32_rden),
      .dout(user_r_read_32_data),
      .valid(user_r_read_32_valid)
      );

   // Display latched data.
   always @(posedge bus_clk) begin
      if (user_r_read_32_valid) begin
	 $display("FIFO data %d: %x", capture_count, user_r_read_32_data);
	 capture_count = capture_count + 1;
      end
   end
   */

   // Display latched data.
   always @(posedge capture_clk) begin
      if (capture_en) begin
	 $display("capture_data %d: %x", capture_count, capture_data);
	 capture_count = capture_count + 1;
      end
   end

   
   // True if we have seen an MCLK, configuration should be complete.
   reg config_done = 0;
   always @(posedge capture_clk) begin
      if (adc_mclk)
	config_done = 1;
   end

   
   /// Simulated ADC output

   // Sequential outputs are hex cAwBcCwW, where c is the channel and w is the
   // output word.  The top 8 bits are lost with adc_bits=24.

   // Counter used to distinguish word data.
   reg [3:0] adc_count = 1;

   // ADC output registers
   reg [adc_bits-1:0] adc_data_reg [adc_channels-1:0];

   always @(posedge adc_sync) begin: load
      // Load new simulated data in output register when we have finished
      // previous output.  Using adc_sync keeps us in synch with adc_interface
      // (and simulates the ADC).  The ADC actually loads the output register
      // on the negative edge of DRL (after the final conversion of the
      // decimate block completes), but we don't use DRL, so rely on
      // worst-case timing.
      reg [3:0] chan;
      for (chan = 0; chan < adc_channels; chan = chan + 1) begin
	 adc_data_reg[chan] <= {chan, 4'hA, adc_count, 4'hB,
				chan, 4'hC, adc_count, 4'hD};
      end
      adc_count <= adc_count + 1;
   end

   always @(*) begin: outreg
      reg [3:0] chan;
      for (chan = 0; chan < adc_channels; chan = chan + 1) begin
	 adc_sdoa[chan] = adc_data_reg[chan][adc_bits-1];
      end
   end

   always @(posedge adc_scka) begin: shifter
      // Shift out new data on each adc_scka positive edge.  This happens
      // during the config period also, which is what the chip does.
      reg [3:0] chan;
      for (chan = 0; chan < adc_channels; chan = chan + 1) begin
	 adc_data_reg[chan] <= {adc_data_reg[chan][adc_bits-2:0], 1'bX};
      end
   end

   multi_adc_interface the_adc
     (
      .adc_mclk(adc_mclk),
      .adc_scka(adc_scka),
      .adc_sync(adc_sync),
      .adc_sdi(adc_sdi),
      .adc_sdoa(adc_sdoa),
      .capture_clk(capture_clk),
      .bus_clk(bus_clk),
      .capture_data(capture_data),
      .capture_en(capture_en),
      .capture_full(capture_full),
      .user_r_read_32_open(user_r_read_32_open)
      );

   initial begin
      $timeformat(-6, 3, "us", 10);
      /*
      $display(" Time MCLK SKCA SYNC SDI data en");
      $monitor("%t %b %b %b %b %x %b", $realtime,
	       adc_mclk,
	       adc_scka,
	       adc_sync, 
	       adc_sdi,
	       capture_data,
	       capture_en);
      */
   end
     
endmodule
