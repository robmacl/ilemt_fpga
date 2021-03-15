module ilemt (
	      DEBUG1,
	      DEBUG2,
	      DEBUG3,
	      DEBUG4,
	      DEBUG5,
	      DEBUG6,
	      DEBUG7,
	      DEBUG8,
	      LED1,
	      LED2,
	      LED3,
	      LED4,
	      IN3_CARDSEL,
	      IN2_CARDSEL,
	      IN1_CARDSEL,
	      IN0_CARDSEL,
	      BIST_SYNC,
	      BIST_MOSI,
	      BIST_SCLK,
	      DAC_NOT_RST,
	      DAC_LRCK,
	      DOUTL3,
	      DOUTL4,
	      DOUTL5,
	      DOUTL6,
	      DFB1_P,
	      DFB1_N,
	      DFB2_P,
	      DFB2_N,
	      DFB3_P,
	      DFB3_N,
	      DFB4_P,
	      DFB4_N,
	      DAC_BCK_P,
	      DAC_BCK_N,
	      DAC_DATA1_P,
	      DAC_DATA1_N,
	      DAC_DATA2_P,
	      DAC_DATA2_N,
	      DOUT4_P,
	      DOUT4_N,
	      DOUT5_P,
	      DOUT5_N,
	      DOUT6_P,
	      DOUT6_N,
	      DOUT7_P,
	      DOUT7_N,
	      DOUT8_P,
	      DOUT8_N,
	      ICLK_SYNC,
	      ICLK_SDI,
	      ICLK_MCLK_ENA_P,
	      ICLK_MCLK_ENA_N,
	      SCKB_P,
	      SCKB_N,
	      SCKA_P,
	      SCKA_N,
	      SYSCLK_P,
	      SYSCLK_N,
	      ICLK_DEBUG_P,
	      ICLK_DEBUG_N,
	      IN3_SDOA1_P,
	      IN3_SDOA1_N,
	      IN3_SDOB1_P,
	      IN3_SDOB1_N,
	      IN3_SDOA2_P,
	      IN3_SDOA2_N,
	      IN3_SDOA3_P,
	      IN3_SDOA3_N,
	      IN2_SDOA1_P,
	      IN2_SDOA1_N,
	      IN2_SDOB1_P,
	      IN2_SDOB1_N,
	      IN2_SDOA2_P,
	      IN2_SDOA2_N,
	      IN2_SDOA3_P,
	      IN2_SDOA3_N,
	      IN1_SDOA1_P,
	      IN1_SDOA1_N,
	      IN1_SDOB1_P,
	      IN1_SDOB1_N,
	      IN1_SDOA2_P,
	      IN1_SDOA2_N,
	      IN1_SDOA3_P,
	      IN1_SDOA3_N,
	      IN0_SDOA1_P,
	      IN0_SDOA1_N,
	      IN0_SDOB1_P,
	      IN0_SDOB1_N,
	      IN0_SDOA2_P,
	      IN0_SDOA2_N,
	      IN0_SDOA3_P,
	      IN0_SDOA3_N);

