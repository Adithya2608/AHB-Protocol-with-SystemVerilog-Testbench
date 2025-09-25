module ahb_slave #(
  parameter ID=0,
  parameter BASE=32'h0000_0000,
  parameter SIZE_WORDS=256
)(
  input  logic clk, rst_n,
  input  logic sel,
  input  logic [31:0] HADDR,
  input  logic HWRITE,
  input  logic [31:0] HWDATA,
  input  logic [1:0] HTRANS,
  output logic [31:0] HRDATA,
  output logic HREADY,
  output logic HRESP
);
  logic [31:0] mem [0:SIZE_WORDS-1];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      HRDATA <= '0;
      HREADY <= 1;
      HRESP  <= 0;
    end else begin
      if (sel && (HTRANS == 2'b10 || HTRANS == 2'b11)) begin
        HREADY <= 1;
        HRESP  <= 0;
        if (HWRITE) begin
          mem[(HADDR - BASE) >> 2] <= HWDATA;
        end else begin
          HRDATA <= mem[(HADDR - BASE) >> 2];
        end
      end else begin
        HREADY <= 1;
        HRESP  <= 0;
      end
    end
  end
endmodule
