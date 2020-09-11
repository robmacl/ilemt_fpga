// Datapaths for a single ADC input.  This is deserializer with an
// output register which can be loaded either from the shift register
// or externally.  With the external load this is used to implement a
// single stage in a FIFO which which feeds out the data words
// sequentially, while deserialization is going on.

module adc_register
`include "adc_params.v"
  (
   // The clock for shift register and output register.
   input 		       clock,

   // The ADC input bit.
   input 		       in_bit,

   // Shift in a new bit on clock.
   input 		       shift_ena,

   // Load output register from shifter or from ext_data.  At most one
   // of these should be asserted.
   input 		       shifter_load_ena,
   input 		       ext_load_ena,

   // External data word input for the FIFO chain.
   input [(adc_bits-1):0]      ext_data,

   // The output register.
   output reg [(adc_bits-1):0] out_reg
   );

   // The shift register.  Bits are shifted in at the low end.
   reg [(adc_bits-1):0] shifter;

   always @(posedge clock) begin
      if (shift_ena)
	shifter <= {shifter[(adc_bits-2):0], in_bit};

      if (shifter_load_ena)
	out_reg <= shifter;
      else if (ext_load_ena) 
	out_reg <= ext_data;
   end
endmodule
