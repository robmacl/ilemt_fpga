// Interface to TI PCM1794A.  We implement four output channels using
// 2 DACs.  We are using I2S data format, 24 bit.
// ### but this is still the old mono version
//
// DAC should be strapped for:
// ### wrong, need stereo
//   {MONO, CHSL, FMT1, FMT0} = 4'b1000
//
// This selects mono, left channel, I2S, sharp output filter rolloff.
// 
module multi_dac_interface
  (
   // Hardware pins: SCK system clock is routed directly from capture_clk.
   // RST reset is not available on the off-the-shelf board.

   // Serial data bit clock.  Data is clocked in on the rising edge of BCK.
   // Frequency is half of capture_clk.  We run BCK continuously (when we are
   // not in reset), sending zero pad data if we have finished the actual
   // data.  There are many excess bit periods in every LRCK window (see
   // lrck_divisor below).
   output reg 	     dac_bck,

   // Serial data, MSB first, followed by zero pad data.  In I2S the first
   // posedge on BCK is a dummy bit, see below.
   output reg [1:0] dac_data,

   // left/right clock.  The rising and trailing edges of LRCK indicate data
   // should be latched.  This is the actual sample rate clock.  The left data
   // is transferred when LRCK is low, so the left data is *latched* by DAC on
   // the positive edge.  I imagine that the data  is clocked into the channel
   // DACs simultaneously, on the negative edge of LRCK (after the right
   // sample data word is complete).  LRCK transitions on a negative edge of
   // BCK, the last bit period of the sample.  (No actual data is transmitted
   // in this last bit period because in I2S the data is at the beginning of
   // the LR window, left justified.)  The full sample period is left then
   // right, so the first LRCK phase is low.
   output reg 	     dac_lrck,

   // Data acqusition clock.  This is the system clock for the DAC (SCK).
   // Must be one of several permissable multiples of LRCK rate, but is not
   // required to have any particular phase relationship.  For us, this is
   // used to generate LRCK (and BCK), so is in-phase.  See adc_params.v for
   // discussion of clocking.
   input wire 	     capture_clk,

   // Processor 100 MHz clock, maybe needed for synchronization?
   input wire 	     bus_clk,

   // ### currently we just always output continuously, regardless of
   // whether there is any new data available or not.  We ignore
   // dac_empty (whether there is data in the FIFO), but hold this
   // module in reset when the DAC pipe is not open.

   // Input from Xillybus, true if the DAC pipe is open (bus_clk domain).
   input wire 	     dac_open_bus,

   // FIFO interface
   output reg 	     dac_rden,
   input wire [31:0] dac_fifo_data,
   input wire 	     dac_empty
   );

   // True when DAC data pipe is not open.
   wire 	     reset;
   
   // Output shifter. Data goes out MSB first, so gets shifted left, shifting
   // in zeros.  When all the data has been sent we keep shifting in and
   // sending zeros.  Data is loaded in [23:0], with bit 24 zero.  Bit 24 is
   // the dummy bit at the beginning each L/R word in I2S format.
   reg [24:0] 	     dac_shifter = 0;
	     
   // How many capture_clk (SCK) cycles for each output sample. Only certain
   // values are supported by DAC (they are all even).  The DAC automatically
   // figures out which divisor you are using.
   //
   // The 512 divisor is more or less forced by need for synchronous ADC and
   // DAC sample rates.  It has to be bigger than 256 in order for there to be
   // enough clocks for the ADC.  We only need 2 channels * 25 bits (with
   // dummy) * 2 SCK/BCK, or 100.  We don't explicitly count pad bits, but if
   // I reckon correctly there are 103 zero pad bits after each 24+1 bit L/R
   // data word.
   parameter lrck_divisor = 512;

   // Where we are in the LRCK cycle.
   reg [9:0] 	     lrck_counter = 0;

   always @(posedge capture_clk) begin
      if (reset) begin
	 // Like we were in right word so that we treat first cycle as left.
	 dac_lrck <= 1; 
	 dac_rden <= 0;
	 lrck_counter <= 0;
      end
      else if (lrck_counter == 0) begin
	 // lrck_counter == 0 means that the new BCK will be negative on this
	 // capture_clk cycle (negative BCK edge).  The other pins (BCK and
	 // DATA) always transition on a negative BCK edge (even
	 // lrck_counter).
	 
	 // -1 because we count 255 down to 0.  Note also that this maintains
	 // the BCK phase, since an odd cycle has to follow an even one
	 // (zero).
	 lrck_counter <= (lrck_divisor / 2) - 1;
	 
	 // LRCK should transition on a negative edge of BCK.  Since counter
	 // is now zero, we are going put out negative edge on this cycle.  So
	 // all is groovy. (The negative edge of the last bit period in the
	 // current L/R output word.)
	 dac_lrck <= ~dac_lrck;

	 if (dac_lrck) begin
	    // LRCK is high, so we are ending a right period (and beginning a
	    // left, moving to the next sample).  Set up new output data.

	    // Truncate the sample from 32 bits down to 24.  Add I2S start pad
	    // bit.
	    dac_shifter <= {1'b0, dac_fifo_data[31:8]};

	    // Read FIFO now so data is ready when we next want it.  We handle
	    // FIFO empty by ignoring it.  According to FIFO doc it is OK to
	    // read when there is no data, and this is a NOOP.  So I expect
	    // this will keep clocking out the last sample over and over (or
	    // whatever the initial dac_data contents are).
	    dac_rden <= 1;
	 end
	 else begin
	    // If we are in a left period (so are beginning a right) then we
	    // don't do anything, just leave zeros in the dac_shifter.
	    // ### right channel support goes here
	    dac_rden <= 0;
	 end
      end
      else begin
	 dac_rden <= 0;
	 
	 lrck_counter <= lrck_counter - 1;
	 if (lrck_counter[0])
	    // New data is shifted out on negative edge of BCK.  Counter is
	    // odd now, so new BCK is low (negative edge).
	   dac_shifter <= {dac_shifter[23:0], 1'b0};
      end

      // These guys just always keep rolling.
      dac_bck <= lrck_counter[0];
      dac_data[0] <= dac_shifter[24];
   end

   
   /// Xillybus stuff:


   // Clock crossing logic: bus_clk -> capture_clk
   (* ASYNC_REG = "TRUE" *) reg dac_open = 0;
   (* ASYNC_REG = "TRUE" *) reg dac_open_cross = 0;
   always @(posedge capture_clk)
     begin
	dac_open_cross <= dac_open_bus;
	dac_open <= dac_open_cross;
     end

   // We hold the DAC interface in reset when the DAC pipe is not open.
   assign reset = ~dac_open;

endmodule
