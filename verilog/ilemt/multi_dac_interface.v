// Interface to TI PCM1794A on the ILEMT DAC board.
//
// We implement four output channels using 2 dual channel DACs (chip 0 and
// chip 1).  I am using the channel mapping where channels 0..3 are in
// sequence 0R 0L 1R 1L.  That is, the DAC chips are in channel order, and
// within a chip, right is a lower channel than left.  We are using I2S data
// format, 24 bit, so the left channel is set first.
//
//Our input dac_buffer 32 bit, but we discard the low 8 bits.
//
// The DAC sample rate has to be the same as the ADC (decimated) sample rate,
// and the DAC board derives its clean system clock (SCK) by a hardware divide
// by 4 from the system master clock (SYSCLK on main board).  This forces
// various decisions related to clocking, see below and in adc_params.v.
//
// The DAC board pin-straps these configuration flags: 
//   {MONO, CHSL, FMT1, FMT0} = 4'b0000
//
// This selects stereo, I2S, sharp output filter rolloff.
//
module multi_dac_interface
  (
   // Data acqusition clock.  This is the same frequency as the DAC SCK,
   // SYSCLK/4, but there is no particular phase relationship because the DAC
   // board has its own hardware divider.  See adc_params.v for discussion of
   // clocking.
   input wire 		      capture_clk,

   // Is this DAC enabled?  We hold ourselves in reset when not enabled.
   input wire 		      enable,

   // The four current output samples (one per channel) that we are to send to
   // the DACs.
   // 
   // Note: you will get many (32?) warnings about unconnected ports, since we
   // only use 24 of 32 bits on each channel.
   input wire [32*dac_channels - 1 : 0] dac_buffer,

   // Request new data from dac_buffer_reg()
   output reg 		      dac_request,

   
   /// IO pins used for DAC interface (all are outputs):

   // Serial data bit clock.  The DAC clocks data on the rising edge of BCK.
   // Frequency is half of capture_clk.  We run BCK continuously (when we are
   // not in reset), sending zero pad data when we have finished the actual
   // data.  There are many excess bit periods in every LRCK window (see
   // lrck_divisor below).
   output reg 		      DAC_BCK,

   // Serial data pins for the two DACs.  The left and right channels are
   // interleaved, giving the four output channels.  Serial data is MSB first,
   // followed by zero pad data.  In I2S the first posedge on BCK is a dummy
   // bit, see below.
   output reg [0:dac_chips-1] DAC_DATA_PINS,

   // The Left/Right Clock pin.  The left data is transferred when LRCK is
   // low.  The rising and falling edges of LRCK tell the DAC when to latch
   // data, so the left data is *latched* by DAC on the positive edge.
   //
   // I imagine that the data is clocked into the channel DACs simultaneously,
   // on the negative edge of LRCK (after the right sample data word is
   // complete).
   //
   // LRCK transitions on a negative edge of BCK, the last bit period of the
   // sample.  (No actual data is transmitted in this last bit period because
   // in I2S the data is at the beginning of the LR window, left justified.)
   // The full sample period is left channel then right, so the first LRCK
   // phase is low.
   // 
   // [The LRCK rate is how the DAC learns what the sample rate is, but I am
   // operating under the assumption that the actual sample clock is the
   // system clock SCK.  The chip has logic to figure out which of several
   // clock divisors are being used.]
   output reg 		      DAC_LRCK,

   // Reset signal, output pin to DACs (negated).
   // 
   // ### Datasheet says that the DAC is not done resetting until 1024 SCK
   // after posedge ~RST.  At least for now we are ignoring this, and will
   // start clocking out data right away.  This will likely cause the first 2
   // samples to not be output correctly, which would not be a problem.
   // 
   // ### It would be nice if the DAC outputs are zero when we are in reset,
   // not sure whether the ~RST reset forces this.
   //
   // ### currently we write undefined data for the first LRCK cycle anyway
   // because we don't dac_request until after the first sample.
   output reg 		      DAC_NOT_RST
   );

`include "adc_params.v"

   // The number of DAC chips.  This is used for documentation, you can't just
   // go and change this parameter without other changes.
   parameter dac_chips = 2;
   
   // Output shifters.  Data goes out MSB first, so gets shifted left,
   // shifting in zeros.  When all the data has been sent we keep shifting in
   // and sending zeros.  Data is loaded in [23:0], with bit 24 zero.  Bit 24
   // is the dummy bit at the beginning each L/R word in I2S format.
   reg [24:0] dac_shifter [0:dac_chips-1];
   
   // lrck_divisor is how many capture_clk (SCK) cycles for each output
   // sample.  Only certain values are supported by DAC (they are all even).
   // The DAC internally figures out which divisor you are using.
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

   // OK, this is a way to deal with the nuisance of indexing the
   // bit-flattened dac_buffer.  We assign wires that select each word,
   // discarding the low bits that we don't want.
   wire [23:0] dac_buffer0 = dac_buffer[(4*32 - 1):(3*32 + 8)];
   wire [23:0] dac_buffer1 = dac_buffer[(3*32 - 1):(2*32 + 8)];
   wire [23:0] dac_buffer2 = dac_buffer[(2*32 - 1):(1*32 + 8)];
   wire [23:0] dac_buffer3 = dac_buffer[(1*32 - 1):(0*32 + 8)];

   always @(posedge capture_clk) begin
      if (!enable) begin
	 // Reset the DAC
	 DAC_NOT_RST <= 0;
	 DAC_BCK <= 0;
	 DAC_DATA_PINS <= 0;
	 
	 // Initialize like we were in a right word so that we treat first
	 // cycle as left.
	 DAC_LRCK <= 1; 
	 lrck_counter <= 0;

	 dac_request <= 0;
      end
      else if (lrck_counter == 0) begin
	 // Not in reset, At a LRCK edge.
	 DAC_NOT_RST <= 1;

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
	 DAC_LRCK <= ~DAC_LRCK;

	 if (DAC_LRCK) begin
	    // LRCK is high, so we are ending a right period (and beginning a
	    // left, moving to the next sample).  Set up new output data.  We
	    // are writing both left words, which is channels 1 and 3.

	    // The shifters truncate the sample from 32 bits down to 24 and
	    // include the I2S start pad bit.
	    dac_shifter[0] <= {1'b0, dac_buffer1};
	    dac_shifter[1] <= {1'b0, dac_buffer3};
	    dac_request <= 0;
	 end
	 else begin
	    // We are in a left period (so are beginning a right).  Load
	    // shifters with the right-channel data, channels 0 and 2.
	    dac_shifter[0] <= {1'b0, dac_buffer0};
	    dac_shifter[1] <= {1'b0, dac_buffer2};

	    // Request new output data now that we are done with the buffer so
	    // it data is ready when we next want it.
	    dac_request <= 1;
	 end
      end
      else begin
	 // Not in reset, in between LRCK edges
	 DAC_NOT_RST <= 1;

	 dac_request <= 0;
	 lrck_counter <= lrck_counter - 1;
	 if (lrck_counter[0]) begin
	    // New data is shifted out on negative edge of BCK.  Counter is
	    // odd now, so new BCK is low (negative edge).
	    dac_shifter[0] <= {dac_shifter[0][23:0], 1'b0};
	    dac_shifter[1] <= {dac_shifter[1][23:0], 1'b0};
	 end
      end

      // We always send these outputs on BCK and data, but in reset this
      // doesn't generate any output activity because these are always zero.
      DAC_BCK <= lrck_counter[0];
      DAC_DATA_PINS <= {dac_shifter[0][24], dac_shifter[1][24]};
   end // posedge (capture_clk)


endmodule
