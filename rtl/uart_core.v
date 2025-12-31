
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
  reg  tx_start;
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
  reg                   rx_fifo_wen  ;
  reg                   rx_fifo_ren  ;
  reg  [DATA_WIDTH-1:0] rx_fifo_wdata;
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
  wire [31:0] status_reg ; // read only
  reg  [31:0] control_reg; // write/read
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
  reg [2:0] read_state ;
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
  reg [31:0] raddr_q;

  // Write
  reg  [31:0] wraddr_q    ;
  reg  [31:0] wdata_q     ;
  wire        ar_handshake;
  wire        r_handshake ;
  wire        aw_handshake;
  wire        w_handshake ;
  wire        b_handshake ;

  // register write
  always @(posedge axi_aclk_i) begin
    if (~axi_aresetn_i) begin
      control_reg <= 0;
    end else begin
      // lower reset after one cycle
      control_reg <= control_reg & ~32'h3;
      if (reg_wen) begin
        case (wraddr_q[3:0])
          4'h4 : begin
            control_reg <= reg_wdata;
          end
          default : ;
        endcase
      end
    end
  end

  assign status_reg = {28'd0, tx_fifo_empty, tx_fifo_full, rx_fifo_empty, rx_fifo_full};
  assign rx_fifo_rd = (raddr_q[3:0] == 4'h8);
  assign tx_fifo_wr = (wraddr_q[3:0] == 4'hc);
  assign reg_rd     = ((raddr_q[3:0] == 4'h0) || (raddr_q[3:0] == 4'h4));
  assign reg_wr     = (wraddr_q[3:0] == 4'h4);

  assign rx_fifo_rst = control_reg[0];
  assign tx_fifo_rst = control_reg[1];



  //*********************************
  //
  // READ FSM
  //
  //*********************************

  always @(posedge axi_aclk_i) begin
    if (!axi_aresetn_i) begin
      read_state  <= AR_READ;
      axi_arready <= 0;
      axi_rvalid  <= 0;
      axi_rresp   <= 0;
      axi_rdata   <= 0;
      //
      rx_fifo_ren <= 0;
    end
    else begin
      case (read_state)
        AR_READ : begin
          axi_arready <= 1;
          axi_rvalid  <= 0;
          if (ar_handshake) begin
            raddr_q     <= axi_araddr_i;
            // on axi read address handshake, register
            // the read data of the specified address
            axi_arready <= 0;
            //
            read_state  <= R_READ1;
          end
        end
        R_READ1 : begin
          axi_arready <= 0;
          axi_rvalid  <= 0;
          // 1 cycle if a register read
          // 3 cycles if a fifo read
          if (reg_rd) begin
            case (raddr_q[3:0])
              4'h0    : axi_rdata <= status_reg;
              4'h4    : axi_rdata <= control_reg;
              default : axi_rdata <= 0;
            endcase
            axi_rresp  <= RESP_OKAY;
            read_state <= R_READ4;
          end else if (rx_fifo_rd) begin
            if (!rx_fifo_empty) begin
              // wait one cycle to read fifo
              rx_fifo_ren <= 1;
              axi_rresp   <= RESP_OKAY;
              read_state  <= R_READ2;
            end else begin
              // send an error; the fifo is empty
              axi_rdata  <= 0;
              axi_rresp  <= RESP_ERR;
              read_state <= R_READ4;
            end
          end
        end
        R_READ2 : begin
          axi_arready <= 0;
          axi_rvalid  <= 0;
          // disable fifo read enable
          rx_fifo_ren <= 0;
          //
          read_state  <= R_READ3;

        end
        R_READ3 : begin
          axi_arready <= 0;
          axi_rvalid  <= 0;
          // sample fifo read data and move on to wait for handshake
          axi_rdata   <= rx_fifo_rdata;
          //
          read_state  <= R_READ4;

        end
        R_READ4 : begin
          axi_arready <= 0;
          axi_rvalid  <= 1;
          // place read data and response on the axi line
          // wait for handshake
          if (r_handshake) begin
            // on axi read response handshake, place the
            // read response on the specified axi signal
            axi_arready <= 1;
            axi_rvalid  <= 0;
            //
            read_state  <= AR_READ;
          end
        end
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
      axi_bresp     <= 0;
      wraddr_q      <= 0;
      wdata_q       <= 0;
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
            if (!tx_fifo_full) begin
              tx_fifo_wen   <= 1;
              tx_fifo_wdata <= wdata_q;
              axi_bresp     <= RESP_OKAY;
              write_state   <= B_WAIT;
            end else begin
              axi_bresp   <= RESP_ERR;
              write_state <= B_WAIT;
            end
          end  else if (reg_wr) begin
            reg_wen     <= 1;
            reg_wdata   <= wdata_q;
            axi_bresp   <= RESP_OKAY;
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
          if (b_handshake) begin
            axi_awready <= 1;
            axi_wready  <= 0;
            axi_bvalid  <= 0;
            write_state <= AW_WAIT;
          end
        end
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

  uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_rx_inst (
    .clk_i      (axi_aclk_i   ),
    .rstn_i     (axi_aresetn_i),
    .rx_i       (rx_i         ),
    .busy_o     (rx_busy      ),
    .rx_msg_o   (rx_byte      ),
    .done_o     (rx_byte_valid),
    .frame_err_o(rx_frame_err )
  );

  uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_tx_inst (
    .clk_i    (axi_aclk_i   ),
    .rstn_i   (axi_aresetn_i),
    .start_i  (tx_start     ),
    .tx_byte_i(tx_fifo_rdata),
    .tx_o     (tx_o         ),
    .busy_o   (tx_busy      ),
    .done_o   (             )
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
endmodule
