module baud_rate_gen#(
    parameter int CNT_WIDTH = 8)(
    input logic clk,
    input logic rst,
    input logic [CNT_WIDTH-1:0] baud_rate,
    output logic tick
);
// we will be oversampling by taking 16x the baud rate
// ratio of oversampled baud rate to clock frequecy gets
// the baud rate input
// for example, for 115200 baud rate and 100 MHz clock
// baud_rate = 100*10^6 / (115200*16) = 54
logic [CNT_WIDTH-1:0] baud_cnt;
always_ff @(posedge clk) begin
    if (rst) begin
        baud_cnt <= 32'd1;
        tick <= 0;
    end else if (baud_cnt == baud_rate)begin
        baud_cnt <= 32'd1;
        tick <= 1;
    end else begin
        baud_cnt <= baud_cnt + 1;
        tick <= 0;
    end
end
endmodule