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

    logic nxt_tx_start;
    logic nxt_tx_fifo_ren;
    logic [DATA_WIDTH-1:0]  nxt_rx_fifo_wdata;
    logic nxt_rx_fifo_wen;

    // only start transmit if tx fifo is not empty and not in reset and not already transmitting
    assign nxt_tx_start       = (!tx_fifo_rst && tx_fifo_ren && !tx_busy) ? 1 : 0;

    // only read from tx fifo if it is not empty, not in reset, and not already transmitting
    assign nxt_tx_fifo_ren    = (!tx_fifo_empty && !tx_fifo_rst && !tx_busy && !tx_fifo_ren) ? 1 : 0;

    assign nxt_rx_fifo_wdata  = rx_byte;

    // only write to rx fifo if byte is valid, fifo is not full, and fifo is not in reset
    assign nxt_rx_fifo_wen    = (rx_byte_valid && !rx_fifo_full && !rx_fifo_rst) ? 1 : 0;

    // uart tx start and fifo read control
    // uart rx write control
    always_ff @(posedge clk) begin
        if (~rstn) begin
            tx_start    <= 0;
            tx_fifo_ren <= 0;
        end else begin
            tx_fifo_ren <= nxt_tx_fifo_ren;
            tx_start    <= nxt_tx_start;
        end
    end

    always_ff @(posedge clk) begin
        if (~rstn) begin
            rx_fifo_wdata <= 0;
            rx_fifo_wen   <= 0;
        end else begin
            rx_fifo_wdata <= nxt_rx_fifo_wdata;
            rx_fifo_wen   <= nxt_rx_fifo_wen;
        end
    end

endmodule