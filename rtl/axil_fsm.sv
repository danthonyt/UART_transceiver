module axil_fsm #(
    DATA_WIDTH = 8
)(
    // global signals
    input logic         axi_aclk_i   ,
    input logic         axi_aresetn_i,

    // read address channel
    input logic  [31:0] axi_araddr_i ,
    input logic         axi_arvalid_i,
    output logic        axi_arready_o,

    // read data channel
    output logic [31:0] axi_rdata_o  ,
    output logic [ 1:0] axi_rresp_o  ,
    output logic        axi_rvalid_o ,
    input logic         axi_rready_i ,

    // write address channel
    input logic         axi_awvalid_i,
    output logic        axi_awready_o,
    input logic  [31:0] axi_awaddr_i ,

    // write data channel
    input logic         axi_wvalid_i ,
    output logic        axi_wready_o ,
    input logic  [31:0] axi_wdata_i  ,

    // write response channel
    output logic        axi_bvalid_o ,
    input logic         axi_bready_i ,
    output logic [ 1:0] axi_bresp_o,

    // fifo status
    input logic tx_fifo_empty,
    input logic tx_fifo_full ,
    input logic rx_fifo_empty,
    input logic rx_fifo_full ,

    // fifo reset control
    output logic tx_fifo_rst  ,
    output logic rx_fifo_rst  ,

    // tx fifo write control
    output logic        tx_fifo_wen  ,
    output logic [DATA_WIDTH-1:0]  tx_fifo_wdata ,

    // rx fifo read control
    output logic        rx_fifo_ren , 

    // fifo read data
    input logic [DATA_WIDTH-1:0]  rx_fifo_rdata

);

    typedef enum logic [1:0] {
        RESP_OKAY = 2'b00,
        RESP_ERR  = 2'b10
    } axil_resp_e;

    typedef enum logic [2:0] {
        AR_READ = 3'b000,
        R_READ1 = 3'b001,
        R_READ2 = 3'b010,
        R_READ3 = 3'b011,
        R_READ4 = 3'b100
    } r_state_e;
    // read fsm states

    typedef enum logic [1:0] {
        AW_WAIT = 2'b00,
        W_WAIT = 2'b01,
        B_WRITE = 2'b10,
        B_WAIT = 2'b11
    } w_state_e;

    // fsm state registers
    w_state_e write_state;
    r_state_e read_state ;

    // transaction signals sampled
    // from axi lite bus
    // Read
    logic [31:0] raddr_q;

    // Write
    logic  [31:0] wraddr_q    ;
    logic  [31:0] wdata_q     ;
    logic        ar_handshake;
    logic        r_handshake ;
    logic        aw_handshake;
    logic        w_handshake ;
    logic        b_handshake ;

    /******************************************/
    //
    //  Uart core registers
    //
    /******************************************/
    logic  [31:0] reg_wdata  ;
    logic         reg_wen    ;
    logic  [31:0] status_reg ; // read only
    logic  [31:0] control_reg; // write/read
    logic        rx_fifo_rd ;
    logic        tx_fifo_wr ;
    logic        reg_rd     ;
    logic        reg_wr     ;

    // adresses:
    // 32'h0 = status register
    // 32'h4 = control register
    // 32'h8 = rx fifo
    // 32'hc = tx fifo

    /******************************************/
    //
    //  AXI LITE SIGNALS
    //
    /******************************************/


    // register write
    always_ff @(posedge axi_aclk_i) begin
        if (~axi_aresetn_i) begin
            control_reg <= 0;
        end else begin
            // lower reset after one cycle
            control_reg <= control_reg & ~32'h3;
            if (reg_wen) begin
                case (wraddr_q[3:0])
                    4'h4 : begin
                        control_reg <= reg_wdata;
                    end
                    default : ;
                endcase
            end
        end
    end

    assign status_reg = {28'd0, tx_fifo_empty, tx_fifo_full, rx_fifo_empty, rx_fifo_full};
    assign rx_fifo_rd = (raddr_q[3:0] == 4'h8);
    assign tx_fifo_wr = (wraddr_q[3:0] == 4'hc);
    assign reg_rd     = ((raddr_q[3:0] == 4'h0) || (raddr_q[3:0] == 4'h4));
    assign reg_wr     = (wraddr_q[3:0] == 4'h4);

    assign rx_fifo_rst = control_reg[0];
    assign tx_fifo_rst = control_reg[1];

    assign ar_handshake = axi_arvalid_i & axi_arready_o;
    assign r_handshake  = axi_rvalid_o & axi_rready_i;
    assign aw_handshake = axi_awvalid_i & axi_awready_o;
    assign w_handshake  = axi_wvalid_i & axi_wready_o;
    assign b_handshake  = axi_bvalid_o & axi_bready_i;


    //*********************************
    //
    // READ FSM
    //
    //*********************************

    always_ff @(posedge axi_aclk_i) begin
        if (!axi_aresetn_i) begin
            read_state  <= AR_READ;
            axi_arready_o <= 0;
            axi_rvalid_o  <= 0;
            axi_rresp_o   <= RESP_ERR;
            axi_rdata_o   <= 0;
            //
            rx_fifo_ren <= 0;
        end
        else begin
            case (read_state)
                AR_READ : begin
                    axi_arready_o <= 1;
                    axi_rvalid_o  <= 0;
                    if (ar_handshake) begin
                        raddr_q     <= axi_araddr_i;
                        // on axi read address handshake, register
                        // the read data of the specified address
                        axi_arready_o <= 0;
                        //
                        read_state  <= R_READ1;
                    end
                end
                R_READ1 : begin
                    axi_arready_o <= 0;
                    axi_rvalid_o  <= 0;
                    // 1 cycle if a register read
                    // 3 cycles if a fifo read
                    if (reg_rd) begin
                        case (raddr_q[3:0])
                            4'h0    : axi_rdata_o <= status_reg;
                            4'h4    : axi_rdata_o <= control_reg;
                            default : axi_rdata_o <= 0;
                        endcase
                        axi_rresp_o  <= RESP_OKAY;
                        read_state <= R_READ4;
                    end else if (rx_fifo_rd) begin
                        if (!rx_fifo_empty) begin
                            // wait one cycle to read fifo
                            rx_fifo_ren <= 1;
                            axi_rresp_o   <= RESP_OKAY;
                            read_state  <= R_READ2;
                        end else begin
                            // send an error; the fifo is empty
                            axi_rdata_o  <= 0;
                            axi_rresp_o  <= RESP_ERR;
                            read_state <= R_READ4;
                        end
                    end
                end
                R_READ2 : begin
                    axi_arready_o <= 0;
                    axi_rvalid_o  <= 0;
                    // disable fifo read enable
                    rx_fifo_ren <= 0;
                    //
                    read_state  <= R_READ3;

                end
                R_READ3 : begin
                    axi_arready_o <= 0;
                    axi_rvalid_o  <= 0;
                    // sample fifo read data and move on to wait for handshake
                    axi_rdata_o   <= rx_fifo_rdata;
                    //
                    read_state  <= R_READ4;

                end
                R_READ4 : begin
                    axi_arready_o <= 0;
                    axi_rvalid_o  <= 1;
                    // place read data and response on the axi line
                    // wait for handshake
                    if (r_handshake) begin
                        // on axi read response handshake, place the
                        // read response on the specified axi signal
                        axi_arready_o <= 1;
                        axi_rvalid_o  <= 0;
                        //
                        read_state  <= AR_READ;
                    end
                end
                default : read_state <= AR_READ;
            endcase
        end
    end

    //*********************************
    //
    // WRITE FSM
    //
    //*********************************


    // next write state fsm register
    always_ff @(posedge axi_aclk_i) begin
        if (!axi_aresetn_i) begin
            axi_awready_o   <= 0;
            axi_wready_o    <= 0;
            axi_bvalid_o    <= 0;
            axi_bresp_o     <= RESP_ERR;
            wraddr_q      <= 0;
            wdata_q       <= 0;
            tx_fifo_wen   <= 0;
            tx_fifo_wdata <= 0;
            reg_wen       <= 0;
            reg_wdata     <= 0;
            write_state   <= AW_WAIT;
        end
        else begin
            case (write_state)
                AW_WAIT: begin
                    // wait for address write handshake
                    axi_awready_o <= 1;
                    axi_wready_o  <= 0;
                    axi_bvalid_o  <= 0;
                    if (aw_handshake) begin
                        wraddr_q    <= axi_awaddr_i;
                        write_state <= W_WAIT;
                    end
                end
                W_WAIT : begin
                    // wait for write handshake
                    axi_awready_o <= 0;
                    axi_wready_o  <= 1;
                    axi_bvalid_o  <= 0;
                    if (w_handshake) begin
                        wdata_q     <= axi_wdata_i;
                        write_state <= B_WRITE;
                    end
                end
                B_WRITE : begin
                    // write to appropriate register or fifo
                    if (tx_fifo_wr) begin
                        if (!tx_fifo_full) begin
                            tx_fifo_wen   <= 1;
                            tx_fifo_wdata <= wdata_q;
                            axi_bresp_o     <= RESP_OKAY;
                            write_state   <= B_WAIT;
                        end else begin
                            axi_bresp_o   <= RESP_ERR;
                            write_state <= B_WAIT;
                        end
                    end  else if (reg_wr) begin
                        reg_wen     <= 1;
                        reg_wdata   <= wdata_q;
                        axi_bresp_o   <= RESP_OKAY;
                        write_state <= B_WAIT;
                    end
                end
                B_WAIT : begin
                    axi_awready_o <= 0;
                    axi_wready_o  <= 0;
                    axi_bvalid_o  <= 1;
                    // lower write enables
                    tx_fifo_wen <= 0;
                    reg_wen     <= 0;
                    if (b_handshake) begin
                        axi_awready_o <= 1;
                        axi_wready_o  <= 0;
                        axi_bvalid_o  <= 0;
                        write_state <= AW_WAIT;
                    end
                end
                default : write_state <= AW_WAIT;
            endcase
        end
    end


endmodule