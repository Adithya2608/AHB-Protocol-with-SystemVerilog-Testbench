`timescale 1ns/1ps
module tb_ahb();
  logic clk;
  logic rst_n;

  ahb_if bus_if(clk, rst_n);
  ahb_master m0(.clk(clk), .rst_n(rst_n), .req(), .grant(1'b1), .if_bus(bus_if));
  ahb_slave  s0(.clk(clk), .rst_n(rst_n), .sel(1'b1), .HADDR(bus_if.HADDR), .HWRITE(bus_if.HWRITE), .HWDATA(bus_if.HWDATA), .HTRANS(bus_if.HTRANS), .HRDATA(bus_if.HRDATA), .HREADY(bus_if.HREADY), .HRESP(bus_if.HRESP));

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    rst_n = 0;
    #20 rst_n = 1;
  end

  class ahb_txn;
    rand bit [31:0] addr;
    rand bit [31:0] wdata;
    rand bit        write;
    function string convert2string();
      return $sformatf("addr=0x%08h wdata=0x%08h write=%0d", addr, wdata, write);
    endfunction
  endclass

  covergroup cg_trans @(posedge clk);
    coverpoint bus_if.HADDR;
    coverpoint bus_if.HWRITE;
    coverpoint bus_if.HTRANS;
  endgroup
  cg_trans cg = new();

  initial begin
    wait (rst_n == 1);
    m0.program_transfer(32'h0000_0000, 32'h1234_5678, 1);
    #50;
    m0.program_transfer(32'h0000_0000, 32'h0, 0);
    repeat (10) begin
      ahb_txn t = new();
      assert(t.randomize() with { addr inside {[32'h0000_0000:32'h0000_00FF]}; });
      m0.program_transfer(t.addr, t.wdata, t.write);
      #20;
    end
    #200;
    $display("Testbench Finished");
    $finish;
  end
endmodule