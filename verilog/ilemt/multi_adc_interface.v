// Interface to LTC2512-24 (and LTC2500-32 ADCs with parameter tweaks)
//
// This module supports reading multiple ADCs in parallel, using a single
// state machine and clocking for all, with duplication of the input
// datapaths.  After a word is read (on all ADCs in parallel) the result data
// words are clocked out sequentially to the output FIFO.  The input data
// shift registers are double buffered so that we can overlap the FIFO output
// with input acquisition.
//
// The LTC2512-24 and LTC2500-32 are very similar in pinout and internal
// architecture.  The LTC2512 is significantly cheaper, and only supports
// configuring the filter by pin-strapping at a decimation rates of 4, 8, 16,
// 32, and only using the "flat" FIR decimation filter.  The LTC2500 has more
// filter options, and is configured by SPI.  Currently we are using the
// LTC2512 because it is cheaper and seems like it should work just as well
// for us.  I've kept the SPI configuration code in case we want it in the
// future.
//
// NOTE: possibly slightly confusing terminology, but we follow the datasheet
// in using "acquisition" to refer to the process of receiving digital data
// from the ADC, while "conversion" is the actual ADC conversion.  Also
// perhaps confusing: the acquire period (and the quiet period after) is when
// the ADC sample-and-hold is sampling the next analog sample.
//
// The architecture is an oversampling ADC with an internal decimation filter.
// Each conversion cycle is triggered by MCLK.  We only read out the filtered
// data (at the decimated rate), but we need to synchronize acquisition with
// MCLK and SYNC.  For one thing, we are not supposed to be using the SPI bus
// during the conversion time (to reduce noise).  (This reduces the available
// bus bandwidth quite a bit.)
//
// Because the filtered output is only updated every N cycles we can get away
// with shifting out only a few bits on each conversion, and so use a lower
// SPI clock.  This is called "distributed read" in the LTC25xx documentation.
// capture_clk is 2x the SPI clock rate.  This code is designed to work when
// capture_clk is asynchronous wrt bus_clk (or if it is synchronous).
//
// The nominal LTC2512-24 MCLK rate is 1.6 MHz, but the rate can be reduced to
// get the desired conversion rate.  The actual MCLK rate is set by
// capture_clock in combination with convert_cycles and related parameters.
// 

module multi_adc_interface
  (
   /// IO pins and clocks:
   
   /// output clocks and data in common to all ADCs:
   
   // Trigger clock positive edge to start conversion. "For best results, the
   // falling edge of MCLK should occur within 40ns from the start of the
   // conversion, or after the conversion has been completed."  We clear MCLK
   // after the conversion should be done (according to conversion time spec).
   output reg 		adc_mclk,
   // SPI SCK for data ouput
   output reg 		adc_scka,

   // SYNC pulse to synchronize the phase of internal digital filter with the
   // output interface.  This is necessary even when there is only one ADC so
   // that you know which bits are being shifted out.  New data is available
   // every DF conversions after SYNC. This is basically a reset, but SYNC
   // which is consistent with existing phase does no harm.  An additional
   // function is to enable filter programming via SDI.
   output reg 		adc_sync,
   // SPI SDI on ADCs, used to configure.
   output reg 		adc_sdi,

   // SPI SDO for decimated output on each ADC.  The first ADC (IN0_SDOA1) is
   // in bit 0, the MS bit.
   input [0:adc_channels-1] adc_sdoa,

   // capture_clk is the clock for the acquisition process. Frequency may be
   // synthesized to get a particular data rate, or be derived from an
   // external input.  Despite the name, this is much faster than the actual
   // "capture" output rate.  There is only new data when capture_en is
   // asserted.
   // 
   // The SPI clock is 1/2 this.  We keep a modest 16 MHz SPI clock rate and
   // use "distributed read", where we clock out only a few bits for every
   // conversion cycle.  See adc_cycles parameter.
   input 		capture_clk,

   
   /// Xillybus interface stuff:

   // Xillybus clock, which is the 100 MHz FPGA clock.  We use this to
   // synchronize some handshaking signals that go directly to the
   // Xillybus core (rather than through the FIFO).
   input wire 		bus_clk,
  
   // We are supplying data to the user_r_read_32 FIFO.  These are attached to
   // FIFO write port (capture_clk domain).  Data is transferred from our
   // adc_register() FIFO chain on every cycle when it is available.  When
   // adc_bits is less than 32 then the result is left justified so that the
   // MSB is still in bit 31.
   output reg [31:0] 	capture_data,
   output reg 		capture_en,
   input wire 		capture_full,

   // user_r_read signals are bus_clk domain.
   // FIFO empty 
   input wire 		user_r_read_32_empty, 
   // Is the read fifo open?
   input wire 		user_r_read_32_open,
   // Asserted to force EOF condition output pipe.  We do not used this.
   output wire 		user_r_read_32_eof
  );

