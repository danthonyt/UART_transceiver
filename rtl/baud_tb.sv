`timescale 1ns/1ps

module baud_tb;
    bit clk;
    bit rst;
    localparam time CLK_PERIOD = 10ns;
    localparam CNT_WIDTH = 32;
    initial begin
        clk = 0;
        forever begin
            #(CLK_PERIOD/2);
            clk = ~clk;
        end
    end

    logic [CNT_WIDTH-1:0] baud_rate;
    logic tick;

    baud_rate_gen #(
        .CNT_WIDTH(CNT_WIDTH)
    ) baud_rate_gen_instance (
        .clk(clk),
        .rst(rst),
        .baud_rate(baud_rate),
        .tick(tick)
    );

    initial begin
        $timeformat(-9, 1, " ns", 10);  // nanoseconds
        $dumpfile("dump.vcd"); // waveform file
        $dumpvars(0, baud_tb);
        // reset
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        // 115200 baud rate 16x oversample
        baud_rate = 54;
        repeat(4) begin
            @(posedge tick);
            $display("time=%0t tick=%0b", $time, tick);
        end
            // 9600 baud rate 16x oversample
        baud_rate = 651;
        repeat(4) begin
            @(posedge tick);
            $display("time=%0t tick=%0b", $time, tick);
        end
        $finish;
    end
endmodule
