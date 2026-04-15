`timescale 1ns / 1ps

module tb_divide_by_2;
    reg clk;
    reg reset;
    wire out;
    
    divide_by_2 dut (
        .clk(clk),
        .reset(reset),
        .out(out)
    );
    
    // ===== CLOCK GENERATOR =====
    initial begin
        clk = 0;          // Khởi tạo clock = 0
        forever #5 clk = ~clk;   // Toggle mỗi 5ns → chu kỳ 10ns (100MHz)
    end
    
    // ===== TEST SEQUENCE =====
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_divide_by_2);
        
        reset = 1;
        #10 reset = 0;   // Release after 1 clock cycle
        #120;            // Run for 12 more clock cycles
        $finish;
    end
    
    // ===== MONITOR OUTPUT =====
    always @(posedge clk) begin
        $display("Time=%0t: clk rise, out=%b, reset=%b", $time, out, reset);
    end
endmodule