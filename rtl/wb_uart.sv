`timescale 1ns/1ps
module wb_uart 
#(
  parameter WB_ADDR_WIDTH=32
)
(
    input logic CLK_I,
    input logic RST_I,

    // wishbone interface
    input logic [WB_ADDR_WIDTH-1:0] WB_ADR_I,
    input logic WB_WE_I,
    input logic [31:0] WB_DAT_I,
    input logic WB_CYC_I,
    input logic WB_STB_I,

    output logic [31:0] WB_DAT_O,
    output logic WB_ACK_O,
    output logic WB_ERR_O,

    input logic RX_I,
    output logic TX_O
  );

  logic [3:0] wb_adr_truncated;
  localparam DATA_WIDTH = 8;
  localparam FIFO_DEPTH = 16;
  localparam CLKS_PER_BIT = 4;

  logic rx_fifo_rst;
  logic tx_fifo_rst;

  logic tx_start;
  logic tx;
  logic tx_busy;

  logic rx_busy;
  logic [DATA_WIDTH-1:0] rx_byte;
  logic rx_frame_err;
  logic rx_byte_valid;

  logic tx_fifo_wen;
  logic tx_fifo_ren;
  logic [DATA_WIDTH-1:0] tx_fifo_wdata;
  logic [DATA_WIDTH-1:0] tx_fifo_rdata;
  logic tx_fifo_empty;
  logic tx_fifo_full;

  logic rx_fifo_wen;
  logic rx_fifo_ren;
  logic [DATA_WIDTH-1:0] rx_fifo_wdata;
  logic [DATA_WIDTH-1:0] rx_fifo_rdata;
  logic rx_fifo_empty;
  logic rx_fifo_full;


  uart_regfile  uart_regfile_inst (
    .CLK_I(CLK_I),
    .RST_I(RST_I),
    .WB_ADR_I(wb_adr_truncated),
    .WB_WE_I(WB_WE_I),
    .WB_DAT_I(WB_DAT_I),
    .WB_CYC_I(WB_CYC_I),
    .WB_STB_I(WB_STB_I),
    .WB_DAT_O(WB_DAT_O),
    .WB_ACK_O(WB_ACK_O),
    .WB_ERR_O(WB_ERR_O),
    .TX_FIFO_FULL_I(tx_fifo_full),
    .TX_FIFO_EMPTY_I(tx_fifo_empty),
    .TX_FIFO_WEN_O(tx_fifo_wen),
    .TX_FIFO_WDATA_O(tx_fifo_wdata),
    .RX_FIFO_RDATA_I(rx_fifo_rdata),
    .RX_FIFO_FULL_I(rx_fifo_full),
    .RX_FIFO_EMPTY_I(rx_fifo_empty),
    .RX_FIFO_REN_O(rx_fifo_ren),
    .RX_FIFO_RST_O(rx_fifo_rst),
    .TX_FIFO_RST_O(tx_fifo_rst)
  );

  uart_tx # (
    .DATA_WIDTH(DATA_WIDTH),
    .CLKS_PER_BIT(CLKS_PER_BIT)
  )
  uart_tx_inst (
    .CLK_I(CLK_I),
    .RST_I(RST_I),
    .START_I(tx_start),
    .TX_BYTE_I(tx_fifo_rdata),
    .TX_O(tx),
    .BUSY_O(tx_busy)
  );

  uart_rx # (
    .DATA_WIDTH(DATA_WIDTH),
    .CLKS_PER_BIT(CLKS_PER_BIT)
  )
  uart_rx_inst (
    .CLK_I(CLK_I),
    .RST_I(RST_I),
    .RX_I(RX_I),
    .BUSY_O(rx_busy),
    .RX_BYTE_O(rx_byte),
    .RX_BYTE_VALID_O(rx_byte_valid),
    .FRAME_ERR_O(rx_frame_err)
  );

  fifo # (
    .DEPTH(FIFO_DEPTH),
    .DWIDTH(DATA_WIDTH)
  )
  tx_fifo_inst (
    .RST_I(RST_I),
    .CLK_I(CLK_I),
    .WEN_I(tx_fifo_wen),
    .REN_I(tx_fifo_ren),
    .DATA_I(tx_fifo_wdata),
    .DATA_O(tx_fifo_rdata),
    .EMPTY_O(tx_fifo_empty),
    .FULL_O(tx_fifo_full)
  );


  fifo # (
    .DEPTH(FIFO_DEPTH),
    .DWIDTH(DATA_WIDTH)
  )
  rx_fifo_inst (
    .RST_I(RST_I),
    .CLK_I(CLK_I),
    .WEN_I(rx_fifo_wen),
    .REN_I(rx_fifo_ren),
    .DATA_I(rx_fifo_wdata),
    .DATA_O(rx_fifo_rdata),
    .EMPTY_O(rx_fifo_empty),
    .FULL_O(rx_fifo_full)
  );

  // uart tx start and fifo read control
  // uart rx write control 
  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      tx_start <= 0;
      tx_fifo_ren <= 0;
    end else begin
      tx_fifo_ren <= 0;
      tx_start <= 0;
      // only start tx if tx fifo is not empty and 
      // tx fifo is not in reset
      if (!tx_fifo_empty && !tx_fifo_rst && !tx_busy) begin
        tx_fifo_ren <= 1;
      end
      // read data is valid one cycle after asserting read enable
      // unless the fifo was reset
      if (!tx_fifo_rst && tx_fifo_ren && !tx_busy) begin
        tx_start <= 1;
        tx_fifo_ren <= 0;
      end
    end
  end

  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      rx_fifo_wdata <= 0;
      rx_fifo_wen <= 0;
    end else begin
      rx_fifo_wdata <= 0;
      rx_fifo_wen <= 0;
      if (rx_byte_valid && !rx_fifo_full && !rx_fifo_rst) begin
        rx_fifo_wdata <= rx_byte;
        rx_fifo_wen <= 1;
      end
    end
  end
  assign TX_O = tx;
  assign wb_adr_truncated = WB_ADR_I[3:0];
  /******************************************/
  //
  //    FORMAL VERIFICATION
  //
  /******************************************/
`ifdef FORMAL
  default clocking @(posedge CLK_I);
  endclocking
  assert property (RST_I |-> ##1 !tx_fifo_ren && !rx_fifo_wen); 
  // tx fifo read enable should never go high if the tx fifo is in reset,
  // it is empty, or the tx is busy
  tx_fifo_read_low:
  assert property (disable iff (RST_I) tx_fifo_rst || tx_fifo_empty || tx_busy |-> ##1 !tx_fifo_ren);

  // rx fifo write enable should never go high if the rx fifo is in reset,
  // the rx fifo is full, or the rx byte is invalid
  rx_fifo_write_low:
  assert property (disable iff (RST_I) rx_fifo_rst || rx_fifo_full || !rx_byte_valid |-> ##1 !rx_fifo_wen);
   
`endif
endmodule