`include "adc_params.v"


/// Xillybus stuff:

   // Clock crossing logic: bus_clk -> capture_clk
   (* ASYNC_REG = "TRUE" *) reg capture_open = 0;
   (* ASYNC_REG = "TRUE" *) reg capture_open_cross = 0;
   always @(posedge capture_clk)
     begin
	capture_open_cross <= user_r_read_32_open;
	capture_open <= capture_open_cross;
     end


/// State machine:

   // Our acquire state machine is held in reset whenever the output file is
   // closed.  This mainly serves to give a clean state on start of
   // acquisition. (FWIW also saves power by keeping the ADC in shutdown.)
   wire external_reset = ~capture_open;

   // Acquire state machine states. See state machine implementation below. 
   parameter
     reset_state = 0, // In reset
     config_state = 1, // Configuring ADC
     start_state = 2, // Start MCLK conversion
     convert_state = 3, // waiting for convert to finish
     sync_state = 4, // maybe send SYNC pulse to ADC
     acquire_state = 5, // clocking in ADC data
     wait_state = 6; // Waiting for next conversion
   reg [2:0] state = reset_state;

   // State machine is in XXX_state.
   wire is_reset = (state == reset_state);
   wire is_config = (state == config_state);
   wire is_start = (state == start_state);
   wire is_convert = (state == convert_state);
   wire is_sync = (state == sync_state);
   wire is_acquire = (state == acquire_state);


/// Conversion timing parameters and adc_cycle counter:

   // Count up capture_clk cycles since start of the MCLK convert/acquire
   // cycle.  The LSB defines the SPI clock.  This advances continuously (mod
   // adc_cycles) and drives several of the state machine transitions below.
   // Note that the state machine and output clocks lag this by one cycle due
   // to registering.
   // 
   // Note: You will need to increase the width if adc_cycles > 32.
   reg [4:0] adc_cycle;

   // These comparators track where we are in the convert/acquire adc_cycle to
   // advance the state machine:

   // End of ADC conversion.
   wire convert_end = (adc_cycle == convert_cycles - 1);

   // The first bit period after the conversion is reserved for the
   // SYNC pulse.  Data acquisition happens after that.  We are "wasting" this
   // potential acquisition cycle, but this is not currently a problem.
   wire sync_end = (adc_cycle == convert_cycles + 2 - 1);

   // Done acquiring data for this MCLK convert cycle.  Our acquire state has
   // to happen within the acquisition window of:
   //   adc_cycles - convert_cycles - 2
   // Each bit requires 2 cycles.
   // 
   // Note that there is supposed to be tQUIET delay (10 ns) from last SCKA
   // edge and MCLK.  This is unlikely to become a problem because SCKA is
   // already in its low state by the second half of the acquisition slot.
   wire acquire_end = (adc_cycle == convert_cycles + 2 - 1 + 2*acquire_nbits);

   // End of wait, time to start new cycle.
   // Note: this may be identical to acquire_end if there are no wait cycles.
   wire wait_end = (adc_cycle == adc_cycles - 1);
   
   always @(posedge capture_clk) begin
      if (is_reset || wait_end)
	adc_cycle <= 0;
      else 
	adc_cycle <= adc_cycle + 1;
   end


/// ADC input datapaths:

   // Which bit we acquire next for the current filtered input word.  This
   // counts down from adc_bits - 1 across multiple convert/acquire cycles.
   // When it reaches 0 we are about to acquire the last (least significant)
   // bit.
   reg [4:0] acquire_bit;

   // Where we are in the decimation cycle.  Counts from adc_decimate - 1 down
   // to 0.  When decimate_counter is 0 then a new output word will be
   // available at the start of the next MCLK cycle.
   reg [4:0] decimate_counter;

   // The "modes" are sort of an outer state machine which keeps track of
   // where we are in the full-word output cycle.
   reg [1:0] mode;

   // Acquire input bits after each MCLK.
   parameter acquire_mode = 0;

   // Done acquiring current word, skip sync_state and acquire_state, just
   // cycle MCLK.
   parameter wait_mode = 1;

   // New word is ready, do SYNC and start acquire again.  We are in this mode
   // just from the start_state thru the first acquire_state of the first MCLK
   // cycle for a conversion.  This remembers that we have completed a word so
   // that we can generate the SYNC pulse at the right time (just after
   // completion of the first conversion in the new decimate period).  This is
   // the reset mode so that we sync before reading the first word (which is
   // otherwise messed up by the configuration process).
   parameter sync_mode = 2; 

   // Pulsed for one capture_clk when we have shifted the last bit of new data
   // into the adc_register() shifters.  This loads the ADC data (for all
   // channels simulatenously) into the FIFO-linked output registers, and also
   // tells the mode machine that we are done acquiring.
   // See adc_register() below.
   reg fifo_load_ena;

   // Update decimate_counter and switch modes.
   always @(posedge capture_clk) begin
      if (is_reset) begin
	 decimate_counter <= adc_decimate - 1;
	 mode <= sync_mode;
      end
      else if (is_start) begin
	 if (decimate_counter == 0) begin
	    // If we have finished decimate cycle, then restart
	    decimate_counter <= adc_decimate - 1;
	    mode <= sync_mode;
	 end
	 else begin
	    decimate_counter <= decimate_counter - 1;
	    if (fifo_load_ena)
	      // fifo_load_ena can happen on a start cycle if there are no
	      // wait cycles (we go directly from acquire to start).  In this
	      // case we need to both decrement decimate and go into
	      // wait_mode.
	      mode <= wait_mode;
	 end
      end
      else begin
	 if (fifo_load_ena)
	   // If we have read full word, enter wait_mode
	   mode <= wait_mode;
	 else if (is_acquire && mode == sync_mode)
	   // exit sync_mode once we hit the first acquire.  We hold it that
	   // long so that we can suppress the first SCKA pulse.
	   mode <= acquire_mode;
      end
   end

   // This is an array of the connections between the stages in the buffer
   // FIFO chain.  The word ready for output appears at fifo_data[0], while
   // fifo_data[acquire_adc_channels] is forced to zero (so that the FIFO fills with
   // zeros as we clock out the words).  Bit fifo_data[0][adc_bits] is a valid
   // flag which indicates data is available (and must be transferred on this
   // capture_clk cycle or it will be lost).
   wire [adc_bits:0] fifo_data [0:acquire_adc_channels];
   assign fifo_data[acquire_adc_channels] = 0;

   // Set up the outputs to the FIFO.  We introduce capture_data and
   // capture_en as an extra stage of registers to get a clean synchronous
   // output.
   parameter [31:0] zero_pad = 0;
   // This is in a generate block to represent our expectation that
   // the adc_bits test on the padding will get constant folded.
   // These days generate is an optional decoration.
   generate
      always @(posedge capture_clk) begin
	 // Zero pad on right if not 32 bit ADC
	 if (adc_bits == 32)
	   capture_data <= fifo_data[0][adc_bits-1:0];
	 else
	   capture_data <= {fifo_data[0][adc_bits-1:0],
			   zero_pad[(32 - adc_bits - 1):0]};

	 // Strobe to enable FIFO write.  We drop input data when the FIFO
	 // is full or the pipe is not open.
	 capture_en <= capture_open && !capture_full && fifo_data[0][adc_bits];
      end
   endgenerate


   // Shift in a bit from the ADCs if there is a negative edge on adc_scka (so
   // scka is currently 1).  adc_sync is also treated as a pseudo-clock here
   // because we have to clock in the first data bit *before* the first scka
   // pulse, since the MSB is already sitting on SDOA.  What would be the
   // first SCKA pulse is suppressed in this case so that we don't acquire an
   // extra bit on the first conversion, see adc_scka generation.
   //
   // It may be easier to understand the operation of shift_ena from the
   // viewpoint of the ADC, rather than looking at the combinatorial paths
   // which compute adc_scka and adc_sync.  If we cycle SCKA then it *will*
   // shift out a bit, so we had better read it.
   //
   // If we have read all of the bits for the word then we don't go into
   // acquire_state, so adc_scka is held low.  This inhibits shifting in data
   // that is isn't there.xs
   wire shift_ena = (adc_scka || adc_sync);

   // Datapaths for ADC data (adc_register), which shift in serial data from
   // each ADC and then feed it out in parallel.
   genvar chan;
   generate
      // The fifo chain linkage defines what order we output to the external
      // FIFO.  We want channel 0 (IN0_SDOA1) first, with the remaining
      // channels shifting down toward channel 0.
      for (chan = 0; chan < acquire_adc_channels ; chan = chan + 1) begin
	 adc_register adc_inst (.clock(capture_clk),
				.reset(is_reset),
				.in_bit(adc_sdoa[chan]),
				.shift_ena(shift_ena),
				.load_ena(fifo_load_ena),
				.fifo_chain_in(fifo_data[chan+1]),
				.fifo_chain_out(fifo_data[chan])
				);
      end
   endgenerate
   
   // Datapaths for acquire_bit and fifo_load_ena.
   always @(posedge capture_clk) begin
      if (is_reset || decimate_counter == 0) begin
	 // Resetting from decimate_counter makes sure that acquire_bit stays
	 // in synch with decimate_counter.
	 acquire_bit <= adc_bits - 1;
	 fifo_load_ena <= 0;
      end
      else if (shift_ena) begin
	 if (acquire_bit == 0) begin
	    // If we hit zero, then wrap and assert fifo_load_ena.
	    acquire_bit <= adc_bits - 1;
	    fifo_load_ena <= 1;
	 end
	 else begin
	    acquire_bit <= acquire_bit - 1;
	    fifo_load_ena <= 0;
	 end
      end
      else begin
	 acquire_bit <= acquire_bit;
	 fifo_load_ena <= 0;
      end
   end


   /// SPI configuration output
   //
   // We go through the motions, but nobody is listening when we use the
   // LTC2512-24.

   // The output shifter for config data.
   reg [11:0] config_shifter;
   // Our output bit counter is a one-hot shifter. When the MSB is 1 we are
   // done.  We delay an extra adc_sck cycle because we need the next positive
   // edge to clock the data in to the ADC.
   reg [12:0] config_done_shift;

   always @(posedge capture_clk) begin
      if (!is_config) begin
	 config_shifter <= adc_config;
	 config_done_shift <= 1;
      end
      else if (adc_scka) begin
	 // Shift out a bit if this cycle a negative edge on adc_scka.
	 // is_config is always true here.
	 config_shifter <= {config_shifter[10:0], 1'b0};
	 config_done_shift <= {config_done_shift[11:0], 1'b0};
      end
   end
   wire config_end;
   assign config_end = config_done_shift[12];

   // This mux for adc_sdi is a bit gratuitous, but it seems weird leaving the
   // first bit of the config word on adc_sdi all the time just in case we
   // want to configure.  Not that there is any other use at all for adc_sdi.
   // But it is clearer than what I was doing before (which also didn't work
   // right).
   always @(*) begin
      if (state == config_state)
	adc_sdi = config_shifter[11];
      else
	adc_sdi = 0;
   end


   /// MCLK state machine
   //
   // This state machine cycles sequentially from start_state through
   // wait_state during each MCLK convert/acquire cycle (during adc_cycles
   // positive edges on capture_clk).  The machine does not generate any
   // signals other than the state, it just changes state at the right time to
   // drive the ADC clocks and the shifter datapaths.  After initialization,
   // this machine cycles once per MCLK cycle.  Our position in the
   // the full word acquisition is accessed here via "mode".

   always @(posedge capture_clk)
     begin
	if (external_reset)
	  state <= reset_state;
	else begin
	   case (state)
	     reset_state: begin
		state <= config_state;
	     end

	     // Configuring ADC via SPI output.  This happens after open,
	     // before any conversions.  Going to wait_state afterward is kind
	     // of a pun, but it makes sure that we come into the
	     // convert/acquire loop at the right phase on adc_cycle.  It so
	     // happens that when shifting out the 12 bit config word we go
	     // through one and a fraction of adc_cycles, but this doesn't
	     // matter since we are only using the LSB to generate adc_scka.
	     // Afterward we just wait for the top of the cycle to come around
	     // again.  This requires less resources than somehow resetting
	     // the count or multiplexing adc_scka, and only causes a one-time
	     // delay of less than 1 us before we start converting.  Truly it
	     // would not really matter if acquring the first sample were
	     // mistimed anyway.
	     config_state: begin
		if (config_end) 
		  state <= wait_state;
		else
		  state <= config_state;
	     end

	     // The first cycle of MCLK conversion
	     start_state: begin
		state <= convert_state;
	     end

	     // Cycles of convert delay after the first.  If we are done with
	     // acquisition for the current word then we skip directly to
	     // wait_state, avoiding both sync_state and acquire_state.
	     convert_state: begin
		if (convert_end)
		   if (mode == wait_mode)
		     state <= wait_state;
		   else
		     state <= sync_state;
		else
		  state <= convert_state;
	     end

	     // Delay here during SYNC window (whether we send pulse this time
	     // or not).
	     sync_state: begin
		if (sync_end) 
		  state <= acquire_state;
		else
		  state <= sync_state;
	     end

	     // Conversions and (optional) sync done, now acquire some bits
	     acquire_state: begin
	       if (acquire_end) begin
		  // If there are no wait cycles, start new conversion.
		  if (wait_end)
		    state <= start_state;
		  else
		    state <= wait_state;
	       end
	       else
		 state <= acquire_state;
	     end

	     // Waiting for next conversion cycle
	     wait_state: begin
		if (wait_end) 
		  state <= start_state;
		else
		  state <= wait_state;
	     end

	     default: begin
		state <= reset_state;
	     end
	   endcase   
	end
     end // always @ (posedge capture_clk)

   
   /// ADC clock generation (SKCA, MCLK, SYNC):

   // True if the next posedge on capture_clk should generate a positive edge
   // on the SPI clock scka (assuming that the clock is gated on). scka always
   // happens in the same places in the adc_cycle period, but is not always
   // generated in those slots.  This is negated wrt what you might perhaps
   // expect; scka is positive during odd cycles, so it goes positive when
   // the previous cycle was even.
   wire scka_positive;
   assign scka_positive = ~adc_cycle[0];

   // Generate output clock-like signals.  This is synchronous so that we
   // don't generate any runt clock pulses.
   always @(posedge capture_clk) begin
      // Generate SPI clock.  The sync_mode thing suppresses the output of
      // what would be the clock pulse for bit adc_bits - 1 because bit
      // adc_bits - 1 is already sitting on SDOA even before the first pulse.
      // So we only actually generate adc_bits - 1 clock pulses, not adc_bits.
      if ((is_acquire && mode != sync_mode) || is_config)
	adc_scka <= scka_positive;
      else
	adc_scka <= 0;

      // MCLK is asserted when we are actually converting.  It is suppresed
      // during reset an configuration.
      adc_mclk <= (is_start || is_convert);

      // SYNC pulse generation.  The negative SYNC edge resets the decimation
      // filter.  As well as making sure we start the decimate filter in the
      // right place, this is also needed to open the "transaction window" for
      // configuration.  The window is open from the negative edge of adc_sync
      // until the start of the next conversion (adc_mclk).
      //
      // We synch in reset, and also do "periodic synchronization", where we
      // synch after acquiring each word.  If we get out of synch this causes
      // output bits to be misaligned with what we are expecting.
      adc_sync <= (is_reset
		   || (is_sync && (mode == sync_mode) && scka_positive));
   end

   
   /// More Xillybus stuff:

   /*
   reg 	       capture_has_been_full;
   reg 	       capture_has_been_nonfull;
   reg 	       has_been_full_cross;
   reg 	       has_been_full;
   
   always @(posedge capture_clk)
     begin
	// capture_has_been_full remembers that the FIFO has been full
	// until the file is closed. capture_has_been_nonfull prevents
	// capture_has_been_full to respond to the initial full condition
	// every FIFO displays on reset.
	if (!capture_full)
	  capture_has_been_nonfull <= 1;
	else if (!capture_open)
	  capture_has_been_nonfull <= 0;
	
	if (capture_full && capture_has_been_nonfull)
	  capture_has_been_full <= 1;
	else if (!capture_open)
	  capture_has_been_full <= 0;
     end

   // Clock crossing logic: capture_clk -> bus_clk
   always @(posedge bus_clk)
     begin
	has_been_full_cross <= capture_has_been_full;
	has_been_full <= has_been_full_cross;
     end
   
   // The user_r_read_32_eof signal is required to go from '0' to '1' only on
   // a clock cycle following an asserted read enable, according to Xillybus'
   // core API. This is assured, since it's a logical AND between
   // user_r_read_32_empty and has_been_full. has_been_full goes high when the
   // FIFO is full, so it's guaranteed that user_r_read_32_empty is low when
   // that happens. On the other hand, user_r_read_32_empty is a FIFO's empty
   // signal, which naturally meets the requirement.

   assign user_r_read_32_eof = user_r_read_32_empty && has_been_full;
   */

   // We want to ignore buffer overruns for now.  I've commented out
   // the logic (above) related to has_been_full, etc.  I'm leaving it
   // here in case we want it later.
   assign user_r_read_32_eof = 0;
   
endmodule
