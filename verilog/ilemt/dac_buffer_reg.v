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
   input wire 	     capture_clk,

   // Processor 100 MHz clock, for synchronization with Xillybus.
   input wire 	     bus_clk,

   // The four current output samples (one per channel) available to the DACs.
   // All the data is updated in a single capture_clk cycle (on dac_request);
   // implementing this atomic update is the main function of this module.  I
   // would implement this as an array, but Verilog 2001 doesn't support that.
   // Channel 0 is stored in 4*32 - 1:3*32, channel 1 in 3*32 - 1:2*32, etc.
   output reg [dac_channels*32 - 1 : 0] dac_buffer,

   // We implement a two-step handshake.  The enabled DAC asserts dac_request
   // for one capture_clk cycle when it is ready for a new sample.  We assert
   // dac_data_ready for one cycle once dac_buffer is filled.
   //
   // Limitations/specifics: immediately on dac_request we transfer the
   // internal buffer to dac_buffer and assert dac_buffer_ready (unless there
   // was an underrun, see dac_underrun).  dac_request is ignored during the 4
   // capture_clk cycles after a preceding dac_request (which is when we are
   // reading the next sample).
   input wire 	     dac_request,
   output reg 	     dac_buffer_ready,
   
   // We assert this for one cycle on each sample period where we went to read
   // the FIFO and found it was empty.  If there was an underrun, then
   // dac_buffer_ready is suppressed and dac_request does *not* copy whatever
   // (possibly partial data) has been read.  Instead, the last valid output
   // is latched.  But we do still attempt to read another sample.  We
   // continue with further read attempts, at the sample rate (as paced by
   // dac_request).
   output reg 	     dac_underrun,

   // True if the DAC pipe is open and the FIFO has been non-empty at least
   // once.  The DAC drivers should be held in reset when not open.  This can
   // also be used to trigger start of the read acquisition, synchronizing the
   // output and input streams.
   //
   // We add the non-empty requirement (as in the Xillybus templates) because
   // there is likely a delay between the time that the pipe is opened and
   // when the first data shows up.  We don't want to start output until there
   // we have some data because that will compromise the synchronization from
   // output to input, and also generate spurious underrun errors.
   output reg 	     dac_open,

   // Input from Xillybus, true if the DAC pipe is open (bus_clk domain).
   input wire 	     dac_open_bus,

   // FIFO interface
   output reg 	     dac_rden,
   input wire [31:0] dac_fifo_data,
   input wire 	     dac_empty
   );

`include "adc_params.v"

   /// State machine:

   // Index in new_data, the next channel to read from FIFO
   reg [1:0] in_index;

   // New data which we are reading now.  This is transferred to dac_buffer on
   // dac_request.
   reg [31:0] new_data [0:3];

   // True if there was an undderrun for one of the reads on this sample.
   reg was_underrun;

   // Asserted for one cycle to indicate that new_data is ready, and should be
   // loaded into the output buffer.
   reg 	load_buffer;

   // dac_buffer latch datapath
   always @(posedge capture_clk) begin
      if (load_buffer) begin
	 dac_buffer <= {new_data[0], new_data[1], new_data[2], new_data[3]};
      	 dac_buffer_ready <= 1;
      end
      else begin
	 dac_buffer_ready <= 0;
      end
      
      // We can always set new_data because it is harmless to copy
      // dac_fifo_data more than once.  We just need to increment in_index on
      // the same cycle we assert dac_rden so that the final value is correct.
      // 
      // Writing the new_data memory here keeps the datapath out of the state
      // machine.
      new_data[in_index] <= dac_fifo_data;
   end
    
   /// State machine:
   //
   // Reading from the FIFO is one sample ahead of the output buffer.  We
   // always start reading a new sample as soon as the one we've got is
   // requested.  We read right after enable (without any waiting) because we
   // need to have a sample ready when the request comes in.  There should
   // always be many samples in the FIFO, so reading ahead will not cause
   // spurious underruns.
   parameter reset_state = 0;  // In reset
   parameter start_state = 1;  // Start first FIFO read
   parameter fifo_state = 2;   // Reading from FIFO
   parameter wait_state = 3;   // Waiting for next read request
   reg state = reset_state;

   always @(posedge capture_clk) begin
      if (!dac_open && state != reset_state) begin
	 state <= reset_state;
      end
      else
	case (state)
	  reset_state: begin
	     // Output ports:
	     // dac_buffer: not initialized on reset
	     // dac_buffer_ready: set in the dac_buffer latch above
	     dac_underrun <= 0;
	     // dac_open: set in FIFO open synchronizer below
	     dac_rden <= 0;

	     // Local state
	     in_index <= 0;
	     was_underrun <= 0;
	     load_buffer <= 0;
	     
	     if (dac_open)
	       state <= start_state;
	  end

	  start_state: begin
	     // Delay while output buffer is loaded and also start read of
	     // channel 0.
	     in_index <= 0;
	     dac_rden <= 1;
	     was_underrun <= dac_empty;
	     state <= fifo_state;
	  end

	  fifo_state: begin
	     // we are now reading data: new_data[in_index] has been set to
	     // dac_fifo_data (in dac_buffer_latch above).
	     if (in_index == dac_channels - 1) begin
		dac_rden <= 0;
		state <= wait_state;
	     end
	     else begin
		dac_rden <= 1;
		was_underrun <= (was_underrun | dac_empty);
	     end
	     in_index <= in_index + 1;
	  end

	  wait_state: begin
	     if (dac_request) begin
		// Data has been requested.

		// Flag any underrun on the new sample.
		dac_underrun <= was_underrun;

		// Maybe initiate transfer.
		load_buffer <= ~was_underrun;

		// Start reading next sample
		state <= start_state;
	     end
	  end

	  default: begin
	     state <= reset_state;
	  end
	endcase
   end // always (posedge capture_clk)


   /// FIFO open synchronizer:

   // Has the FIFO been non-empty since reset ended?
   reg saw_nonempty = 0;
   
   // Clock crossing logic: bus_clk -> capture_clk
   (* ASYNC_REG = "TRUE" *) reg dac_open_cross1 = 0;
   (* ASYNC_REG = "TRUE" *) reg dac_open_cross2 = 0;
   always @(posedge capture_clk)
     begin
	dac_open_cross1 <= dac_open_bus;
	dac_open_cross2 <= dac_open_cross1;
	dac_open <= dac_open_cross2 & saw_nonempty;

	if (state == reset_state)
	  saw_nonempty <= 0;
	else
	  saw_nonempty <= ~dac_empty | saw_nonempty;
     end

endmodule
