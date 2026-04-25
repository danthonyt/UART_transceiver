interface fifo_syscon_if #(parameter int DATA_WIDTH = 8)
  (input logic clk);

  logic wen;
  logic ren;
  logic [DATA_WIDTH-1:0] wdata;
  logic [DATA_WIDTH-1:0] rdata;
  logic empty;
  logic full;
  logic rst;

endinterface
