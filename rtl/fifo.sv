module fifo #(
    parameter DEPTH = 16,
    DWIDTH = 8
) (
    input  logic              rst_i,    // active high reset
    input  logic              clk_i,    // clk
    input  logic              wen_i,    // write enable
    input  logic              ren_i,    // read enable
    input  logic [DWIDTH-1:0] wdata_i,   // Data written into FIFO
    output logic [DWIDTH-1:0] rdata_o,   // Data read from FIFO
    output logic              empty_o,  // FIFO is empty when high
    output logic              full_o    // FIFO is full when high
);


  logic [$clog2(DEPTH)-1:0]   wptr;
  logic [$clog2(DEPTH)-1:0]   rptr;

  logic [DWIDTH-1 : 0]    fifo[DEPTH];

  always @(posedge clk_i) begin
    if (rst_i) begin
      wptr <= 0;
    end else begin
      if (wen_i & !full_o) begin
        fifo[wptr] <= wdata_i;
        wptr <= (wptr + 1) % DEPTH;
      end
    end
  end

  always @(posedge clk_i) begin
    if (rst_i) begin
      rptr <= 0;
      rdata_o <= 0;
    end else begin
      if (ren_i & !empty_o) begin
        rdata_o <= fifo[rptr];
        rptr   <= (rptr + 1) % DEPTH;
      end
    end
  end

  assign full_o  = ((wptr + 1) % DEPTH) == rptr;
  assign empty_o = wptr == rptr;
endmodule
