`timescale 1ns/1ps

module tb_i2c_top_module;

    reg clk;
    reg rst_n;

    i2c_top_module dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;  // 50 MHz
    end

    initial begin
        rst_n = 1'b0;
        #100;
        rst_n = 1'b1;

        #50000;
        $finish;
    end

    initial begin
     	$dumpfile("i2c_top_module.vcd");
      $dumpvars(0, tb_i2c_top_module);
    end
endmodule
