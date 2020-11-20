// Interface to TI PCM1794A on the ILEMT DAC board.  We implement four output
// channels using 2 dual channel DACs.  We are using I2S data format, 24 bit.
// Our input dac_buffer 32 bit, but we discard the low 8 bits.
//
// The DAC sample rate has to be the same as the ADC (decimated) sample rate,
// and the DAC board derives its clean system clock (SCK) by a hardware divide
// by 4 from the system master clock (SYSCLK on main board).  This forces
// various decisions related to clocking, see below and in adc_params.v.
//
// The DAC board pin straps these configuration flags: 
//   {MONO, CHSL, FMT1, FMT0} = 4'b0000
//
// This selects stereo, I2S, sharp output filter rolloff.
//
// ### implement reset control.  Should add delay after reset.
module multi_dac_interface
  (
   // Data acqusition clock.  This is the same frequency as the DAC SCK,
   // SYSCLK/4, but there is no particular phase relationship because the DAC
   // board has its own hardware divider.  See adc_params.v for discussion of
   // clocking.
   input wire 		      capture_clk,

   // Is this DAC enabled?  We hold ourselves in reset when not enabled.
   input wire 		      enable;

   // The four current output samples (one per channel) that we are to write.
   input wire [31:0] 	      dac_buffer [0:dac_channels-1];

   // Request new data from dac_buffer_reg()
   output reg 		      dac_request;

   
   /// IO pins used for DAC interface (all are outputs):

   // Serial data bit clock.  The DAC clocks data on the rising edge of BCK.
   // Frequency is half of capture_clk.  We run BCK continuously (when we are
   // not in reset), sending zero pad data when we have finished the actual
   // data.  There are many excess bit periods in every LRCK window (see
   // lrck_divisor below).
   output reg 		      dac_bck,

   // Serial data pins for the two DACs.  The left and right channels are
   // interleaved, giving the four output channels.  Serial data is MSB first,
   // followed by zero pad data.  In I2S the first posedge on BCK is a dummy
   // bit, see below.
   output reg [dac_chips-1:0] dac_data_pins,

   // The Left/Right Clock pin.  The rising and trailing edges of LRCK tell
   // the DAC when to latch data.  The left data is transferred when
   // LRCK is low, so the left data is *latched* by DAC on the positive edge.
   // I imagine that the data is clocked into the channel DACs simultaneously,
   // on the negative edge of LRCK (after the right sample data word is
   // complete).  LRCK transitions on a negative edge of BCK, the last bit
   // period of the sample.  (No actual data is transmitted in this last bit
   // period because in I2S the data is at the beginning of the LR window,
   // left justified.)  The full sample period is left channel then right, so
   // the first LRCK phase is low.
   // 
   // [The LRCK rate is how the DAC learns what the sample rate is, but I am
   // operating under the assumption that the actual sample clock is the
   // system clock SCK.  It has logic to figure out which of several clock
   // divisors are being used.]
   output reg 		      dac_lrck,

   // Reset signal, output pin to DACs (negated).
   output reg 		      dac_not_rst,
   );

`include "adc_params.v"

   // The number of DAC chips.  This is used for documentation, you can't just
   // go and change this parameter without other changes.
   parameter dac_chips = 2;
   
   // We reset if we are not enabled.
   wire reset = ~enable;
   
   // Output shifters.  Data goes out MSB first, so gets shifted left,
   // shifting in zeros.  When all the data has been sent we keep shifting in
   // and sending zeros.  Data is loaded in [23:0], with bit 24 zero.  Bit 24
   // is the dummy bit at the beginning each L/R word in I2S format.
   reg [24:0] dac_shifter [0:dac_chips-1];
   
   // How many capture_clk (SCK) cycles for each output sample. Only certain
   // values are supported by DAC (they are all even).  The DAC automatically
   // figures out which divisor you are using.
   //
   // The 512 divisor is more or less forced by need for synchronous ADC and
   // DAC sample rates.  It has to be bigger than 256 in order for there to be
   // enough clocks for the ADC.  We only need 2 channels * 25 bits (with
   // dummy) * 2 SCK/BCK, or 100.  We don't explicitly count pad bits, but if
   // I reckon correctly there are 103 zero pad bits after each 24+1 bit L/R
   // data word.  See adc_params.v
   parameter lrck_divisor = 512;

   // Counts down by capture_clk cycles in order to time the LRCK half-cycles.
   // We generate a LRCK edge when this hits 0.
   reg [9:0] lrck_counter = 0;

   always @(posedge capture_clk) begin
      if (reset) begin
	 dac_bck <= 0;
	 dac_data_pins <= 0;
	 
	 // Initialize like we were in a right word so that we treat first
	 // cycle as left.
	 dac_lrck <= 1; 
	 lrck_counter <= 0;

	 dac_request <= 0;
      end
      else if (lrck_counter == 0) begin
	 // lrck_counter == 0 means that the new BCK will be negative on this
	 // capture_clk cycle (negative BCK edge).  The other pins (BCK and
	 // DATA) always transition on a negative BCK edge (even
	 // lrck_counter).
	 
	 // -1 because we count 255 down to 0.  /2 because we are timing LRCK
	 // half-cycles.  Another way to see the need for -1 is that BCK is
	 // generated from the LRCK LSB, and an odd cycle has to follow an
	 // even one (zero) in order for BCK to be continuous.
	 lrck_counter <= (lrck_divisor / 2) - 1;
	 
	 // LRCK should transition on a negative edge of BCK.  Since counter
	 // is now zero, we are going put out negative edge on this cycle.  So
	 // all is groovy. (The negative edge of the last bit period in the
	 // current L/R output word.)
	 dac_lrck <= ~dac_lrck;

	 if (dac_lrck) begin
	    // LRCK is high, so we are ending a right period (and beginning a
	    // left, moving to the next sample).  Set up new output data.  We
	    // are writing both left words, which is channels 0 and 2.

	    // The shifters truncate the sample from 32 bits down to 24 and
	    // include the I2S start pad bit.
	    dac_shifter[0] <= {1'b0, dac_buffer[0][31:8]};
	    dac_shifter[1] <= {1'b0, dac_buffer[2][31:8]};

	    // Request new output data from the buffer so it data is ready
	    // when we next want it.
	    dac_request <= 1;
	 end
	 else begin
	    // We are in a left period (so are beginning a right).  Load
	    // shifters with the right-channel data, channels 1 and 3.
	    dac_shifter[0] <= {1'b0, dac_buffer[1][31:8]};
	    dac_shifter[1] <= {1'b0, dac_buffer[3][31:8]};
	    dac_request <= 0;
	 end
      end
      else begin
	 dac_request <= 0;
	 
	 lrck_counter <= lrck_counter - 1;
	 if (lrck_counter[0]) begin
	    // New data is shifted out on negative edge of BCK.  Counter is
	    // odd now, so new BCK is low (negative edge).
	    dac_shifter[0] <= {dac_shifter[0][23:0], 1'b0};
	    dac_shifter[1] <= {dac_shifter[1][23:0], 1'b0};
      end

      // These guys just always keep rolling (when we are not in reset).
      dac_bck <= lrck_counter[0];
      dac_data_pins <= {dac_shifter[0][24], dac_shifter[1][24]};
   end

endmodule
