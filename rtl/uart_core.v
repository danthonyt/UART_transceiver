`timescale 1ns / 1ps
module uart_core #(parameter DATA_WIDTH = 8, FIFO_DEPTH = 16, CLKS_PER_BIT = 4) (
  // global signals
  input         axi_aclk_i   ,
  input         axi_aresetn_i,
  // read address channel
  input  [31:0] axi_araddr_i ,
  input         axi_arvalid_i,
  output        axi_arready_o,
  // read data channel
  output [31:0] axi_rdata_o  ,
  output [ 1:0] axi_rresp_o  ,
  output        axi_rvalid_o ,
  input         axi_rready_i ,
  // write address channel
  input         axi_awvalid_i,
  output        axi_awready_o,
  input  [31:0] axi_awaddr_i ,
  // write data channel
  input         axi_wvalid_i ,
  output        axi_wready_o ,
  input  [31:0] axi_wdata_i  ,
  // write response channel
  output        axi_bvalid_o ,
  input         axi_bready_i ,
  output [ 1:0] axi_bresp_o  ,
  // uart rx and tx
  input         rx_i         ,
  output        tx_o
);

  // tx uart signals
  wire tx_start;
  wire tx      ;
  wire tx_busy ;
  // rx uart signals
  wire                  rx_busy      ;
  wire [DATA_WIDTH-1:0] rx_byte      ;
  wire                  rx_frame_err ;
  wire                  rx_byte_valid;
  // tx fifo signals
  reg                   tx_fifo_wen  ;
  reg                   tx_fifo_ren  ;
  reg  [DATA_WIDTH-1:0] tx_fifo_wdata;
  wire [DATA_WIDTH-1:0] tx_fifo_rdata;
  wire                  tx_fifo_empty;
  wire                  tx_fifo_full ;
  wire                  tx_fifo_rst  ;
  // rx fifo signals
  wire                  rx_fifo_wen  ;
  wire                  rx_fifo_ren  ;
  wire [DATA_WIDTH-1:0] rx_fifo_wdata;
  wire [DATA_WIDTH-1:0] rx_fifo_rdata;
  wire                  rx_fifo_empty;
  wire                  rx_fifo_full ;
  wire                  rx_fifo_rst  ;
  localparam [1:0] RESP_OKAY = 2'b00,
    RESP_ERR = 2'b10;
  /******************************************/
  //
  //  Uart core registers
  //
  /******************************************/
  reg  [31:0] reg_wdata  ;
  reg         reg_wen    ;
  reg  [31:0] status_reg ; // read only
  reg  [31:0] control_reg; // write/read
  reg  [31:0] reg_rdata  ;
  wire        rx_fifo_rd ;
  wire        tx_fifo_wr ;
  wire        reg_rd     ;
  wire        reg_wr     ;
  /******************************************/
  //
  //  AXI LITE SIGNALS
  //
  /******************************************/
  // read fsm states
  localparam [2:0]
    AR_READ = 3'b000,
    R_READ1 = 3'b001,
    R_READ2 = 3'b010,
    R_READ3 = 3'b011,
    R_READ4 = 3'b100;


  // write fsm states
  localparam [2:0]
    AW_WAIT = 2'b00,
    W_WAIT = 2'b01,
    B_WRITE = 2'b10,
    B_WAIT = 2'b11;

  reg [2:0] write_state;
  reg [1:0] read_state ;
  // read address channel
  reg axi_arready;
  // read data channel
  reg [31:0] axi_rdata ;
  reg [ 1:0] axi_rresp ;
  reg        axi_rvalid;
  // write address channel
  reg axi_awready;
  // write data channel
  reg axi_wready;
  // write response channel
  reg       axi_bvalid;
  reg [1:0] axi_bresp ;


  // transaction signals sampled
  // from axi lite bus
  // Read
  reg [31:0] rdata_q;
  reg [31:0] raddr_q;
  reg        rresp_q;

  // Write
  reg  [31:0] wraddr_q    ;
  reg  [31:0] wdata_q     ;
  reg         bresp_q     ;
  wire        ar_handshake;
  wire        r_handshake ;
  wire        aw_handshake;
  wire        w_handshake ;
  wire        b_handshake ;

  // register write
  always @(posedge axi_aclk_i) begin
    if (~axi_aresetn_i) begin
      control_reg <= 0;
    end else if (reg_wen) begin
      case (addr_i)
        4'h4 : begin
          control_reg <= reg_wdata;
        end
        default : ;
      endcase
    end
  end

  assign status_reg = {28'd0, tx_fifo_empty_i, tx_fifo_full_i, rx_fifo_empty_i, rx_fifo_full_i};
  assign rx_fifo_rd = (raddr_q == 4'h8);
  assign tx_fifo_wr = (wraddr_q == 4'hc);
  assign reg_rd     = ((raddr_q == 4'h0) || (raddr_q == 4'h4));
  assign reg_wr     = (wraddr_q == 4'h4);

  assign rx_fifo_rst = control_reg[0];
  assign tx_fifo_rst = control_reg[1];



  //*********************************
  //
  // READ FSM
  //
  //*********************************

  always @(posedge axi_aclk_i) begin
    if (!axi_aresetn_i) begin
      read_state  <= RESET_READ;
      axi_arready <= 0;
      axi_rvalid  <= 0;
      axi_rresp   <= 0;
      axi_rdata   <= 0;
      //
      rdata_q     <= 0;
      rx_fifo_ren <= 0;
    end
    else begin
      case (read_state)
        AR_READ : begin
          axi_arready <= 1;
          axi_rvalid  <= 0;
          if (ar_handshake) begin
            raddr_q         <= axi_araddr_i;
            // on axi read address handshake, register
            // the read data of the specified address
            axi_arready     <= 0;
            //
            next_read_state <= R_READ1;
          end
        end
        R_READ1 : begin
          axi_arready <= 0;
          axi_rvalid  <= 0;
          // 1 cycle if a register read
          // 3 cycles if a fifo read
          if (reg_rd) begin
            case (raddr_q)
              4'h0    : rdata_q <= status_reg;
              4'h4    : rdata_q <= control_reg;
              default : rdata_q <= 0;
            endcase
            rresp_q         <= RESP_OKAY;
            next_read_state <= R_READ4;
          end else if (rx_fifo_rd) begin
            if (!rx_fifo_empty_i) begin
              // wait one cycle to read fifo
              rx_fifo_ren_o   <= 1;
              rresp_q         <= RESP_OKAY;
              next_read_state <= R_READ2;
            end else begin
              // send an error; the fifo is empty
              rresp_q         <= RESP_ERR;
              next_read_state <= R_READ4;
            end
          end
        end
        R_READ2 : begin
          axi_arready     <= 0;
          axi_rvalid      <= 0;
          // disable fifo read enable
          rx_fifo_ren     <= 0;
          //
          next_read_state <= R_READ3;

        end
        R_READ3 : begin
          axi_arready     <= 0;
          axi_rvalid      <= 1;
          // sample fifo read data and move on to wait for handshake
          rdata_q         <= rx_fifo_rdata;
          //
          next_read_state <= R_READ4;

        end
        R_READ4 : begin
          axi_arready <= 0;
          axi_rvalid  <= 1;
          // wait for handshake
          if (r_handshake) begin
            // on axi read response handshake, place the
            // read response on the specified axi signal
            axi_rvalid      <= 1;
            axi_rresp       <= rresp_q;
            axi_rdata       <= rdata_q;
            //
            axi_arready     <= 1;
            axi_rvalid      <= 0;
            //
            next_read_state <= AR_READ;
          end
        end
        default : next_read_state <= AR_READ;
      endcase
    end
  end

  //*********************************
  //
  // WRITE FSM
  //
  //*********************************


  // next write state fsm register
  always @(posedge axi_aclk_i) begin
    if (!axi_aresetn_i) begin
      axi_awready   <= 0;
      axi_wready    <= 0;
      axi_bvalid    <= 0;
      wraddr_q      <= 0;
      wdata_q       <= 0;
      bresp_q       <= 0;
      tx_fifo_wen   <= 0;
      tx_fifo_wdata <= 0;
      reg_wen       <= 0;
      reg_wdata     <= 0;
      write_state   <= AW_WAIT;
    end
    else begin
      case (write_state)
        AW_WAIT : begin
          // wait for address write handshake
          axi_awready <= 1;
          axi_wready  <= 0;
          axi_bvalid  <= 0;
          if (aw_handshake) begin
            wraddr_q    <= axi_awaddr_i;
            write_state <= W_WAIT;
          end
        end
        W_WAIT : begin
          // wait for write handshake
          axi_awready <= 0;
          axi_wready  <= 1;
          axi_bvalid  <= 0;
          if (w_handshake) begin
            wdata_q     <= axi_wdata_i;
            write_state <= B_WRITE;
          end
        end
        B_WRITE : begin
          // write to appropriate register or fifo
          if (tx_fifo_wr) begin
            if (!tx_fifo_full_i) begin
              tx_fifo_wen   <= 1;
              tx_fifo_wdata <= wdata_q;
              bresp_q       <= RESP_OKAY;
              write_state   <= B_WAIT;
            end else begin
              bresp_q     <= RESP_ERR;
              write_state <= B_WAIT;
            end
          end  else if (reg_wr) begin
            reg_wen     <= 1;
            reg_wdata   <= wdata_q;
            bresp_q     <= RESP_OKAY;
            write_state <= B_WAIT;
          end
        end
        B_WAIT : begin
          axi_awready <= 0;
          axi_wready  <= 0;
          axi_bvalid  <= 1;
          // lower write enables
          tx_fifo_wen <= 0;
          reg_wen     <= 0;
          // place response on axil line
          axi_bresp   <= bresp_q;
          if (b_handshake) begin
            axi_awready <= 1;
            axi_wready  <= 0;
            axi_bvalid  <= 0;
            write_state <= AW_WAIT;
          end
        end
        default : write_state <= AW_WAIT;
      endcase
    end
  end

  //*********************************
  //
  // assign statements
  //
  //*********************************


  assign ar_handshake = axi_arvalid_i & axi_arready;
  assign r_handshake  = axi_rvalid & axi_rready_i;
  assign aw_handshake = axi_awvalid_i & axi_awready;
  assign w_handshake  = axi_wvalid_i & axi_wready;
  assign b_handshake  = axi_bvalid & axi_bready_i;

  assign axi_arready_o = axi_arready;
  assign axi_rresp_o   = axi_rresp;
  assign axi_rvalid_o  = axi_rvalid;
  assign axi_rdata_o   = axi_rdata;
  assign axi_awready_o = axi_awready;
  assign axi_wready_o  = axi_wready;
  assign axi_bvalid_o  = axi_bvalid;
  assign axi_bresp_o   = axi_bresp;

  /******************************************/
  //
  //    MODULES
  //
  /******************************************/

  uart_rx #(
    .DATA_WIDTH  (DATA_WIDTH  ),
    .CLKS_PER_BIT(CLKS_PER_BIT)
  ) uart_rx_inst (
    .clk_i          (axi_aclk_i    ),
    .rst_i          (~axi_aresetn_i),
    .rx_i           (rx_i          ),
    .busy_o         (rx_busy       ),
    .rx_byte_o      (rx_byte       ),
    .rx_byte_valid_o(rx_byte_valid ),
    .frame_err_o    (rx_frame_err  )
  );

  uart_tx #(
    .DATA_WIDTH  (DATA_WIDTH  ),
    .CLKS_PER_BIT(CLKS_PER_BIT)
  ) uart_tx_inst (
    .clk_i    (axi_aclk_i    ),
    .rst_i    (~axi_aresetn_i),
    .start_i  (tx_start      ),
    .tx_byte_i(tx_fifo_rdata ),
    .tx_o     (tx            ),
    .busy_o   (tx_busy       )
  );

  fifo #(
    .DEPTH (FIFO_DEPTH),
    .DWIDTH(DATA_WIDTH)
  ) tx_fifo_inst (
    .rst_i  (~axi_aresetn_i || tx_fifo_rst),
    .clk_i  (axi_aclk_i                   ),
    .wen_i  (tx_fifo_wen                  ),
    .ren_i  (tx_fifo_ren                  ),
    .wdata_i(tx_fifo_wdata                ),
    .rdata_o(tx_fifo_rdata                ),
    .empty_o(tx_fifo_empty                ),
    .full_o (tx_fifo_full                 )
  );

  fifo #(
    .DEPTH (FIFO_DEPTH),
    .DWIDTH(DATA_WIDTH)
  ) rx_fifo_inst (
    .rst_i  (~axi_aresetn_i || rx_fifo_rst),
    .clk_i  (axi_aclk_i                   ),
    .wen_i  (rx_fifo_wen                  ),
    .ren_i  (rx_fifo_ren                  ),
    .wdata_i(rx_fifo_wdata                ),
    .rdata_o(rx_fifo_rdata                ),
    .empty_o(rx_fifo_empty                ),
    .full_o (rx_fifo_full                 )
  );

  /******************************************/
  //
  //    TX and RX fifo glue logic
  //
  /******************************************/
  // uart tx start and fifo read control
  // uart rx write control
  always @(posedge axi_aclk_i) begin
    if (~axi_aresetn_i) begin
      tx_start    <= 0;
      tx_fifo_ren <= 0;
    end else begin
      tx_fifo_ren <= 0;
      tx_start    <= 0;
      // only start tx if tx fifo is not empty and
      // tx fifo is not in reset
      if (!tx_fifo_empty && !tx_fifo_rst && !tx_busy) begin
        tx_fifo_ren <= 1;
      end
      // read data is valid one cycle after asserting read enable
      // unless the fifo was reset
      if (!tx_fifo_rst && tx_fifo_ren && !tx_busy) begin
        tx_start    <= 1;
        tx_fifo_ren <= 0;
      end
    end
  end

  always @(posedge axi_aclk_i) begin
    if (~axi_aresetn_i) begin
      rx_fifo_wdata <= 0;
      rx_fifo_wen   <= 0;
    end else begin
      rx_fifo_wdata <= 0;
      rx_fifo_wen   <= 0;
      if (rx_byte_valid && !rx_fifo_full && !rx_fifo_rst) begin
        rx_fifo_wdata <= rx_byte;
        rx_fifo_wen   <= 1;
      end
    end
  end
  assign tx_o = tx;
  /******************************************/
  //
  //    FORMAL VERIFICATION
  //
  /******************************************/
`ifdef FORMAL
default clocking @(posedge axi_aclk_i);
endclocking
// reset on start
initial assume (!axi_aresetn_i);
low_enables_on_reset:
assert property (~axi_aresetn_i |-> ##1 !tx_fifo_ren && !rx_fifo_wen);
// tx fifo read enable should never go high if the tx fifo is in reset,
// it is empty, or the tx is busy
tx_fifo_read_low :
assert property (disable iff (~axi_aresetn_i) tx_fifo_rst || tx_fifo_empty || tx_busy |-> ##1 !tx_fifo_ren);

// rx fifo write enable should never go high if the rx fifo is in reset,
// the rx fifo is full, or the rx byte is invalid
rx_fifo_write_low :
assert property (disable iff (~axi_aresetn_i) rx_fifo_rst || rx_fifo_full || !rx_byte_valid |-> ##1 !rx_fifo_wen);

// write enables are only high for one cycle
assert property (disable iff (!axi_aresetn_i) $rose(tx_fifo_wen) |-> ##1 $fell(tx_fifo_wen));
assert property (disable iff (!axi_aresetn_i) $rose(reg_wen) |-> ##1 $fell(reg_wen));


  // During reset the following interface requirements apply:
  // • a master interface must drive ARVALID, AWVALID, and WVALID LOW
  // • a slave interface must drive RVALID and BVALID LOW
  // • all other signals can be driven to any value. (p A3-36)
master_valids_low_on_reset :
assume property( @(posedge axi_aclk_i)
(!axi_aresetn_i |-> ##1 ~(axi_wvalid_i | axi_arvalid_i | axi_awvalid_i)));
slave_valids_low_on_reset :
assert property (@(posedge axi_aclk_i) (!axi_aresetn_i |-> ##1 ~(axi_rvalid_o | axi_bvalid_o)));

  /******************************************/
  //
  //    AXI LITE COMPLIANCE
  //
  /******************************************/
// In Figure A3-2, the source presents the address, data or control information after T1 and asserts the VALID signal.
// "The destination asserts the READY signal after T2, and the source must keep its information stable until the transfer
// occurs at T3, when this assertion is recognized. (p A3-37)"
// data is held stable while valid is high
property stable_source_data(logic valid, logic [31:0] data, logic rst_n);
disable iff (!rst_n) valid & !$rose(valid) |-> ($stable(data) | !valid);
endproperty
stable_data_ar :
assume property (stable_source_data(
axi_arvalid_i, axi_araddr_i, axi_aresetn_i
));
stable_data_r :
assert property (stable_source_data(
axi_rvalid_o, axi_rdata_o, axi_aresetn_i
));
stable_data_aw :
assume property (stable_source_data(
axi_awvalid_i, axi_awaddr_i, axi_aresetn_i
));
stable_data_w :
assume property (stable_source_data(
axi_wvalid_i, axi_wdata_i, axi_aresetn_i
));
stable_data_b :
assert property (stable_source_data(
axi_bvalid_o, axi_bresp_o, axi_aresetn_i
));

// Once VALID is asserted it must remain asserted until the handshake occurs, at a rising clock edge at which VALID
// and READY are both asserted. (p A3-37)
property stable_valid_high(logic valid, logic ready, logic rst_n);
disable iff (!rst_n) (valid & ~ready) |-> ##1 valid;
endproperty

valid_stays_high_until_handshake_w :
assume property (
  stable_valid_high(axi_wvalid_i, axi_wready_o, axi_aresetn_i)
  );
valid_stays_high_until_handshake_ar :
assume property (
  stable_valid_high(axi_arvalid_i, axi_arready_o, axi_aresetn_i)
);
valid_stays_high_until_handshake_aw :
assume property (stable_valid_high(
axi_awvalid_i, axi_awready_o, axi_aresetn_i
));
valid_stays_high_until_handshake_r :
assert property (stable_valid_high(
axi_rvalid_o, axi_rready_i, axi_aresetn_i
));
valid_stays_high_until_handshake_b :
assert property (stable_valid_high(
axi_bvalid_o, axi_bready_i, axi_aresetn_i
));

  /******************************************/
  //
  //    COVER STATEMENTS
  //
  /******************************************/
// make sure a read can happen
read_complete :
cover property (
  disable iff (!axi_aresetn_i) 
  read_state == AR_READ  ##1 
  read_state == R_READ1  ##1 
  read_state == R_READ2  ##1 
  read_state == R_READ3  ##1 
  read_state == R_READ4  ##1
  read_state == AR_READ
  );
// make sure a write can happen
write_complete :
cover property (
  disable iff (!axi_aresetn_i) 
  write_state == AW_WAIT ##1 
  write_state == W_WAIT  ##1 
  write_state == B_WRITE ##1 
  write_state == B_WAIT  ##1
  write_state == AW_WAIT
  );

// tx must hold its value if baud tick is false and is busy

// covers:
// write to non-full tx fifo
cover property (state == IDLE && wb_cyc_i && wb_stb_i && tx_fifo_wr && !tx_fifo_full_i##1
state == IDLE && wb_ack_o && !wb_err_o);
// write to full tx fifo - error
cover property (state == IDLE && wb_cyc_i && wb_stb_i && tx_fifo_wr && tx_fifo_full_i ##1
state == IDLE && !wb_ack_o && wb_err_o);
// read from non empty rx fifo
cover property (state == IDLE && wb_cyc_i && wb_stb_i && rx_fifo_rd && !rx_fifo_empty_i ##1
state == READ_FIFO_WAIT && rx_fifo_ren_o ##1 state == IDLE && wb_ack_o && wb_dat_o == rx_fifo_rdata_i);
// read from empty rx fifo - error
cover property (state == IDLE && wb_cyc_i && wb_stb_i && rx_fifo_rd && rx_fifo_empty_i ##1
state == IDLE && !wb_ack_o && wb_err_o);
// invalid request
cover property (state == IDLE && wb_cyc_i && wb_stb_i && !rx_fifo_rd  && !tx_fifo_wr && !reg_rd && !reg_wr ##1
state == IDLE && !wb_ack_o && wb_err_o);
// read from register
cover property (state == IDLE && wb_cyc_i && wb_stb_i && reg_rd ##1
state == IDLE && wb_ack_o && !wb_err_o && wb_dat_o == reg_rdata);
// write to register
cover property (state == IDLE && wb_cyc_i && wb_stb_i && reg_wr ##1
state == IDLE && wb_ack_o && !wb_err_o);

`endif
endmodule
