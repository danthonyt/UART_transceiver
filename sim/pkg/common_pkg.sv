package common_pkg;

  typedef bit[31:0] u32;
  typedef enum {READ, WRITE} axil_op_e;
  typedef enum logic [1:0] {
    OKAY = 2'b00,
    EXOKAY = 2'b01,
    SLVERR = 2'b10,
    DECERR = 2'b11
  } axil_resp_e;
  typedef struct {
    u32 addr;
    u32 data;
    axil_resp_e resp;
  } axil_req_s;

  typedef enum logic [1:0] {
    FIFO_READ = 2'b00,
    FIFO_WRITE = 2'b01,
    FIFO_RESET = 2'b10
  } fifo_ctrl_e;
endpackage : common_pkg
