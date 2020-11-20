// This module de-interleaves data on the 32 bit write FIFO into seperate
// words for each DAC channel (there are four).  This is split off from the
// DAC drivers because we have two DACs, the normal output DAC to the source,
// and the BIST DAC.  We only use one at a time, so we can multiplex the
// FIFO.
//
// We always read 4 words.  Our state (what word we think we are reading) is
// reset whenever the DAC FIFO is closed, to ensure that our words are
// correctly aligned on the intended channels.  We implement double buffering
// so that the dac_data words all update simultaneously, representing a single
// multi-channel sample.
//
// Note that we have to allow DAC data to buffer up in the FIFO (and in the
// operating system buffer).  We only read data from the FIFO when the DAC is
// ready for a new sample.  The output process always writes data as fast as
// it can.  The Xillybus write FIFO implements flow control and stalls the
// output process when the FIFO fills up, which is how the ILEMT software
// synchronizes with the sample rate.

// [On the output side the latency hardly matters because the source drive
// signal changes very little (currently not at all).  But we will want to
// keep the total OS buffering just large enough to prevent data underruns on
// the output.]
//
// [It would be possible to generate a new Xillybus core with two or more 32
// bit write FIFOs, but there does not seem to be any point, because AFAICT
// there would be no use in driving both the source output and the input BIST
// at the same time.]

module dac_buffer_reg
  (
   // Data acqusition clock, used to clock this module.
   input wire 	     capture_clk,

   // Processor 100 MHz clock, for synchronization with Xillybus.
   input wire 	     bus_clk,

   // The four current output samples (one per channel) available to the DACs.
   // All the data is updated in a single capture_clk cycle (on dac_request);
   // implementing this atomic update is the main function of this module.
   output reg [31:0] dac_buffer [0:dac_channels-1];

   // We implement a two-step handshake.  The enabled DAC asserts dac_request
   // for one capture_clk cycle when it is ready for a new sample.  We assert
   // dac_data_ready for one cycle once dac_buffer is filled.
   //
   // Limitations/specifics: immediately on dac_request we transfer the
   // internal buffer to dac_buffer and assert dac_buffer_ready (unless there
   // was an underrun, see dac_underrun).  dac_request is ignored during the 4
   // capture_clk cycles after a preceding daq_request (which is when we are
   // reading the next sample).
   input wire 	     dac_request;
   output reg 	     dac_buffer_ready;
   
   // We assert this for one cycle on each sample period where we went to read
   // the FIFO and found it was empty.  If there was an underrun, then
   // dac_buffer_ready is suppressed and dac_request does *not* copy whatever
   // (possibly partial data) has been read.  Instead, the last valid output
   // is latched.  But we do still attempt to read another sample.  The read
   // attempts proceed at the sample rate, paced by dac_request.
   output reg 	     dac_underrun;

   // True if the DAC pipe is open.  The DAC drivers should be held in reset
   // when the pipe is not open.  This can also be used to trigger start of
   // the read acquisition, synchronizing the output and input streams.
   output reg 	     dac_open;

   // Input from Xillybus, true if the DAC pipe is open (bus_clk domain).
   input wire 	     dac_open_bus,

   // FIFO interface
   output reg 	     dac_rden,
   input wire [31:0] dac_fifo_data,
   input wire 	     dac_empty
   );

`include "adc_params.v"

   // How many words to read for this sample. Ranges 4..0, when 0 we are done
   // reading (and are ready for the next dac_request).
   reg [2:0] 	     in_counter;

   // New data which we are reading now.  This is transferred to dac_buffer on
   // dac_request.
   output reg [31:0] new_data [0:dac_channels-1];

   // True if there was an undderrun for one of the reads on this sample.
   reg 		     was_underrun;
   
   // We reset if the dac pipe is not open.
   wire reset = ~dac_open;

   always @(posedge capture_clk) begin
      if (reset) begin
	 in_counter <= 0;
	 dac_rden <= 0;
	 dac_underrun <= 0;
	 was_underrun <= 0;
	 dac_buffer_ready <= 0;
      end
      else begin
	 if (in_counter != 0) begin
	    // we are now reading data, slap it into our internal buffer.
	    wire next_count = in_counter - 1;
	    in_counter <= next_count;
	    new_data[next_count] <= dac_fifo_data;
	    dac_rden <= (next_count != 0);
	    dac_underrun <= 0;
	    was_underrun <= (was_underrun | dac_empty);
	    dac_buffer_ready <= 0;
	 end
	 else if (dac_request) begin
	    // Data has been requested.

	    // Flag any underrun on the new sample.
	    dac_buffer_ready <= ~was_underrun;
	    dac_underrun <= was_underrun;
	    was_underrun <= dac_empty;

	    // Only copy the data if there was not an underrun.  This will
	    // latch the last valid sample.
	    if (!was_underrun)
	      generate
		 genvar chan;
		 for (chan = 0; chan < dac_channels; chan++)
		   dac_buffer[chan] <= new_data[chan];
	      endgenerate

	    // start fetching the next sample from the FIFO.
	    in_counter <= dac_channels;
	    dac_rden <= 1;
	 end
	 else begin
	    // Not reading data, not requesting.  Do nothing.
	 end
      end
   end

      
   // Clock crossing logic: bus_clk -> capture_clk
   (* ASYNC_REG = "TRUE" *) reg dac_open = 0;
   (* ASYNC_REG = "TRUE" *) reg dac_open_cross = 0;
   always @(posedge capture_clk)
     begin
	dac_open_cross <= dac_open_bus;
	dac_open <= dac_open_cross;
     end

endmodule
