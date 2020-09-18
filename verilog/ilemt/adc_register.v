// Datapaths for a single ADC input.  This is deserializer with an
// output register which can be loaded either from the shift register
// or from the FIFO chain.  Each register implements a single stage in
// a FIFO which which feeds out the data words sequentially, while
// deserialization is going on.
//
// Bit adc_bits in the fifo_chain words is a "valid" bit which is set
// when the register is loaded from the shifter.  Since
// multi_adc_interface arranges for zeros to be fed into the FIFO this
// bit goes to zero when there is no remaining data to be read.  Since
// the FIFO advances on every cycle which it is not loaded, the output
// must be transferred on each cycle where the valid bit is true or
// data will be lost.

module adc_register
  (
   // The clock for shift register and output register.
   input 		   clock,

   // Synchronous reset.
   input 		   reset,

   // The ADC input bit.
   input 		   in_bit,

   // Shift in a new bit on clock.
   input 		   shift_ena,

   // If true, load output register from shifter, otherwise from
   // fifo_chain.  If shift_ena is asserted on the same cycle then we
   // will load the pre-shift value.
   input 		   load_ena,

   // External data word input for the FIFO chain.
   input [adc_bits:0] 	   fifo_chain_in,

   // The output register.
   output reg [adc_bits:0] fifo_chain_out
   );

`include "adc_params.v"

   // The shift register.  Bits are shifted in at the low end.
   reg [(adc_bits-1):0] shifter;

   always @(posedge clock) begin
      if (reset) begin
	 shifter <= 0;
	 fifo_chain_out <= 0;
      end
      else begin
	 if (shift_ena)
	   shifter <= {shifter[(adc_bits-2):0], in_bit};
	 else
	   shifter <= shifter;
	 
	 if (load_ena)
	   fifo_chain_out <= {1'b1, shifter[(adc_bits-1):0]};
	 else
	   fifo_chain_out <= fifo_chain_in;
      end
   end
endmodule
