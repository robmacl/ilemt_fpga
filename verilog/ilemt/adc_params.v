// Parameters related to ADC input, see multi_adc_interface.v  These values
// are for the LTC2512-24 with the ILEMT main board.

// adc_cycles: the number of capture_clk cycles per MCLK conversion, giving
// total convert/acquire cycle at (or below) a 1.6 MHz MCLK rate (625 ns).
// 
// convert_cycles: the number of capture_clk cycles we allow for worst-case
// ADC conversion time.  These must be even because the SPI bus runs at half
// rate.
//
// BUT: synchronous sampling between ADC and DAC more or less forces
// adc_cycles=16 and adc_decimate=32, since we want the product
// adc_cycles*adc_decimate=512, which is a divisor supported by the TI
// PCM1794A DAC.  Also the DAC clock is forced in hardware to SYSCLK/4,
// limting our flexibility in the SYSCLK rate and capture_clk divisor.  It
// would seem that capture_clk also has to be SYSCLK/4.  See comments in
// multi_dac_interface.v and capture_clk1 instance in ilemt.v.
//  
// With capture_clk = 48e3*512 = 24.576 MHz, and the settings below, we get:
//  -- Output sample rate of 48 ksps
//  -- MCLK rate of 1.536 MHz.
//  -- ADC convert window of 488 ns.
//  -- 12.3 MHz SPI clock

// The ADC SAR converter clock is generated internally to the ADC, so is
// asynchronous wrt. capture_clk, and is not tightly frequency controlled.
// Hence the vagueness in ADC conversion time.  The internal SAR clock is not
// jitter critical because it is synchronized on each sample by MCLK. The BUSY
// signal (which we did not bring out) tells you when the conversion is
// actually in progress, but we want to operate all of the ADCs synchronously,
// so we use a worst-case timing.
//
// When we figure out how to program SYSCLK we can reduce it to get a lower
// sample rate, which would give more timing slack all around.  We wouldn't
// want to reduce it too much, but we could go down from the 48.8 ksps we get
// at 100 MHz to say 44.1 ksps @ 90.3168 MHz.  Hoping for now that it works at
// 100 MHz.
// 
// The 488 ns convert window gives us only 28 ns margin wrt. the 460 ns max
// conversion time spec, which seems rather marginal.  At ~100 MHz SYSCLK
// the synchronization delay is only 5 ns, but this makes the MCLK FF setup
// critical.  We might need to tweak the capture_clk phase shift to get good
// setup time on MCLK_ENA.  We have freedom here because nothing else is
// constraining the capture_clk/SYSCLK phase relationship.
//
// For the SPI setup, our max delay from SCKA back to SDOA is about 20 ns,
// whereas 1/2 clock at 10 MHz gives us 50 ns, so there is really no problem
// ensuring enough setup time.  This would be the case even with the 25.4 MHz
// clock corresponding to full ADC rate, but the convert_cycles starts to
// become a concern.
//
// Note that there is no ADC jitter penalty for interposing the FPGA and PLL
// in the capture_clk path because of the external MCLK synchronization.  And
// the DAC SCK clock is derived directly from SYSCLK by a hard divider (so
// does not go through the FPGA).  I am not certain which DAC clock is jitter
// critical, but it is probably the high rate SCK.

// Don't confuse adc_cycles with adc_decimate, which further divides the
// output rate.
parameter adc_cycles = 16;
parameter convert_cycles = 12;

// Total bits we acquire (ADC output word size).
parameter adc_bits = 24;

// Number of output bits to acquire each MCLK cycle.  With current timing this
// has to be 1 because the conversion takes up most of the MCLK cycle.
parameter acquire_nbits = 1;

// Decimation factor configured in the ADC output filter.  We need this to
// know how many MCLK cycles per data output word.  With the LTC2512-24 this
// is pin-strapped by jumpers on the input board.  With current timing this
// value has to be 32 in order for there to be time to transfer all the output
// bits because acquire_nbits has to be 1.
parameter adc_decimate = 32;

// Configuration data for LTC2500-32.  This is not used with the LTC2512-24 in
// the current ILEMT hardware.
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
parameter acquire_adc_channels = 6;

// Clock periods in ns, used in testbenches.  Round numbers make for a
// prettier display, don't need to be exactly correct.
parameter capture_clk_period = 40;
parameter bus_clk_period = 10;

// The number of DAC channels.
parameter dac_channels = 4;
