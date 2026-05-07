`timescale 1ns / 1ps

module tb_k_counter();
    
    // =========================================================================
    // Parameters
    // =========================================================================
    parameter K = 4;
    parameter CLK_PERIOD = 10;  // 100MHz clock
    
    // =========================================================================
    // Test Signals
    // =========================================================================
    reg clk;
    reg reset;
    reg enable;
    wire carry;
    
    // =========================================================================
    // Module Instance
    // =========================================================================
    k_counter #(.K(K)) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .carry(carry)
    );
    
    // =========================================================================
    // Clock Generation
    // =========================================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // =========================================================================
    // Test Sequence
    // =========================================================================
    initial begin
        // VCD dump configuration
        $dumpfile("tb_k_counter.vcd");
        $dumpvars(0, tb_k_counter);
        
        // Initialize
        reset = 1'b1;
        enable = 1'b0;
        
        $display("=== K-COUNTER TESTBENCH (K=%d) ===", K);
        $display("Expected behavior:");
        $display("  - Counter counts from 0 to 2^K-1");
        $display("  - Carry = MSB (bit K-1) of counter");
        $display("  - For K=4: Carry=0 for count 0-7, Carry=1 for count 8-15");
        $display("");
        
        // TEST 1: Reset Functionality
        $display("TEST 1: Reset Functionality");
        #(CLK_PERIOD * 2);
        reset = 1'b0;
        enable = 1'b0;
        
        #CLK_PERIOD;
        $display("  After reset: carry = %b (expected: 0)", carry);
        if (carry !== 1'b0)
            $display("  FAIL: Carry should be 0 after reset");
        else
            $display("  PASS");
        $display("");
        
        // TEST 2: Counter Increment with Enable
        $display("TEST 2: Counter Increment (Enable=1)");
        enable = 1'b1;
        $display("  Testing 32 cycles of counting...");
        test_carry_values(32);
        $display("");
        
        // TEST 3: Enable Signal (Reset Count when enable=0)
        $display("TEST 3: Enable Signal Behavior");
        enable = 1'b0;
        #(CLK_PERIOD * 1);
        $display("  Set enable=0, count should reset to 0");
        #CLK_PERIOD;
        $display("  After next clock: carry = %b (expected: 0)", carry);
        if (carry !== 1'b0)
            $display("  FAIL: Carry should be 0 when enable=0");
        else
            $display("  PASS");
        $display("");
        
        // TEST 4: Reset During Operation
        $display("TEST 4: Reset During Operation");
        test_reset_during_op();
        $display("");
        
        // TEST 5: Stress Test - 100 Cycles
        $display("TEST 5: Stress Test (100 cycles)");
        reset = 1'b0;
        enable = 1'b1;
        test_stress_100();
        $display("");
        
        // Summary
        $display("=== TEST COMPLETE ===");
        #(CLK_PERIOD * 5);
        $finish;
    end
    
    // =========================================================================
    // Task: Test Carry Values
    // =========================================================================
    task test_carry_values;
        input integer num_cycles;
        integer i;
        integer count_mod;
        reg expected_carry;
        
        begin
            for (i = 0; i < num_cycles; i = i + 1) begin
                #CLK_PERIOD;
                
                count_mod = i % (1 << K);
                
                if (count_mod >= (1 << (K-1)))
                    expected_carry = 1'b1;
                else
                    expected_carry = 1'b0;
                
                if (i % 4 == 0) begin
                    if (carry === expected_carry)
                        $display("  Cycle %3d: carry=%b (expected %b) - PASS", i, carry, expected_carry);
                    else
                        $display("  Cycle %3d: carry=%b (expected %b) - FAIL", i, carry, expected_carry);
                end
            end
        end
    endtask
    
    // =========================================================================
    // Task: Test Reset During Operation
    // =========================================================================
    task test_reset_during_op;
        integer i;
        
        begin
            enable = 1'b1;
            for (i = 0; i < 10; i = i + 1) begin
                #CLK_PERIOD;
            end
            
            $display("  After 10 cycles with enable=1, apply reset");
            reset = 1'b1;
            #CLK_PERIOD;
            $display("  carry = %b (expected: 0)", carry);
            if (carry !== 1'b0)
                $display("  FAIL: Carry should be 0 after reset");
            else
                $display("  PASS");
            
            reset = 1'b0;
        end
    endtask
    
    // =========================================================================
    // Task: Stress Test 100 Cycles
    // =========================================================================
    task test_stress_100;
        integer i;
        integer count_now;
        reg expected;
        integer error_count;
        
        begin
            error_count = 0;
            
            for (i = 0; i < 100; i = i + 1) begin
                #CLK_PERIOD;
                
                count_now = i % (1 << K);
                
                if (count_now >= (1 << (K-1)))
                    expected = 1'b1;
                else
                    expected = 1'b0;
                
                if (carry !== expected) begin
                    $display("  ERROR at cycle %d: carry=%b, expected %b", i, carry, expected);
                    error_count = error_count + 1;
                end
            end
            
            if (error_count == 0)
                $display("  PASS - 100 cycles correct");
            else
                $display("  FAIL - %d errors", error_count);
        end
    endtask

endmodule
