interface ahb_if(input bit clk, input bit rst_n);
  logic [31:0] HADDR;
  logic [31:0] HWDATA;
  logic [31:0] HRDATA;
  logic [1:0]  HTRANS;
  logic HWRITE;
  logic HSEL;
  logic HREADY;
  logic HRESP;
  clocking cb @(posedge clk);
    default input #1step;
    output #1step HADDR, HWDATA, HTRANS, HWRITE;
    input  #1step HRDATA, HREADY, HRESP, HSEL;
  endclocking
endinterface

module ahb_master #(parameter ID=0) (
  input logic clk, rst_n,
  output logic req,
  input  logic grant,
  inout  ahb_if if_bus
);
  typedef enum logic [1:0] {M_IDLE, M_ADDR} mstate_t;
  mstate_t state;
  logic [31:0] req_addr;
  logic [31:0] req_wdata;
  logic        req_write;
  logic [1:0]  req_xfer;
  logic        pending;

  task automatic program_transfer(input logic [31:0] addr, input logic [31:0] wdata, input logic write);
    req_addr  = addr;
    req_wdata = wdata;
    req_write = write;
    req_xfer  = 2'b10;
    pending   = 1'b1;
    req = 1'b1;
    wait (!pending);
  endtask

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= M_IDLE;
      if_bus.HADDR <= '0;
      if_bus.HTRANS <= 2'b00;
      if_bus.HWRITE <= 1'b0;
      if_bus.HWDATA <= '0;
      req <= 1'b0;
      pending <= 1'b0;
    end else begin
      case (state)
        M_IDLE: begin
          if (pending && grant) begin
            if_bus.HADDR <= req_addr;
            if_bus.HTRANS <= req_xfer;
            if_bus.HWRITE <= req_write;
            if_bus.HWDATA <= req_wdata;
            state <= M_ADDR;
          end else begin
            if_bus.HTRANS <= 2'b00;
          end
        end
        M_ADDR: begin
          if (if_bus.HREADY) begin
            if (!req_write) begin
              // HRDATA consumed externally
            end
            if_bus.HTRANS <= 2'b00;
            pending <= 1'b0;
            req <= 1'b0;
            state <= M_IDLE;
          end
        end
      endcase
    end
  end
endmodule

