module uart_axi_lite_wrapper #(
    parameter DATA_WIDTH   = 8,
    parameter FIFO_DEPTH   = 16,
    parameter CLKS_PER_BIT = 4
)(
    input  wire             clk_i,
    input  wire             rst_i,
    // AXI-Lite write address channel
    input  wire [3:0]       s_axi_awaddr_i,
    input  wire             s_axi_awvalid_i,
    output reg              s_axi_awready_o,
    // AXI-Lite write data channel
    input  wire [31:0]      s_axi_wdata_i,
    input  wire [3:0]       s_axi_wstrb_i,
    input  wire             s_axi_wvalid_i,
    output reg              s_axi_wready_o,
    // AXI-Lite write response channel
    output reg [1:0]        s_axi_bresp_o,
    output reg              s_axi_bvalid_o,
    input  wire             s_axi_bready_i,
    // AXI-Lite read address channel
    input  wire [3:0]       s_axi_araddr_i,
    input  wire             s_axi_arvalid_i,
    output reg              s_axi_arready_o,
    // AXI-Lite read data channel
    output reg [31:0]       s_axi_rdata_o,
    output reg [1:0]        s_axi_rresp_o,
    output reg              s_axi_rvalid_o,
    input  wire             s_axi_rready_i,
    // UART signals
    input  wire             rx_i,
    output wire             tx_o
);

    // Internal bus signals for uart_core
    reg             cs_i_int;
    reg             we_i_int;
    reg  [3:0]      addr_i_int;
    reg  [31:0]     wdata_i_int;
    wire [31:0]     rdata_o_int;
    wire            done_o_int;
    wire            err_o_int;

    // Instantiate UART core
    uart_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .cs_i(cs_i_int),
        .we_i(we_i_int),
        .addr_i(addr_i_int),
        .wdata_i(wdata_i_int),
        .rdata_o(rdata_o_int),
        .done_o(done_o_int),
        .err_o(err_o_int),
        .rx_i(rx_i),
        .tx_o(tx_o)
    );

    // AXI-Lite write FSM (simplified)
    always @(posedge clk_i) begin
        if (~rst_i) begin
            s_axi_awready_o <= 0;
            s_axi_wready_o  <= 0;
            s_axi_bvalid_o  <= 0;
            s_axi_bresp_o   <= 2'b00;
            cs_i_int        <= 0;
            we_i_int        <= 0;
        end else begin
            s_axi_awready_o <= ~s_axi_awready_o & s_axi_awvalid_i;
            s_axi_wready_o  <= ~s_axi_wready_o & s_axi_wvalid_i;

            cs_i_int        <= s_axi_awvalid_i & s_axi_wvalid_i;
            we_i_int        <= s_axi_awvalid_i & s_axi_wvalid_i;
            addr_i_int      <= s_axi_awaddr_i;
            wdata_i_int     <= s_axi_wdata_i;

            if (cs_i_int & we_i_int) begin
                s_axi_bvalid_o <= 1;
                s_axi_bresp_o  <= err_o_int ? 2'b10 : 2'b00;
            end else if (s_axi_bvalid_o & s_axi_bready_i) begin
                s_axi_bvalid_o <= 0;
            end
        end
    end

    // AXI-Lite read FSM (simplified)
    always @(posedge clk_i) begin
        if (~rst_i) begin
            s_axi_arready_o <= 0;
            s_axi_rvalid_o  <= 0;
            s_axi_rresp_o   <= 2'b00;
            cs_i_int        <= 0;
            we_i_int        <= 0;
            addr_i_int      <= 0;
        end else begin
            s_axi_arready_o <= ~s_axi_arready_o & s_axi_arvalid_i;

            cs_i_int        <= s_axi_arvalid_i;
            we_i_int        <= 0;
            addr_i_int      <= s_axi_araddr_i;

            if (cs_i_int & ~we_i_int) begin
                s_axi_rvalid_o <= 1;
                s_axi_rdata_o  <= rdata_o_int;
                s_axi_rresp_o  <= err_o_int ? 2'b10 : 2'b00;
            end else if (s_axi_rvalid_o & s_axi_rready_i) begin
                s_axi_rvalid_o <= 0;
            end
        end
    end

endmodule
