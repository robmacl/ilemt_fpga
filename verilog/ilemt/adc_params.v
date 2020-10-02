// Parameters related to ADC input, see multi_adc_interface.v  These values
// are for the LTC2512-24 with the ILEMT main board.

// adc_cycles: the number of capture_clk cycles per MCLK conversion, giving
// total convert/acquire cycle at (or below) a 1.6 MHz MCLK rate (625 ns).
// 
// convert_cycles: the number of capture_clk cycles we allow for worst-case
// ADC conversion time.  These must be even because the SPI bus runs at half
// rate.
//  
// With 20 MHz capture_clk and the setting below, we get:
//  -- Output sample rate of 39.06 ksps
//  -- MCLK rate of 1.25 MHz.
//  -- ADC convert window of 600 ns.
//  -- 10 MHz SPI clock
// 
//
// (The ADC SAR converter clock is generated internally to the ADC, so is
// asynchronous wrt. capture_clk, and is not tightly frequency controlled.
// Hence the vagueness in ADC conversion time.  The internal SAR clock is not
// jitter critical because it is synchronized on each sample by MCLK. The BUSY
// signal (which we did not bring out) tells you when the conversion is
// actually in progress, but we want to operate all of the ADCs synchronously,
// so we use a worst-case timing.)
//
// ### I was planning for capture_clk to be identical to SYSCLK, but I don't
// want to figure out how to program the oscillator now, so I'm going to leave
// it at 100 MHz and use a PLL to derive a 20 MHz capture_clk.  It needs to
// have an integer ratio to give a fixed edge-to-edge timing of SYSCLK to
// capture_clk in order for the MCLK synchronization to work.  See the PLL IP
// configuration for the capture_clk generation.
// 
// The 600 ns convert window gives us 140 ns margin wrt. the 460 ns max
// conversion time spec, more than enough to allow for the synchronization
// delay in the MCLK flip-flop.  At the 100 MHz clock the synchronization
// delay is only 5 ns, but this makes the MCLK FF setup critical.  We might
// need to tweak the capture_clk phase shift to get good setup time on
// MCLK_ENA.  We have freedom here because nothing else is constraining the
// capture_clk/SYSCLK phase relationship.
//
// For the SPI setup, our max delay from SCKA back to SDOA is about 20 ns,
// whereas 1/2 clock at 10 MHz gives us 50 ns, so there is really no problem
// ensuring enough setup time.  This would be the case even with the 25.4 MHz
// clock corresponding to full ADC rate, but the convert_cycles starts to
// become a concern.  Having a multiplied SYSCLK does greatly reduce the MCLK
// synchronization delay.  With programmed clock we might want to try a
// divisor of 4.  I guess we could squeak through with this even with 100 MHz
// sysclk (which may be forced by the DAC supported divisors.
//
// Note that there is no ADC jitter penalty for interposing the PLL in the
// capture_clk path because of the external MCLK synchronization.  This would
// be a factor for the DACs if we don't do external synch there.  I am not
// certain which DAC clock is jitter critical, but it is probably the high
// rate SCK.
//
// Don't confuse adc_cycles with adc_decimate, which further divides the
// output rate.
// 
parameter adc_cycles = 16;
parameter convert_cycles = 12;

// Total bits we acquire (ADC output word size).
parameter adc_bits = 24;

// Number of output bits to acquire each MCLK cycle.  With current timing this
// has to be 1 because the conversion takes up most of the MCLK cycle.
parameter acquire_nbits = 1;

// Decimation factor configured in the ADC output filter.  We need this to
// know how many MCLK cycles per data output word.
parameter adc_decimate = 32;

// Configuration data for LTC2500-32
// 10: we are configuring
// 00: DGE off DCE off, gain expansion and compression
// 0100: DF=16, decimation factor
// 0010: filter=SINC2, decimation filter type, or 
// 0110: filter=FLAT
parameter adc_config = 12'b10_00_0100_0110;

// The total number of ADC channels supported (card slots * 3)
parameter adc_channels = 12;

// The number of channels to actually acquire (starting with channel
// 0).
parameter acquire_adc_channels = 3;

// Clock periods in ns, used in testbenches.
//parameter capture_clk_period = 19.53;
parameter capture_clk_period = 39.06;
parameter bus_clk_period = 10;
