module baud_rate_gen#(
    parameter int CNT_WIDTH = 8)(
    input logic clk,
    input logic rstn,
    input logic [CNT_WIDTH-1:0] baud_rate,
    output logic tick
);
// we will be oversampling by taking 16x the baud rate
// ratio of oversampled baud rate to clock frequecy gets
// the baud rate input
// for example, for 115200 baud rate and 100 MHz clock
// baud_rate = 100*10^6 / (115200*16) = 54
logic [CNT_WIDTH-1:0] baud_rate_shadow;
logic [CNT_WIDTH-1:0] baud_cnt;
always_ff @(posedge clk) begin
    if (!rstn) begin
        baud_cnt <= 32'd1;
        baud_rate_shadow <= baud_rate;
        tick <= 0;
    end else if (baud_cnt == baud_rate_shadow)begin
        baud_cnt <= 32'd1;
        // only update baud_rate_shadow when we generate a tick to avoid timing issues
        baud_rate_shadow <= baud_rate;
        tick <= 1;
    end else begin
        baud_cnt <= baud_cnt + 1;
        tick <= 0;
    end
end
endmodule