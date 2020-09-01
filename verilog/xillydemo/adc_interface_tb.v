
module adc_interface_tb ();

   // pins:  Direction r.e. adc_interface module
   wire adc_mclk, // out
	adc_scka, // out
	adc_sync, // out 
	adc_sdi; // out

   reg adc1_sdoa = 0; // in
   
   // reg [11:0] adc_config;

   // Xillybus/FIFO interface:
   wire [31:0] capture_data; // out, FIFO
   wire        capture_en; // out, FIFO
   reg 	       user_r_read_32_open = 0; // in Xillybus
   reg 	       capture_full = 0; // in, fifo handshaking

   parameter period = 50; // Not the real period 70.989
   reg clk = 0;
   initial begin
      forever clk = #(period / 2) ~clk;
   end

   initial begin
      #(100*period)
	user_r_read_32_open = 1;
      #(100*20*period);
      $stop;
   end

   // True if we have seen an MCLK, configuration should be complete.
   reg config_done = 0;
   always @(posedge clk) begin
      if (adc_mclk)
	config_done = 1;
   end
   
   /// Simulated ADC output
   // Sequential outputs are like 0x1A1B1C1D, 0x2A2B2C2D, etc.

   // Counter used to distinguish word data.
   reg [3:0] adc_count = 1;
   // ADC output register.
   reg [31:0] adc_data_reg = 0;

   always @(posedge adc_sync) begin
      // Load new simulated data in output register when we have finished
      // previous output.  Using adc_sync keeps us in synch with adc_interface
      // (and simulates the ADC).  The ADC actually loads the output register
      // on the negative edge of DRL (after the final conversion of the
      // decimate block completes).
      adc_data_reg <= {adc_count, 4'hA, adc_count, 4'hB,
		       adc_count, 4'hC, adc_count, 4'hD};
      adc_count <= adc_count + 1;
   end

   // Number of words captured. 
   reg [31:0] capture_count = 1;
   // Display latched data.
   always @(posedge clk) begin
      if (capture_en) begin
	 $display("capture_data %d: %x", capture_count, capture_data);
	 capture_count = capture_count + 1;
      end
   end

   always @(*)
     adc1_sdoa = adc_data_reg[31];

   always @(posedge adc_scka) begin
      // Shift out new data on each adc_scka positive edge.  This happens
      // during the config period also, which is what the chip does.
      adc_data_reg <= {adc_data_reg[30:0], 1'bX};
   end

   adc_interface the_adc
     (
      .adc_mclk(adc_mclk),
      .adc_scka(adc_scka),
      .adc_sync(adc_sync),
      .adc_sdi(adc_sdi),
      .adc1_sdoa(adc1_sdoa),
      .capture_clk(clk),
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
     
endmodule // adc_interface_tb
