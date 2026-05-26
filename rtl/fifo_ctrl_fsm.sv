module fifo_ctrl_fsm #(
    DATA_WIDTH = 8
)(
    input logic clk,
    input logic rstn,

    // tx fifo control
    output logic        tx_fifo_ren  ,
    input  logic        tx_fifo_empty,
    input  logic        tx_fifo_rst  ,

    // rx fifo control
    output logic        rx_fifo_wen  ,
    input  logic        rx_fifo_full ,
    input  logic        rx_fifo_rst  ,
    output logic [DATA_WIDTH-1:0]  rx_fifo_wdata,

    
    // uart control
    input  logic        tx_busy       ,
    input  logic        rx_byte_valid ,
    input  logic [DATA_WIDTH-1:0]  rx_byte       ,
    output logic        tx_start
    

);

/******************************************/
  //
  //    TX and RX fifo glue logic
  //
  /******************************************/
  // uart tx start and fifo read control
  // uart rx write control
  always_ff @(posedge clk) begin
    if (~rstn) begin
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

  always_ff @(posedge clk) begin
    if (~rstn) begin
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