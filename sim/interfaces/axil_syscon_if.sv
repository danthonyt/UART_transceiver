interface axil_syscon_if (input aclk, input aresetn);

  // Read address channel
  logic [31:0] araddr_i;
  logic                  arvalid_i;
  logic                  arready_o;

  // Read data channel
  logic [31:0] rdata_o;
  logic [1:0]            rresp_o;
  logic                  rvalid_o;
  logic                  rready_i;

  // Write address channel
  logic [31:0] awaddr_i;
  logic                  awvalid_i;
  logic                  awready_o;

  // Write data channel
  logic [31:0] wdata_i;
  logic                  wvalid_i;
  logic                  wready_o;

  // Write response channel
  logic                  bvalid_o;
  logic                  bready_i;
  logic [1:0]            bresp_o;

endinterface : axil_syscon_if
