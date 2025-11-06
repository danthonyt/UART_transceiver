interface axil_syscon_if #(parameter ADDR_WIDTH=32, DATA_WIDTH=32);

  // Clock and reset
  logic aclk;
  logic aresetn;

  // Read address channel
  logic [ADDR_WIDTH-1:0] araddr_i;
  logic                  arvalid_i;
  logic                  arready_o;

  // Read data channel
  logic [DATA_WIDTH-1:0] rdata_o;
  logic [1:0]            rresp_o;
  logic                  rvalid_o;
  logic                  rready_i;

  // Write address channel
  logic [ADDR_WIDTH-1:0] awaddr_i;
  logic                  awvalid_i;
  logic                  awready_o;

  // Write data channel
  logic [DATA_WIDTH-1:0] wdata_i;
  logic                  wvalid_i;
  logic                  wready_o;

  // Write response channel
  logic                  bvalid_o;
  logic                  bready_i;
  logic [1:0]            bresp_o;

endinterface
