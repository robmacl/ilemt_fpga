// Interface to TI DAC80004 Built In Self-Test (BIST) DAC on the ILEMT main
// board.  This is a quad 16 bit DAC which can inject signal into the inputs
// on the input board.
//
// Our input dac_buffer 32 bit, but we discard the low 16 bits.
//
// The BIST DAC functions as an alternate destination for DAC data, instead of
// the normal output DAC on the DAC board.  We can do this because it doesn't
// make any sense to run both at the same time.  This file is derived from
// multi_dac_interface.v, see there for discussion of sample timing.
//
// One particular requirement for the BIST DAC is that when not in use we must
// drive the outputs to particular values so that BIST is disengaged.  This
// requires writing to the DACs on reset and when we go idle.  Channels 0 and
// 2 ("A" and "C") are set to zero, and channels 1 and 3 ("B" and "D") to all
// ones.
//
// The mapping between the ADC channels and BIST signals is:
//     Number	Letter	Signal
//     0	A	BIST++
//     1	B	BIST+-
//     2	C	BIST-+
//     3	D	BIST--
//
// See the schematic for the main board and input board for more details, but
// briefly, how BIST works is that a signal can be injected into both the
// positive and negative differential sides of the sensor input.  BIST++ and
// BIST+- inject the positive input and BIST-+, BIST-- inject the negative.
// There are two signals for each to implement the BIST disconnection during
// normal operation.  For eg. the positive input, BIST++ can only source
// current, and BIST+- can only sink current.  If you drive both together,
// then you can inject a signal.  If you drive them to the opposite rails then
// they are effectively disconnected.
//
// The BIST signals are 0..5V and are injected through a 10K resistor.  The
// actual signal seen at the input varies depending on what impedance is
// present at the input.  In particular, if there is a sensor, then its
// impedance is low compared to 10K, and significantly loads down the
// differential signal.
//
module bist_dac_interface
  (
   // Data acqusition clock.  This is the same frequency as the DAC SCK,
   // SYSCLK/4, but there is no particular phase relationship because the DAC
   // board has its own hardware divider.  See adc_params.v for discussion of
   // clocking.
   input wire 				capture_clk,

   // When true, reset our state and hold outputs at fixed values.  Behavior
   // when we exit reset depends on "enable".  ilemt.v asserts "reset" whenever
   // the DAC FIFO is not open.  This insures that we will always disable BIST
   // when the software starts up (and opens the DAC fifo).
   input wire 				reset,

   // If "enable" is true (and not in reset), then we are writing BIST data,
   // and are in control of the dac_buffer_reg().  If "enable" is false when
   // we exit reset, or if it goes negative, then we disable BIST by writing
   // the DACs to 0 and full scale, and then go idle.
   input wire 				enable,

   // The four current output samples (one per channel) that we are to send to
   // the DACs.
   input wire [32*dac_channels - 1 : 0] dac_buffer,

   // Request new data from dac_buffer_reg()
   output reg 				dac_request,

   
   /// IO pins used for DAC interface (all are outputs):

   // This synchronizes the DAC serial interface so it is shifting in the bits
   // that we expect.  This is active low, so should really be called
   // BIST_NOT_SYNC.  We synchronize for every output sample to insure we stay
   // in synch.
   output reg 				BIST_SYNC,

   // SPI output data and clock.  New data goes out on the rising edge of SCLK
   // and is clocked on the falling edge.  The clock rate is capture_clk/2.
   output reg 				BIST_MOSI,
   output reg 				BIST_SCLK,
   );

`include "adc_params.v"

   // OK, this is a way to deal with the nuisance of indexing the
   // bit-flattened dac_buffer.  We assign wires that select each word,
   // discarding the low bits that we don't want.
   wire [15:0] dac_buffer0 = dac_buffer[(4*32 - 1):(3*32 + 16)];
   wire [15:0] dac_buffer1 = dac_buffer[(3*32 - 1):(2*32 + 16)];
   wire [15:0] dac_buffer2 = dac_buffer[(2*32 - 1):(1*32 + 16)];
   wire [15:0] dac_buffer3 = dac_buffer[(1*32 - 1):(0*32 + 16)];

   // The DAC write logic functions independently from the dac_buffer[] since
   // we need to be able to write a dummy sample to the DAC to disable BIST.

   // When we are writing BIST data, we pace the output sample rate (to match
   // the ADC input rate), just as multi_dac_interface() does.

   // The DAC SPI interface has details (see datasheet), but the basic idea is
   // that there is a 32 bit register we write, and this has a data word for a
   // single channel, a channel index, and various control bits.  For the
   // first 3 words we use command bits 0000, and for the last word we use
   // 0010 to transfer the sample to the DACs.

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
