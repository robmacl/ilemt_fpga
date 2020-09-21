module ilemt (DEBUG1, DEBUG2, DEBUG3, DEBUG4, DEBUG5, DEBUG6, DEBUG7, DEBUG8, LED1, LED2, LED3, LED4, IN3_CARDSEL, IN2_CARDSEL, IN1_CARDSEL, IN0_CARDSEL, BIST_SYNC, BIST_MOSI, BIST_SCLK, DAC_BCK, DAC_LRCK, DAC_DATA0, DAC_DATA1, DOUTL5, DOUTL6, DFB1_P, DFB1_N, DFB2_P, DFB2_N, DFB3_P, DFB3_N, DFB4_P, DFB4_N, DOUT1_P, DOUT1_N, DOUT2_P, DOUT2_N, DOUT3_P, DOUT3_N, DOUT4_P, DOUT4_N, DOUT5_P, DOUT5_N, DOUT6_P, DOUT6_N, DOUT7_P, DOUT7_N, DOUT8_P, DOUT8_N, ICLK_SYNC, ICLK_SDI, ICLK_MCLK_ENA_P, ICLK_MCLK_ENA_N, SCKB_P, SCKB_N, SCKA_P, SCKA_N, SYSCLK_P, SYSCLK_N, ICLK_DEBUG_P, ICLK_DEBUG_N, IN3_SDOA1_P, IN3_SDOA1_N, IN3_SDOB1_P, IN3_SDOB1_N, IN3_SDOA2_P, IN3_SDOA2_N, IN3_SDOA3_P, IN3_SDOA3_N, IN2_SDOA1_P, IN2_SDOA1_N, IN2_SDOB1_P, IN2_SDOB1_N, IN2_SDOA2_P, IN2_SDOA2_N, IN2_SDOA3_P, IN2_SDOA3_N, IN1_SDOA1_P, IN1_SDOA1_N, IN1_SDOB1_P, IN1_SDOB1_N, IN1_SDOA2_P, IN1_SDOA2_N, IN1_SDOA3_P, IN1_SDOA3_N, IN0_SDOA1_P, IN0_SDOA1_N, IN0_SDOB1_P, IN0_SDOB1_N, IN0_SDOA2_P, IN0_SDOA2_N, IN0_SDOA3_P, IN0_SDOA3_N);

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
   output LED1;
   output LED2;
   output LED3;
   output LED4;

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
   output DAC_BCK;
   output DAC_LRCK;
   output DAC_DATA0;
   output DAC_DATA1;
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
   output DOUT1_P;
   output DOUT1_N;
   output DOUT2_P;
   output DOUT2_N;
   output DOUT3_P;
   output DOUT3_N;
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
   wire   DOUT1;
   OBUFDS OBUFDS_DOUT1 (.O(DOUT1_P), .OB(DOUT1_N), .I(DOUT1));
   wire   DOUT2;
   OBUFDS OBUFDS_DOUT2 (.O(DOUT2_P), .OB(DOUT2_N), .I(DOUT2));
   wire   DOUT3;
   OBUFDS OBUFDS_DOUT3 (.O(DOUT3_P), .OB(DOUT3_N), .I(DOUT3));
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
   // More specifically, what we are mostly doing is instantiating the
   // Xillybus core and defining the names of the signals that go to/from the
   // core.  In the case of FIFOs, this the Xillybus end of the FIFO. (The
   // names of the signals on our side of the FIFO are defined elsewhere.)
   // There are also templates for the (currently unused) Xillybus random
   // access modes xillybus_mem (which looks like a Unix file) and xillybus
   // lite, which supports memory mapped registers.

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

   // capture_clk is to generate the ADC and DAC clocking: adc_scka, adc_mclk,
   // etc.
   // 
   // See adc_params.v for notes on current on current clock configuration,
   // and also the MMCM/PLL IP configuration wizard.  capture_clk needs to be
   // phase shifted wrt. SYSCLK to give maximum setup/hold time on the
   // MCLK_ENA signal.  Ideally this should be phase-tweaked to get that
   // measured relationship at the MCLK flip-flop.
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
   // the double-rate clock.)  The ADC mostly writes, so only uses negedge
   // SCKA for the configuration input (which does not exist on the
   // LTC2512-24).

   wire capture_clk;
   capture_clk1 capture_clk1_instance
     (
      .clk_out1(capture_clk),
      .clk_in1_p(SYSCLK_P),
      .clk_in1_n(SYSCLK_N)
      );


   // Output from ADC to FIFO.  The data format is a left-justified signed
   // integer.  The low 8 bits are zero with the LTC2512-24.
   wire [31:0] capture_data;

   // ADC FIFO full.
   wire        capture_full;

   // Bundle all of the ADC inputs into a single word.
   wire [adc_channels-1:0] ADC_SDOA;
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

   // Logic for acquiring on the ADC, stores data into the Xillybus
   // read 32 fifo, fifo_32
   multi_adc_interface the_adc
     (
      .adc_mclk(ICLK_MCLK_ENA),
      .adc_scka(SCKA),
      .adc_sync(ICLK_SYNC),
      .adc_sdi(ICLK_SDI),
      .adc_sdoa(ADC_SDOA),
      .capture_clk(capture_clk),
      .bus_clk(bus_clk),
      .capture_data(capture_data),
      .capture_en(capture_en),
      .capture_full(capture_full),
      .user_r_read_32_empty(user_r_read_32_empty),
      .user_r_read_32_open(user_r_read_32_open),
      .user_r_read_32_eof(user_r_read_32_eof)
      );

   // Sends data from 32 bit write FIFO to DAC.
   // 
   // ### eventually set things up so that ADC actually starts when
   // the first DAC data arrives.  This insures synchronization.  We
   // have been making do without any synchronization so far, but it
   // could allow us to know what the phase should be.  Advantage of
   // not doing is that allows us to read data when no output is
   // supplied.
   wire dac_rden, dac_empty;

   // FIFO output word
   wire [31:0] dac_fifo_data;
   
   assign dac_sck = capture_clk;
   wire [1:0] DAC_DATA;
   assign DAC_DATA = {DAC_DATA0, DAC_DATA1};
   multi_dac_interface the_dac
      (
       .dac_bck(DAC_BCK),
       .dac_data(DAC_DATA),
       .dac_lrck(DAC_LRCK),
       .capture_clk(capture_clk),
       .bus_clk(bus_clk),
       .dac_open_bus(user_w_write_32_open),
       .dac_rden(dac_rden),
       .dac_fifo_data(dac_fifo_data),
       .dac_empty(dac_empty)
       );


   // DAC input data
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

   // ADC output data
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
   

   assign  user_r_read_8_eof = 0;
endmodule