`include "adc_params.v"
   /// Pin definitions:
   
   // debug IOs
   output DEBUG1;
   output DEBUG2;
   output DEBUG3;
   output DEBUG4;
   output DEBUG5;
   output DEBUG6;
   output DEBUG7;
   output DEBUG8;
   output reg LED1;
   output reg LED2;
   output reg LED3;
   output reg LED4;

   // Card select for input card configuration
   output IN0_CARDSEL;
   output IN1_CARDSEL;
   output IN2_CARDSEL;
   output IN3_CARDSEL;

   // BIST DAC
   output BIST_SYNC;
   output BIST_MOSI;
   output BIST_SCLK;

   // Output slot IOs
   output DAC_NOT_RST; // DOUTL1
   output DAC_LRCK; // DOUTL2
   output DOUTL3;
   output DOUTL4;
   output DOUTL5;
   output DOUTL6;
   input  DFB1_P;
   input  DFB1_N;
   input  DFB2_P;
   input  DFB2_N;
   input  DFB3_P;
   input  DFB3_N;
   input  DFB4_P;
   input  DFB4_N;
   output DAC_BCK_P; // DOUT1
   output DAC_BCK_N;
   output DAC_DATA1_P; // DOUT2
   output DAC_DATA1_N;
   output DAC_DATA2_P; // DOUT3
   output DAC_DATA2_N;
   output DOUT4_P;
   output DOUT4_N;
   output DOUT5_P;
   output DOUT5_N;
   output DOUT6_P;
   output DOUT6_N;
   output DOUT7_P;
   output DOUT7_N;
   output DOUT8_P;
   output DOUT8_N;

   // Clock signals to ADC
   output ICLK_SYNC;
   output ICLK_SDI;
   output ICLK_MCLK_ENA_P;
   output ICLK_MCLK_ENA_N;
   output SCKB_P;
   output SCKB_N;
   output SCKA_P;
   output SCKA_N;

   // Master clock from oscillator
   input  SYSCLK_P;
   input  SYSCLK_N;
 
   // Debug output to coax jack
   output ICLK_DEBUG_P;
   output ICLK_DEBUG_N;

   // Decimated ADC outputs
   input  IN0_SDOA1_N;
   input  IN0_SDOA1_P;
   input  IN0_SDOA2_N;
   input  IN0_SDOA2_P;
   input  IN0_SDOA3_N;
   input  IN0_SDOA3_P;
   input  IN1_SDOA1_N;
   input  IN1_SDOA1_P;
   input  IN1_SDOA2_N;
   input  IN1_SDOA2_P;
   input  IN1_SDOA3_N;
   input  IN1_SDOA3_P;
   input  IN2_SDOA1_N;
   input  IN2_SDOA1_P;
   input  IN2_SDOA2_N;
   input  IN2_SDOA2_P;
   input  IN2_SDOA3_N;
   input  IN2_SDOA3_P;
   input  IN3_SDOA1_N;
   input  IN3_SDOA1_P;
   input  IN3_SDOA2_N;
   input  IN3_SDOA2_P;
   input  IN3_SDOA3_N;
   input  IN3_SDOA3_P;

   // Full rate ADC outputs (not used)
   input  IN0_SDOB1_N;
   input  IN0_SDOB1_P;
   input  IN1_SDOB1_N;
   input  IN1_SDOB1_P;
   input  IN2_SDOB1_N;
   input  IN2_SDOB1_P;
   input  IN3_SDOB1_N;
   input  IN3_SDOB1_P;

   // Output bits for each DAC chip, bundled at multi_dac_interface.v
   wire [0:1] DAC_DATA_PINS;
   

   /// IO buffer instances for LVDS lines:
   // (from pinmap/pin_defs_verilog.v)
   wire   IN0_SDOA1;
   IBUFDS IBUFDS_IN0_SDOA1 (.O(IN0_SDOA1), .I(IN0_SDOA1_P), .IB(IN0_SDOA1_N));
   wire   IN0_SDOB1;
   IBUFDS IBUFDS_IN0_SDOB1 (.O(IN0_SDOB1), .I(IN0_SDOB1_P), .IB(IN0_SDOB1_N));
   wire   IN0_SDOA2;
   IBUFDS IBUFDS_IN0_SDOA2 (.O(IN0_SDOA2), .I(IN0_SDOA2_P), .IB(IN0_SDOA2_N));
   wire   IN0_SDOA3;
   IBUFDS IBUFDS_IN0_SDOA3 (.O(IN0_SDOA3), .I(IN0_SDOA3_P), .IB(IN0_SDOA3_N));
   wire   IN1_SDOA1;
   IBUFDS IBUFDS_IN1_SDOA1 (.O(IN1_SDOA1), .I(IN1_SDOA1_P), .IB(IN1_SDOA1_N));
   wire   IN1_SDOB1;
   IBUFDS IBUFDS_IN1_SDOB1 (.O(IN1_SDOB1), .I(IN1_SDOB1_P), .IB(IN1_SDOB1_N));
   wire   IN1_SDOA2;
   IBUFDS IBUFDS_IN1_SDOA2 (.O(IN1_SDOA2), .I(IN1_SDOA2_P), .IB(IN1_SDOA2_N));
   wire   IN1_SDOA3;
   IBUFDS IBUFDS_IN1_SDOA3 (.O(IN1_SDOA3), .I(IN1_SDOA3_P), .IB(IN1_SDOA3_N));
   wire   IN2_SDOA1;
   IBUFDS IBUFDS_IN2_SDOA1 (.O(IN2_SDOA1), .I(IN2_SDOA1_P), .IB(IN2_SDOA1_N));
   wire   IN2_SDOB1;
   IBUFDS IBUFDS_IN2_SDOB1 (.O(IN2_SDOB1), .I(IN2_SDOB1_P), .IB(IN2_SDOB1_N));
   wire   IN2_SDOA2;
   IBUFDS IBUFDS_IN2_SDOA2 (.O(IN2_SDOA2), .I(IN2_SDOA2_P), .IB(IN2_SDOA2_N));
   wire   IN2_SDOA3;
   IBUFDS IBUFDS_IN2_SDOA3 (.O(IN2_SDOA3), .I(IN2_SDOA3_P), .IB(IN2_SDOA3_N));
   wire   IN3_SDOA1;
   IBUFDS IBUFDS_IN3_SDOA1 (.O(IN3_SDOA1), .I(IN3_SDOA1_P), .IB(IN3_SDOA1_N));
   wire   IN3_SDOB1;
   IBUFDS IBUFDS_IN3_SDOB1 (.O(IN3_SDOB1), .I(IN3_SDOB1_P), .IB(IN3_SDOB1_N));
   wire   IN3_SDOA2;
   IBUFDS IBUFDS_IN3_SDOA2 (.O(IN3_SDOA2), .I(IN3_SDOA2_P), .IB(IN3_SDOA2_N));
   wire   IN3_SDOA3;
   IBUFDS IBUFDS_IN3_SDOA3 (.O(IN3_SDOA3), .I(IN3_SDOA3_P), .IB(IN3_SDOA3_N));
   wire   ICLK_MCLK_ENA;
   OBUFDS OBUFDS_ICLK_MCLK_ENA (.O(ICLK_MCLK_ENA_P), .OB(ICLK_MCLK_ENA_N), .I(ICLK_MCLK_ENA));
   wire   SCKB;
   OBUFDS OBUFDS_SCKB (.O(SCKB_P), .OB(SCKB_N), .I(SCKB));
   wire   SCKA;
   OBUFDS OBUFDS_SCKA (.O(SCKA_P), .OB(SCKA_N), .I(SCKA));
   // SYSCLK receive buffer is integral to PLL, on clock capable pin.
   wire   ICLK_DEBUG;
   OBUFDS OBUFDS_ICLK_DEBUG (.O(ICLK_DEBUG_P), .OB(ICLK_DEBUG_N), .I(ICLK_DEBUG));
   wire   DFB1;
   IBUFDS IBUFDS_DFB1 (.O(DFB1), .I(DFB1_P), .IB(DFB1_N));
   wire   DFB2;
   IBUFDS IBUFDS_DFB2 (.O(DFB2), .I(DFB2_P), .IB(DFB2_N));
   wire   DFB3;
   IBUFDS IBUFDS_DFB3 (.O(DFB3), .I(DFB3_P), .IB(DFB3_N));
   wire   DFB4;
   IBUFDS IBUFDS_DFB4 (.O(DFB4), .I(DFB4_P), .IB(DFB4_N));
   wire   DAC_BCK;
   OBUFDS OBUFDS_DAC_BCK (.O(DAC_BCK_P), .OB(DAC_BCK_N), .I(DAC_BCK));
   wire   DAC_DATA1;
   OBUFDS OBUFDS_DAC_DATA1 (.O(DAC_DATA1_P), .OB(DAC_DATA1_N), .I(DAC_DATA_PINS[0]));
   wire   DAC_DATA2;
   OBUFDS OBUFDS_DAC_DATA2 (.O(DAC_DATA2_P), .OB(DAC_DATA2_N), .I(DAC_DATA_PINS[1]));
   wire   DOUT4;
   OBUFDS OBUFDS_DOUT4 (.O(DOUT4_P), .OB(DOUT4_N), .I(DOUT4));
   wire   DOUT5;
   OBUFDS OBUFDS_DOUT5 (.O(DOUT5_P), .OB(DOUT5_N), .I(DOUT5));
   wire   DOUT6;
   OBUFDS OBUFDS_DOUT6 (.O(DOUT6_P), .OB(DOUT6_N), .I(DOUT6));
   wire   DOUT7;
   OBUFDS OBUFDS_DOUT7 (.O(DOUT7_P), .OB(DOUT7_N), .I(DOUT7));
   wire   DOUT8;
   OBUFDS OBUFDS_DOUT8 (.O(DOUT8_P), .OB(DOUT8_N), .I(DOUT8));
   

   
   /// This section is all Xillybus stuff for the processor interface.
   // Some is for features which are not used.  This is more-or-less copied
   // from xillydemo.v.
   //
   // Mostly what we are doing is instantiating the Xillybus core and defining
   // the names of the signals that go to/from the core.  The signals in this
   // section are the Xillybus end of whatever is going on.  We could have
   // renamed these signals to locally meaningul ones when we instantiate
   // Xillybus, but it seems clearer to use the Xillybus names to represent
   // where the signals are going.  All these signals are in the bus_clk
   // domain.  (bus_clk is an output from Xillybus.)
   //
   // So in the case of FIFOs, these "user_" signals are the Xillybus end of
   // the FIFO.  We declare the signals to/from our side of the FIFOs
   // elsewhere (and give them meaningful names).
   //
   // The 8 bit read and write FIFOs are not used.  There are also templates
   // for the (currently unused) Xillybus random access modes xillybus_mem
   // (which looks like a Unix file) and xillybus lite, which supports memory
   // mapped registers.

   // Clock and quiesce
   wire    bus_clk;
   wire    quiesce;

   // Memory arrays
   reg [7:0] demoarray[0:31];
   
   reg [7:0] litearray0[0:31];
   reg [7:0] litearray1[0:31];
   reg [7:0] litearray2[0:31];
   reg [7:0] litearray3[0:31];

   // Wires related to /dev/xillybus_mem_8
   wire      user_r_mem_8_rden;
   wire      user_r_mem_8_empty;
   reg [7:0] user_r_mem_8_data;
   wire      user_r_mem_8_eof;
   wire      user_r_mem_8_open;
   wire      user_w_mem_8_wren;
   wire      user_w_mem_8_full;
   wire [7:0] user_w_mem_8_data;
   wire       user_w_mem_8_open;
   wire [4:0] user_mem_8_addr;
   wire       user_mem_8_addr_update;

   // Wires related to /dev/xillybus_read_32
   wire       user_r_read_32_rden;
   wire       user_r_read_32_empty;
   wire [31:0] user_r_read_32_data;
   wire        user_r_read_32_eof;
   wire        user_r_read_32_open;

   // Wires related to /dev/xillybus_read_8
   wire        user_r_read_8_rden;
   wire        user_r_read_8_empty;
   wire [7:0]  user_r_read_8_data;
   wire        user_r_read_8_eof;
   wire        user_r_read_8_open;

   // Wires related to /dev/xillybus_write_32
   wire        user_w_write_32_wren;
   wire        user_w_write_32_full;
   wire [31:0] user_w_write_32_data;
   wire        user_w_write_32_open;

   // Wires related to /dev/xillybus_write_8
   wire        user_w_write_8_wren;
   wire        user_w_write_8_full;
   wire [7:0]  user_w_write_8_data;
   wire        user_w_write_8_open;

   // Wires related to Xillybus Lite
   wire        user_clk;
   wire        user_wren;
   wire [3:0]  user_wstrb;
   wire        user_rden;
   reg [31:0]  user_rd_data;
   wire [31:0] user_wr_data;
   wire [31:0] user_addr;
   wire        user_irq;


   // [Comment from xillydemo.v]
   // Note that none of the ARM processor's direct connections to pads is
   // attached in the instantion below. Normally, they should be connected as
   // toplevel ports here, but that confuses Vivado 2013.4 to think that
   // some of these ports are real I/Os, causing an implementation failure.
   // This detachment results in a lot of warnings during synthesis and
   // implementation, but has no practical significance, as these pads are
   // completely unrelated to the FPGA bitstream.

   xillybus xillybus_ins (

    // Ports related to /dev/xillybus_mem_8
    // FPGA to CPU signals:
    .user_r_mem_8_rden(user_r_mem_8_rden),
    .user_r_mem_8_empty(user_r_mem_8_empty),
    .user_r_mem_8_data(user_r_mem_8_data),
    .user_r_mem_8_eof(user_r_mem_8_eof),
    .user_r_mem_8_open(user_r_mem_8_open),

    // CPU to FPGA signals:
    .user_w_mem_8_wren(user_w_mem_8_wren),
    .user_w_mem_8_full(user_w_mem_8_full),
    .user_w_mem_8_data(user_w_mem_8_data),
    .user_w_mem_8_open(user_w_mem_8_open),

    // Address signals:
    .user_mem_8_addr(user_mem_8_addr),
    .user_mem_8_addr_update(user_mem_8_addr_update),


    // Ports related to /dev/xillybus_read_32
    // FPGA to CPU signals:
    .user_r_read_32_rden(user_r_read_32_rden),
    .user_r_read_32_empty(user_r_read_32_empty),
    .user_r_read_32_data(user_r_read_32_data),
    .user_r_read_32_eof(user_r_read_32_eof),
    .user_r_read_32_open(user_r_read_32_open),


    // Ports related to /dev/xillybus_read_8
    // FPGA to CPU signals:
    .user_r_read_8_rden(user_r_read_8_rden),
    .user_r_read_8_empty(user_r_read_8_empty),
    .user_r_read_8_data(user_r_read_8_data),
    .user_r_read_8_eof(user_r_read_8_eof),
    .user_r_read_8_open(user_r_read_8_open),


    // Ports related to /dev/xillybus_write_32
    // CPU to FPGA signals:
    .user_w_write_32_wren(user_w_write_32_wren),
    .user_w_write_32_full(user_w_write_32_full),
    .user_w_write_32_data(user_w_write_32_data),
    .user_w_write_32_open(user_w_write_32_open),


    // Ports related to /dev/xillybus_write_8
    // CPU to FPGA signals:
    .user_w_write_8_wren(user_w_write_8_wren),
    .user_w_write_8_full(user_w_write_8_full),
    .user_w_write_8_data(user_w_write_8_data),
    .user_w_write_8_open(user_w_write_8_open),

    // Xillybus Lite signals:
    .user_clk ( user_clk ),
    .user_wren ( user_wren ),
    .user_wstrb ( user_wstrb ),
    .user_rden ( user_rden ),
    .user_rd_data ( user_rd_data ),
    .user_wr_data ( user_wr_data ),
    .user_addr ( user_addr ),
    .user_irq ( user_irq ),
			  			  
    // General signals
    .bus_clk(bus_clk),
    .quiesce(quiesce)
  );

   assign      user_irq = 0; // No interrupts for now

   // Xillybus lite lets you read and write register data by
   // dereferencing a C user space pointer.
   always @(posedge user_clk)
     begin
	if (user_wstrb[0])
	  litearray0[user_addr[6:2]] <= user_wr_data[7:0];

	if (user_wstrb[1])
	  litearray1[user_addr[6:2]] <= user_wr_data[15:8];

	if (user_wstrb[2])
	  litearray2[user_addr[6:2]] <= user_wr_data[23:16];

	if (user_wstrb[3])
	  litearray3[user_addr[6:2]] <= user_wr_data[31:24];
	
	if (user_rden)
	  user_rd_data <= { litearray3[user_addr[6:2]],
			    litearray2[user_addr[6:2]],
			    litearray1[user_addr[6:2]],
			    litearray0[user_addr[6:2]] };
     end

   // A simple inferred RAM
   always @(posedge bus_clk)
     begin
	if (user_w_mem_8_wren)
	  demoarray[user_mem_8_addr] <= user_w_mem_8_data;
	
	if (user_r_mem_8_rden)
	  user_r_mem_8_data <= demoarray[user_mem_8_addr];	  
     end

   assign  user_r_mem_8_empty = 0;
   assign  user_r_mem_8_eof = 0;
   assign  user_w_mem_8_full = 0;

   // End Xillybus xillydemo.v stuff 


/// ILEMT interfaces:

   // capture_clk is to generate the ADC and DAC clocking: adc SCKA, DAC_SCK,
   // etc.
   // 
   // See adc_params.v and multi_dac_interface.v for notes on current on
   // current clock configuration, and also the MMCM/PLL IP configuration
   // wizard.
   // 
   // Note: if you customize the MCMM clock PLL IP then you need to copy the
   // generated file back into the source tree (where this file is located):
   //   cp vivado/ilemt.srcs/sources_1/ip/capture_clk1/capture_clk1.xci .
   //
   // Current theory is that capture_clk must be SYSCLK/4 (which is also the
   // DAC System Clock SCK rate).  This is forced by the need to get the
   // same sample rate on ADC and DAC.
   //
   // capture_clk needs to be phase shifted approx 180 degrees wrt. SYSCLK to
   // give maximum setup/hold time on the MCLK_ENA signal.  Ideally this
   // should be phase-tweaked to get that measured relationship at the MCLK
   // flip-flop.
   //
   // The phase shift and reclocking on MCLK_ENA means that MCLK is delayed by
   // about 1/2 SYSCLK cycle wrt. the signals that come straight from the
   // FPGA.  This doesn't matter as long as we allow enough time for the
   // conversion to complete before we go active on the SPI bus.
   // 
   // ### need attention here:
   // We should constrain at least the leading edges of MCLK_ENA and SCKA.  As
   // well as the MCLK phase requirement above, we also need to be confident
   // that there is enough setup time for SDOA from posedge SCKA with the
   // various delays.  See ilemt_fpga/docs/spi_timing_budget.xlsx
   //
   // It seems constraining SPI can get ugly in general because SPI uses both
   // posedge and negedge on SCK, but it is pretty simple for us since we are
   // master, and use the double rate capture_clk to drive sampling.  (The bad
   // case seems to be a slave, because SCK is asynchronous and we don't have
   // the double-rate clock.)  The ADC mostly writes to SPI, so only uses
   // negedge SCKA when reading the configuration input (which does not exist
   // on the LTC2512-24).
   //

   wire capture_clk;
   capture_clk1 capture_clk1_instance
     (
      .clk_out1(capture_clk),
      .clk_in1_p(SYSCLK_P),
      .clk_in1_n(SYSCLK_N)
      );


   // Notes on data overrun/underrun:
   //
   // It is possible that when we need to read a sample to send to the DAC
   // that the write FIFO will be empty (underrun), or that when we want to
   // write an ADC sample, the read FIFO will be full (overrun).  This is bad,
   // and the larger Linux software context should try to set up buffering,
   // scheduling, etc., so this does not happen.  But when it does happen
   // (which is likely every so often) then we should recover gracefully.
   //
   // Handling of overrun/underrun is incompletely implemented here, and needs
   // software support also.  What necessarily happens is that ADC data is
   // dropped, and the DAC does not update (holding a fixed value).  The big
   // problem for us is that (in addition to causing a transient glitch) an
   // overrun/underrun can also cause permanent a phase jump between input and
   // output, which affects the ILEMT demodulation.  It is also in principle
   // possible that the sample/channel alignment could be corrupted so that
   // data is going to the wrong channels.  (I am guessing that alignment
   // problems are very unlikely because we transfer data as blocks.)
   //
   // ==> For now, we are enabling the ADC only when the DAC has data.
   //     If there is a DAC underrun, then we stop the ADC.  Likewise
   //     if the DAC is not open.  This gives synchronization without
   //     any EOF conditions that might complicate remote TCP access.
   //
   // Xillybus docs suggest forcing an EOF condition on the affected pipe to
   // tell the software that it needs to reinitialize.

   // Instantiation of the read FIFO for ADC data:
   // 
   // ADC data is represented as a left-justified signed integer.  The low 8
   // bits are zero with the LTC2512-24 on the current ILEMT input board.
   wire [31:0] capture_data;
   wire        capture_full;
   async_fifo_32 adc_fifo
     (
      .rst(!user_r_read_32_open),
      .wr_clk(capture_clk),
      .rd_clk(bus_clk),
      .din(capture_data),
      .wr_en(capture_en),
      .rd_en(user_r_read_32_rden),
      .dout(user_r_read_32_data),
      .full(capture_full),
      .empty(user_r_read_32_empty)
      );

   // Bundle all of the ADC inputs into a single word.  Note that (opposite to
   // our usual bit numbering) we make the MS bit be index 0 because it is the
   // zero'th input.
   wire [0:adc_channels-1] ADC_SDOA;
   assign ADC_SDOA
     = {IN0_SDOA1,
	IN0_SDOA2,
	IN0_SDOA3,
	IN1_SDOA1,
	IN1_SDOA2,
	IN1_SDOA3,
	IN2_SDOA1,
	IN2_SDOA2,
	IN2_SDOA3,
	IN3_SDOA1,
	IN3_SDOA2,
	IN3_SDOA3};


   // DAC status flags, used to control ADC also.
   wire dac_open, dac_underrun;

   // Synchronization tag, low bits of DAC data copied to low bits of
   // ADC data.
   wire [7:0] sync_tag;

   // Logic for acquiring from the input boards.  Sends data into the Xillybus
   // read 32 fifo, adc_fifo.
   multi_adc_interface the_adc
     (
      // Pins
      .adc_mclk(ICLK_MCLK_ENA),
      .adc_scka(SCKA),
      .adc_sync(ICLK_SYNC),
      .adc_sdi(ICLK_SDI),
      .adc_sdoa(ADC_SDOA),

      // Clocks
      .capture_clk(capture_clk),
      .bus_clk(bus_clk),

      // For synchronization, only enable ADC when the DAC is running.
      .enable(dac_open & ~dac_underrun),
      .sync_tag(sync_tag),

      // read FIFO interface
      .capture_data(capture_data),
      .capture_en(capture_en),
      .capture_full(capture_full),
      .user_r_read_32_empty(user_r_read_32_empty),

      // flags to/from Xillybus about file status
      .user_r_read_32_open(user_r_read_32_open),
      .user_r_read_32_eof(user_r_read_32_eof)
      );


   // Instantiation of the write FIFO for data sent to the DACs.
   wire [31:0] dac_fifo_data;
   wire dac_rden, dac_empty;
   async_fifo_32 dac_fifo
     (
      .wr_clk(bus_clk),
      .rd_clk(capture_clk),
      .rst(!user_w_write_32_open),
      .din(user_w_write_32_data),
      .wr_en(user_w_write_32_wren),
      .rd_en(dac_rden),
      .dout(dac_fifo_data),
      .full(user_w_write_32_full),
      .empty(dac_empty)
      );

   // dac_buffer_reg manages the reading from our end of the write FIFO.
   wire [dac_channels*32 - 1 : 0] dac_buffer;
   wire dac_request;
   // undriven pin dac_open_bus is constant 0
   dac_buffer_reg the_dac_buffer_reg
     (
      .capture_clk(capture_clk),
      .bus_clk(bus_clk),
      .dac_buffer(dac_buffer),
      .sync_tag(sync_tag),
      .dac_request(dac_request),
      .dac_underrun(dac_underrun),
      .dac_open(dac_open),
      .dac_fifo_open_bus(user_w_write_32_open),
      .dac_rden(dac_rden),
      .dac_fifo_data(dac_fifo_data),
      .dac_empty(dac_empty)
      );

   // multi_dac_interface is the interface for the output board
   multi_dac_interface the_dac
      (
       .capture_clk(capture_clk),
       .enable(dac_open),
       .dac_buffer(dac_buffer),
       .dac_request(dac_request),

       // DAC pins (all output)
       .DAC_BCK(DAC_BCK),
       .DAC_DATA_PINS(DAC_DATA_PINS),
       .DAC_LRCK(DAC_LRCK),
       .DAC_NOT_RST(DAC_NOT_RST)
       );

   always @(posedge capture_clk) begin
      LED1 <= ~dac_open;
      LED2 <= ~dac_underrun;
      LED3 <= ~capture_full;
      LED4 <= ~user_r_read_32_empty;
   end

   // Interface to the Built In Self Test DAC on the main board.  Data from
   // dac_buffer_reg can be diverted here rather than going to the normal
   // output on the DAC board.
   // bist_dac_interface bist_dac
   //    (
   //     .capture_clk(capture_clk),
   //     .reset(!dac_open),
   //     .enable(###),
   //     .dac_buffer(dac_buffer),
   //     .dac_request(dac_request),

   //     // DAC pins (all output)
   //     .BIST_SYNC(BIST_SYNC),
   //     .BIST_MOSI(BIST_MOSI),
   //     .BIST_SCLK(BIST_SCLK)
   //     );


   // Unused Xillybus interface signals
   assign user_r_read_8_eof = 0;
endmodule
