package common_pkg;

typedef bit[31:0] u32;
typedef enum {READ, WRITE} axil_op_e;
  typedef enum logic [1:0] {
    OKAY = 2'b00,
    EXOKAY = 2'b01,
    SLVERR = 2'b10,
    DECERR = 2'b11
  } axil_resp_e;
endpackage : common_pkg
