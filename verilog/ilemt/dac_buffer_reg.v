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
// ready for a new sample.  The Linux output process always writes data as
// fast as it can.  The Xillybus write FIFO implements flow control and stalls
// the Linux process when the FIFO fills up, which is how the ILEMT software
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
   input wire 				capture_clk,

   // Processor 100 MHz clock, for synchronization with Xillybus.
   input wire 				bus_clk,

   // The four current output samples (one per channel) available to the DACs.
   // All the data is updated in a single capture_clk cycle (on dac_request);
   // implementing this atomic update is the main function of this module.  I
   // would implement this as an array, but Verilog 2001 doesn't support that.
   // Channel 0 is stored in 4*32 - 1:3*32, channel 1 in 3*32 - 1:2*32, etc.
   output reg [dac_channels*32 - 1 : 0] dac_buffer,

   // The enabled DAC asserts dac_request for one capture_clk cycle when it is
   // ready for a new sample.  Immediately on dac_request we transfer the
   // internal buffer to dac_buffer.  Don't assert dac_request again during
   // the 4 capture_clk cycles after a preceding dac_request (which is when we
   // are reading the next sample).
   input wire 				dac_request,
   
   // We assert this for one cycle on each sample period where we went to read
   // the FIFO and found it was empty.  If there was an underrun, then
   // dac_request does *not* copy whatever (possibly partial data) has been
   // read.  Instead, the last valid output is latched.  But we do still
   // attempt to read another sample.  We continue with further read attempts,
   // at the sample rate (as paced by dac_request).
   output reg 				dac_underrun,

   // True if we are ready for the first daq_request.  The DAC pipe is open
   // and the FIFO has been non-empty at least once.  The DAC drivers should
   // be held in reset when not open.  This can also be used to trigger start
   // of the read acquisition, synchronizing the output and input streams.
   //
   // We add the non-empty requirement (as in the Xillybus templates) because
   // there is likely a delay between the time that the pipe is opened and
   // when the first data shows up.  We don't want to start output until there
   // we have some data because that will compromise the synchronization from
   // output to input, and also generate spurious underrun errors.
   output reg 				dac_open,

   // Low bits of channel 0 of the last sample put out, used to test
   // output/input synchronization.  These bits are not used by either DAC or
   // ADC.
   output reg [7:0] 			sync_tag,


   // Input from Xillybus, true if the DAC pipe is open (bus_clk domain).
   input wire 				dac_fifo_open_bus,

   // FIFO interface
   output reg 				dac_rden,
   input wire [31:0] 			dac_fifo_data,
   input wire 				dac_empty
   );

`include "adc_params.v"

   /// State machine:
   parameter reset_state = 0;  // In reset, FIFO not open
   parameter empty_state = 1;  // Waiting for first data to arrive
   parameter start_state = 2;  // Start first FIFO read
   parameter fifo_state = 3;   // Reading from FIFO
   parameter last_state = 4;   // Loading last channel from FIFO
   parameter wait_state = 5;   // Waiting for next read request
   reg [2:0] state = reset_state;

   // Index in new_data, the next channel to read from FIFO
   reg [1:0] in_index;

   // New data which we are reading now.  This is transferred to dac_buffer on
   // dac_request.
   reg [31:0] new_data [0:3];

   // True if there was an underrun for one of the reads on the sample that
   // should have been in new_data.
   reg was_underrun;

   // If true, load fifo data into new_data.  The previous state is
   // fifo_state.
   reg load_new;

   // dac_buffer datapaths
   always @(posedge capture_clk) begin
      // dac_request directly latches new_data into the output so that it is
      // ready on the next cycle.  This is inhibited if there was an underrun.
      if (dac_request && !was_underrun) begin
	 dac_buffer <= {new_data[0], new_data[1], new_data[2], new_data[3]};
	 sync_tag <= new_data[0][7:0];
      end

      // If we just read the FIFO, then store it into new_data.
      if (load_new) begin
	 new_data[in_index] <= dac_fifo_data;
	 in_index <= in_index + 1;
      end
      else begin
	 // Except in the case of reset this is redundant (because we have
	 // wrapped to zero), but this makes it clearer what index we are
	 // writing to above.
	 in_index <= 0;
      end
   end


   /// FIFO open synchronizer:

   // Clock crossing logic: bus_clk -> capture_clk
   (* ASYNC_REG = "TRUE" *) reg dac_fifo_open_cross = 0;
   (* ASYNC_REG = "TRUE" *) reg dac_fifo_open = 0;
   always @(posedge capture_clk)
     begin
	dac_fifo_open_cross <= dac_fifo_open_bus;
	dac_fifo_open <= dac_fifo_open_cross;
     end

   
   /// State machine:
   //
   // Reading from the FIFO is one sample ahead of the output buffer.  We
   // always start reading a new sample as soon as the one we've got is
   // requested.  We read right after enable (without any waiting) because we
   // need to have a sample ready when the request comes in.  There should
   // always be many samples in the FIFO, so reading ahead will not cause
   // spurious underruns.
   always @(posedge capture_clk) begin
      case (state)
	reset_state: begin
	   // Output ports:
	   // dac_buffer: not initialized on reset
	   // dac_buffer_ready: set in the dac_buffer latch above
	   dac_underrun <= 0;
	   dac_open <= 0;
	   dac_rden <= 0;

	   // Local state
	   load_new <= 0;
	   
	   was_underrun <= 0;
	   
	   if (dac_fifo_open)
	     state <= empty_state;
	end

	empty_state: begin
	   // This is a post-reset state, not one we go thru in normal
	   // operation.  We wait here for first data to become available (so
	   // we don't get spurious underrun).  After this the state machine
	   // handles dac_empty by generating an underrun.
	   if (!dac_empty)
	     state <= start_state;
	end

	start_state: begin
	   // Start of normal operation state sequence.  This starts the FIFO
	   // read of channel 0 for the new sample.
	   if (dac_fifo_open) begin
	      dac_rden <= 1;
	      was_underrun <= dac_empty;
	      state <= fifo_state;
	   end
	   else begin
	      // If FIFO has closed, then go back into reset.  We don't need
	      // to check in every state as long as we notice in a timely way.
	      state <= reset_state;
	   end
	   load_new <= 0;
	end

	fifo_state: begin
	   // We are now reading data.
	   if (in_index == dac_channels - 2) begin
	      // Load of last channel is now underway, so go to last_state.
	      // We do not have anymore FIFO data to read, so turn off
	      // dac_rden.
	      dac_rden <= 0;
	      state <= last_state;
	   end
	   else begin
	      dac_rden <= 1;
	      was_underrun <= (was_underrun | dac_empty);
	   end
	   // On the next cycle new_data[in_index] will be set to
	   // dac_fifo_data (in datapath latch above).
	   load_new <= 1;
	end

	last_state: begin
	   // This state delays for one cycle while we wait for the new_data
	   // load of the last channel to complete.
	   load_new <= 0;
	   state <= wait_state;
	end

	wait_state: begin
	   // Waiting for dac_request

	   // Delay our dac_open output until now so that we do not get a
	   // request until we are ready for it.
	   dac_open <= 1;
	   if (dac_request) begin
	      // Data has been requested.  dac_request also triggers the
	      // datapath latch to transfer new_data to dac_buffer on this
	      // same cycle that we get here.

	      // Flag any underrun on now-being-loaded dac_buffer sample.
	      dac_underrun <= was_underrun;

	      // Start reading next sample
	      state <= start_state;
	   end
	   load_new <= 0;
	end

	default: begin
	   state <= reset_state;
	end
      endcase
   end // always (posedge capture_clk)

endmodule
