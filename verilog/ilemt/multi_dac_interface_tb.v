// Test dac_buffer_reg and multi_dac_interface.  We feed in data words when
// the module requests, and also monitor the serial output to see if it agrees
// (according to our understanding of what the DAC does).

module multi_dac_interface_tb ();
`include "adc_params.v"

   /// signals to/from the modules under test
   //
   // Signals are labeled input/output from the viewpoint of the module under
   // test.

   // dac_buffer_reg
   wire 	     bus_clk; // input to module (unused)
   wire [32*dac_channels - 1 : 0] dac_buffer; // output
   wire 	     dac_request; // input
   wire 	     dac_buffer_ready; // output
   wire 	     dac_underrun; // output
   wire 	     dac_open; // output
   reg 		     dac_open_bus; // input
   wire 	     dac_rden; // output
   reg [31:0] 	     dac_fifo_data; // input
   reg	 	     dac_empty; // output

   
   // multi_dac_interface
   // 
   // Many of the ports on multi_dac_interface wire directly to
   // dac_buffer_reg, are not read or written by the testbench, and are not
   // re-declared here.
   wire 	     DAC_BCK; // out from module
   wire [1:0] 	     DAC_DATA_PINS; // out
   wire 	     DAC_LRCK; // out
   wire 	     DAC_NOT_RST; // out
   
   reg capture_clk = 0;
   initial begin
      forever capture_clk = #(capture_clk_period / 2) ~capture_clk;
   end


   /// Simulated DAC input.
   //
   // Output Words are like 0x0A1B0C1D, 0x0A2B0C2D, etc. (for channel 0)

   // Counters used to generate word data.
   reg [3:0] dac_count = 1;
   reg [1:0] dac_channel = 0;
   
   // DAC output register.
   reg [31:0] dac_data_reg = 0;

   always @(posedge capture_clk)
     if (dac_rden) begin
	// Load new simulated data in output register when module requests.
	dac_data_reg <= {dac_channel, 4'hA, dac_count, 4'hB,
			 dac_channel, 4'hC, dac_count, 4'hD};
	dac_channel <= dac_channel + 1;
	if (dac_channel == 0)
	  dac_count <= dac_count + 1;
     end

   
   /// deserialize and display data sent to DAC.

   // Input shift registers of the two simulated DAC chips.  Data is shifted
   // in at the LSB, and there is a 1 bit stuffed before it.  So the actual
   // data is [23:0].  When the 1 bit reaches bit 24 then we know we have got
   // the full word.
   reg [24:0] dac_shiftin [0:1];

   reg prev_lrck = 1;
   // Number of words captured. 
   reg [31:0] capture_count = 1;
   always @(posedge DAC_BCK) begin
      if (prev_lrck != DAC_LRCK) begin
	 // An edge on LRCK, start new word (left/right).  At this point the
	 // dummy I2S start bit is on the data line.  This gets ignored for
	 // free, because we would have to shift it in now, and we don't.
	 dac_shiftin[0] <= {24'b0, 1'b1};
	 dac_shiftin[1] <= {24'b0, 1'b1};
      end
      else begin
	 // Not starting a word, shift in data (24 bits).
	 if (dac_shiftin[0][24]) begin
	    // At end of 24 bit input, marked by the stuffed 1 bit.
	    $display("DAC0 %d %d: %x", capture_count, DAC_LRCK, dac_shiftin[0][23:0]);
	    $display("DAC1 %d %d: %x", capture_count, DAC_LRCK, dac_shiftin[1][23:0]);
	    capture_count <= capture_count + 1;
	    dac_shiftin[0] <= 0;
	    dac_shiftin[1] <= 0;
	 end
	 else begin
	    // Shift in the data bits
	    dac_shiftin[0] <= {dac_shiftin[0][23:0], DAC_DATA_PINS[0]};
	    dac_shiftin[1] <= {dac_shiftin[1][23:0], DAC_DATA_PINS[1]};
	 end
      end
      prev_lrck <= DAC_LRCK;
   end

   always @(posedge capture_clk) begin
      if (dac_underrun)
	$display("dac_underrun!");
   end

   assign bus_clk = capture_clk;

   initial begin
      dac_open_bus <= 0;
      dac_empty <= 1;
      
      #(200)
      dac_open_bus <= 1;

      #(200)
      @(posedge capture_clk)
      dac_empty <= 0;
   end


   //// Instantiate modules:

   // dac_buffer_reg manages the reading from our end of the write FIFO.
   dac_buffer_reg the_dac_buffer_reg
     (
      .capture_clk(capture_clk),
      .bus_clk(bus_clk),
      .dac_buffer(dac_buffer),
      .dac_request(dac_request),
      .dac_buffer_ready(dac_buffer_ready),
      .dac_underrun(dac_underrun),
      .dac_open(dac_open),
      .dac_open_bus(dac_open_bus),
      .dac_rden(dac_rden),
      .dac_fifo_data(dac_fifo_data),
      .dac_empty(dac_empty)
      );

   // multi_dac_interface is the interface for the output board
   multi_dac_interface the_dac
      (
       .capture_clk(capture_clk),
       .enable(dac_open),
       .dac_buffer(dac_buffer),
       .dac_request(dac_request),

       // DAC pins (all output)
       .DAC_BCK(DAC_BCK),
       .DAC_DATA_PINS(DAC_DATA_PINS),
       .DAC_LRCK(DAC_LRCK),
       .DAC_NOT_RST(DAC_NOT_RST)
       );

   
     
endmodule // multi_dac_interface_tb
