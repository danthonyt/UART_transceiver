module fifo #(
    parameter DEPTH = 16,
    DWIDTH = 8
) (
    input  logic              RST_I,    // active high reset
    input  logic              CLK_I,    // clk
    input  logic              WEN_I,    // write enable
    input  logic              REN_I,    // read enable
    input  logic [DWIDTH-1:0] DATA_I,   // Data written into FIFO
    output logic [DWIDTH-1:0] DATA_O,   // Data read from FIFO
    output logic              EMPTY_O,  // FIFO is empty when high
    output logic              FULL_O    // FIFO is full when high
);


  logic [$clog2(DEPTH)-1:0]   wptr;
  logic [$clog2(DEPTH)-1:0]   rptr;

  logic [DWIDTH-1 : 0]    fifo[DEPTH];

  always @(posedge CLK_I) begin
    if (RST_I) begin
      wptr <= 0;
    end else begin
      if (WEN_I & !FULL_O) begin
        fifo[wptr] <= DATA_I;
        wptr <= wptr + 1;
      end
    end
  end

  always @(posedge CLK_I) begin
    if (RST_I) begin
      rptr <= 0;
    end else begin
      if (REN_I & !EMPTY_O) begin
        DATA_O <= fifo[rptr];
        rptr   <= rptr + 1;
      end
    end
  end

  assign FULL_O  = (wptr + 1) == rptr;
  assign EMPTY_O = wptr == rptr;
endmodule
