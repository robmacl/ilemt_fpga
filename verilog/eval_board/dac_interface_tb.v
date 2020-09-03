// Test dac_interface.  We feed in data words when the module requests, and
// also monitor the serial output to see if it agrees (according to our
// understanding of what the DAC does).

module dac_interface_tb ();

   wire 	     dac_bck; // out from module
   wire 	     dac_data_pin; // out
   wire 	     dac_lrck; // out
   
   wire 	     bus_clk; // in (unused)
   reg 		     dac_open_bus; // in
   wire 	     dac_rden; // out
   wire 	     dac_empty; // in (unused)

   parameter period = 50; // Not the real period 40.69 ns
   reg capture_clk = 0;
   initial begin
      forever capture_clk = #(period / 2) ~capture_clk;
   end

   /// Simulated DAC input. Words are like 0x1A1B1C1D, 0x2A2B2C2D, etc.
   // Counter used to generate word data.
   reg [3:0] dac_count = 1;
   // DAC output register.
   reg [31:0] dac_data_reg = 0;

   always @(posedge capture_clk)
     if (dac_rden) begin
      // Load new simulated data in output register when module requests.
      dac_data_reg <= {dac_count, 4'hA, dac_count, 4'hB,
		       dac_count, 4'hC, dac_count, 4'hD};
      dac_count <= dac_count + 1;
     end

   /// deserialize and display data sent to DAC.

   // Input shift register of simulated DAC.  Data is shifted in at the LSB,
   // and there is a 1 bit stuffed before it.  So the actual data is [23:0]
   // When the 1 bit reaches bit 24 then we know we have got the full word.
   reg [24:0] dac_shiftin = 0;

   reg prev_lrck = 1;
   // Number of words captured. 
   reg [31:0] capture_count = 1;
   always @(posedge dac_bck) begin
      if (prev_lrck != dac_lrck) begin
	 // The left pad bit gets ignored for free, because we would have to
	 // shift it in now, and we don't.
	 dac_shiftin <= {24'b0, 1'b1};
      end
      else begin
	 if (dac_shiftin[24] && !dac_lrck) begin
	    $display("dac input %d: %x", capture_count, dac_shiftin[23:0]);
	    capture_count <= capture_count + 1;
	    dac_shiftin <= 0;
	 end
	 else
	   dac_shiftin <= {dac_shiftin[23:0], dac_data_pin};
      end
      prev_lrck <= dac_lrck;
   end
   assign bus_clk = capture_clk;
   assign dac_empty = 0;

   initial begin
      dac_open_bus <= 0;
      #(200)
      dac_open_bus <= 1;
   end
   
   dac_interface the_dac
      (
       .dac_bck(dac_bck),
       .dac_data_pin(dac_data_pin),
       .dac_lrck(dac_lrck),
       .capture_clk(capture_clk),
       .bus_clk(bus_clk),
       .dac_open_bus(dac_open_bus),
       .dac_rden(dac_rden),
       .dac_data(dac_data_reg),
       .dac_empty(dac_empty)
       );
     
endmodule // dac_interface_tb
