package dut_params_pkg;

    localparam int DATA_WIDTH = 8;
    localparam int FIFO_DEPTH = 16;

    parameter int CLK_FREQ = 100_000_000;
    parameter time CLK_PERIOD = 1s / CLK_FREQ;
    parameter int BAUD_RATE = 115200;

    parameter int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

endpackage : dut_params_pkg
