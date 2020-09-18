// Parameters related to ADC input, see multi_adc_interface.v  These values
// are for the LTC2512-24 with the ILEMT main board.

// The number of capture_clk cycles per MCLK conversion, giving total
// convert/acquire cycle corresponding to 1.6 MHz MCLK rate (625 ns).  This
// must be even because the SPI bus runs at half rate.  This implies
// capture_clk is 51.2 MHz.
//
// ### Huh, why am I using such a high capture_clk/SCKA?  It could be half
// this fast and still acquire all of the data.  This would make the SPI SDOA
// setup much more relaxed.  Just need to reduce both the clock frequency and
// the XXX_cycles values.  IIRC, one issue is the DAC timing, which only
// supports certain power-of-two clock multipliers.  This is a constraint if
// the ADC clock is the same as capture_clk.
//
// Don't confuse adc_cycles with adc_decimate, which further divides the
// output rate.
parameter adc_cycles = 32;

// The number of capture_clk cycles to wait while the MCLK conversion
// completes.  This must be even.  LTC2512-24 datasheet max is 460 ns (which
// is a min for us).  24 = 469 ns with 51.2 MHz capture_clk, but the actual
// MCLK with the ILEMT main board is delayed by reclocking, so we increase to
// 26.  capture_clk should be 180 degrees wrt sysclk to give maximum timing
// slack on the reclocking, giving an expected delay of 9.8 ns, which makes
// convert_cycles=24 just barely too short.  This leaves only 6 cycles for
// acqusition, which would just permit acquire_bits=2, but we go with 1
// because there is plenty of time for acqusition even at that rate with
// adc_decimate=32. 
//
// (The ADC SAR converter clock is generated internally to the ADC, so is
// asynchronous wrt. capture_clk, and is not tightly frequency controlled.
// Hence the vagueness in the conversion time.  The BUSY signal tells you
// when the conversion is actually in progress, but we want to operate all
// of the ADCs synchronously, so we use a worst-case timing.)
parameter convert_cycles = 26;

// Total bits we acquire (ADC output word size).
parameter adc_bits = 24;

// Number of output bits to acquire each MCLK cycle.
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

// The number of ADC channels to acquire (card slots * 3)
parameter adc_channels = 12;
