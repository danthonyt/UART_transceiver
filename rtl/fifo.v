module fifo #(parameter DEPTH  = 16, DWIDTH = 8) (
  input                   rst_i  , // active high reset
  input                   clk_i  , // clk
  input                   wen_i  , // write enable
  input                   ren_i  , // read enable
  input      [DWIDTH-1:0] wdata_i, // Data written into FIFO
  output reg [DWIDTH-1:0] rdata_o, // Data read from FIFO
  output                  empty_o, // FIFO is empty when high
  output                  full_o   // FIFO is full when high
);


  reg [$clog2(DEPTH)-1:0] wptr;
  reg [$clog2(DEPTH)-1:0] rptr;

  reg [DWIDTH-1:0] fifo[0:DEPTH-1];

  always @(posedge clk_i) begin
    if (rst_i) begin
      wptr <= 0;
    end else begin
      if (wen_i & !full_o) begin
        fifo[wptr] <= wdata_i;
        wptr       <= (wptr + 1) % DEPTH;
      end
    end
  end

  always @(posedge clk_i) begin
    if (rst_i) begin
      rptr    <= 0;
      rdata_o <= 0;
    end else begin
      if (ren_i & !empty_o) begin
        rdata_o <= fifo[rptr];
        rptr    <= (rptr + 1) % DEPTH;
      end
    end
  end

  assign full_o  = ((wptr + 1) % DEPTH) == rptr;
  assign empty_o = wptr == rptr;

  /******************************************/
  //
  //    FORMAL VERIFICATION
  //
  /******************************************/
`ifdef FORMAL
  initial assume (rst_i);
  assert property(
    @(posedge clk_i)
    rst_i |-> ##1 wptr == 0 && rptr == 0 && rdata_o == 0
    );
`endif
endmodule
