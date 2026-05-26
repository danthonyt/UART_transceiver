module fifo #(parameter DEPTH  = 16, DWIDTH = 8) (
  input logic                   rstn  , // active low reset
  input logic                   clk  , // clk
  input logic                   wen_i  , // write enable
  input logic                   ren_i  , // read enable
  input logic      [DWIDTH-1:0] wdata_i, // Data written into FIFO
  output logic [DWIDTH-1:0] rdata_o, // Data read from FIFO
  output logic                  empty_o, // FIFO is empty when high
  output logic                  full_o // FIFO is full when high
);
  localparam AWIDTH = $clog2(DEPTH);

  logic [AWIDTH:0] wptr;
  logic [AWIDTH:0] rptr;

  logic [DWIDTH-1:0] fifo[0:DEPTH-1];

  always_ff @(posedge clk) begin
    if (!rstn) begin
      wptr <= 0;
    end else begin
      if (wen_i & !full_o) begin
        fifo[wptr[AWIDTH-1:0]] <= wdata_i;
        wptr       <= (wptr + 1);
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rstn) begin
      rptr    <= 0;
      rdata_o <= 0;
    end else begin
      if (ren_i & !empty_o) begin
        rdata_o <= fifo[rptr[AWIDTH-1:0]];
        rptr    <= (rptr + 1);
      end
    end
  end

  assign full_o = (wptr[AWIDTH-1:0] == rptr[AWIDTH-1:0]) &&
  (wptr[AWIDTH]     != rptr[AWIDTH]);
  assign empty_o = wptr == rptr;
endmodule
