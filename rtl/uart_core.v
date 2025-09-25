`timescale 1ns / 1ps
module uart_core #(parameter DATA_WIDTH = 8, FIFO_DEPTH = 16, CLKS_PER_BIT = 4) (
  input             clk_i  ,
  input             rst_i  ,
  // bus signals
  input             cs_i   ,
  input             we_i   ,
  input      [ 3:0] addr_i ,
  input      [31:0] wdata_i,
  output reg [31:0] rdata_o,
  output reg        done_o ,
  output reg        err_o  ,
  // uart rx and tx
  input             rx_i   ,
  output            tx_o
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


  uart_regfile uart_regfile_inst (
    .clk_i          (clk_i        ),
    .rst_i          (rst_i        ),
    .cs_i           (cs_i         ),
    .we_i           (we_i         ),
    .addr_i         (addr_i[3:0]  ),
    .wdata_i        (wdata_i      ),
    .rdata_o        (rdata_o      ),
    .done_o         (done_o       ),
    .err_o          (err_o        ),
    .tx_fifo_full_i (tx_fifo_full ),
    .tx_fifo_empty_i(tx_fifo_empty),
    .tx_fifo_wen_o  (tx_fifo_wen  ),
    .tx_fifo_wdata_o(tx_fifo_wdata),
    .rx_fifo_rdata_i(rx_fifo_rdata),
    .rx_fifo_full_i (rx_fifo_full ),
    .rx_fifo_empty_i(rx_fifo_empty),
    .rx_fifo_ren_o  (rx_fifo_ren  ),
    .rx_fifo_rst_o  (rx_fifo_rst  ),
    .tx_fifo_rst_o  (tx_fifo_rst  )
  );

  uart_rx #(
    .DATA_WIDTH  (DATA_WIDTH  ),
    .CLKS_PER_BIT(CLKS_PER_BIT)
  ) uart_rx_inst (
    .clk_i          (clk_i        ),
    .rst_i          (rst_i        ),
    .rx_i           (rx_i         ),
    .busy_o         (rx_busy      ),
    .rx_byte_o      (rx_byte      ),
    .rx_byte_valid_o(rx_byte_valid),
    .frame_err_o    (rx_frame_err )
  );

  uart_tx #(
    .DATA_WIDTH  (DATA_WIDTH  ),
    .CLKS_PER_BIT(CLKS_PER_BIT)
  ) uart_tx_inst (
    .clk_i    (clk_i        ),
    .rst_i    (rst_i        ),
    .start_i  (tx_start     ),
    .tx_byte_i(tx_fifo_rdata),
    .tx_o     (tx           ),
    .busy_o   (tx_busy      )
  );

  fifo #(
    .DEPTH (FIFO_DEPTH),
    .DWIDTH(DATA_WIDTH)
  ) tx_fifo_inst (
    .rst_i  (rst_i || tx_fifo_rst),
    .clk_i  (clk_i               ),
    .wen_i  (tx_fifo_wen         ),
    .ren_i  (tx_fifo_ren         ),
    .wdata_i(tx_fifo_wdata       ),
    .rdata_o(tx_fifo_rdata       ),
    .empty_o(tx_fifo_empty       ),
    .full_o (tx_fifo_full        )
  );

  fifo #(
    .DEPTH (FIFO_DEPTH),
    .DWIDTH(DATA_WIDTH)
  ) rx_fifo_inst (
    .rst_i  (rst_i || rx_fifo_rst),
    .clk_i  (clk_i               ),
    .wen_i  (rx_fifo_wen         ),
    .ren_i  (rx_fifo_ren         ),
    .wdata_i(rx_fifo_wdata       ),
    .rdata_o(rx_fifo_rdata       ),
    .empty_o(rx_fifo_empty       ),
    .full_o (rx_fifo_full        )
  );

  // uart tx start and fifo read control
  // uart rx write control
  always @(posedge clk_i) begin
    if (rst_i) begin
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

  always @(posedge clk_i) begin
    if (rst_i) begin
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
  default clocking @(posedge clk_i);
  endclocking
    assert property (rst_i |-> ##1 !tx_fifo_ren && !rx_fifo_wen);
  // tx fifo read enable should never go high if the tx fifo is in reset,
  // it is empty, or the tx is busy
  tx_fifo_read_low :
    assert property (disable iff (rst_i) tx_fifo_rst || tx_fifo_empty || tx_busy |-> ##1 !tx_fifo_ren);

  // rx fifo write enable should never go high if the rx fifo is in reset,
  // the rx fifo is full, or the rx byte is invalid
  rx_fifo_write_low :
    assert property (disable iff (rst_i) rx_fifo_rst || rx_fifo_full || !rx_byte_valid |-> ##1 !rx_fifo_wen);

`endif
endmodule
