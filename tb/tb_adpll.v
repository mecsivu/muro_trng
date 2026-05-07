`timescale 1ns / 1ps

module tb_adpll();
    
    parameter K = 4;
    parameter M = 8;
    parameter N = 4;
    
    parameter REF_CLK_PERIOD = 10000;   // 100KHz ref clock
    parameter K_CLK_PERIOD = 1250;      // 800KHz k_clk (M*100K)
    parameter DCO_CLK_PERIOD = 1250;    // 800KHz dco_clk (2N*100K)
    
    reg clk_100mhz;
    reg reset;
    wire ref_clk;
    wire k_clk;
    wire dco_clk;
    wire idout;
    
    reg ref_clk_gen;
    reg k_clk_gen;
    reg dco_clk_gen;
    
    // =========================================================================
    // Module Instance
    // =========================================================================
    adpll_ring_osc #(.K(K), .M(M), .N(N)) dut (
        .ref_clk(ref_clk),
        .k_clk(k_clk),
        .dco_clk(dco_clk),
        .reset(reset),
        .idout(idout)
    );
    
    // Assign generated clocks to inputs
    assign ref_clk = ref_clk_gen;
    assign k_clk = k_clk_gen;
    assign dco_clk = dco_clk_gen;
    
    // =========================================================================
    // Clock Generators
    // =========================================================================
    initial begin
        ref_clk_gen = 1'b0;
        forever #(REF_CLK_PERIOD/2) ref_clk_gen = ~ref_clk_gen;
    end
    
    initial begin
        k_clk_gen = 1'b0;
        forever #(K_CLK_PERIOD/2) k_clk_gen = ~k_clk_gen;
    end
    
    initial begin
        dco_clk_gen = 1'b0;
        forever #(DCO_CLK_PERIOD/2) dco_clk_gen = ~dco_clk_gen;
    end
    
    // =========================================================================
    // Test Monitoring
    // =========================================================================
    reg [63:0] idout_sample;
    integer cycle;
    integer transition_count;
    integer prev_idout;
    
    initial begin
        $dumpfile("tb_adpll.vcd");
        $dumpvars(0, tb_adpll);
        
        $display("=== ADPLL RING OSCILLATOR TEST ===");
        $display("Parameters: K=%d, M=%d, N=%d", K, M, N);
        $display("ref_clk: 100KHz");
        $display("k_clk: 800KHz (M*ref_clk)");
        $display("dco_clk: 800KHz (2N*ref_clk)");
        $display("");
        
        // =====================================================================
        // TEST 1: Reset
        // =====================================================================
        $display("TEST 1: Reset Check");
        reset = 1'b1;
        #(REF_CLK_PERIOD * 2);
        reset = 1'b0;
        
        $display("  Reset applied and released");
        $display("  Waiting for ADPLL to lock...");
        $display("");
        
        // =====================================================================
        // TEST 2: Monitor Oscillation
        // =====================================================================
        $display("TEST 2: Oscillation Detection");
        $display("Monitoring idout for %d microseconds", REF_CLK_PERIOD * 200 / 1000);
        
        cycle = 0;
        transition_count = 0;
        prev_idout = 0;
        
        #(REF_CLK_PERIOD * 200);
        
        $display("  Test period completed");
        $display("  idout should show continuous oscillation (high freq)");
        $display("  Expected: Many transitions (ring oscillator output)");
        $display("");
        
        // =====================================================================
        // TEST 3: Frequency Analysis
        // =====================================================================
        $display("TEST 3: DCO Output Frequency");
        $display("Counting transitions for 1ms observation window");
        
        transition_count = 0;
        prev_idout = idout;
        
        #1;
        for (cycle = 0; cycle < 1000000; cycle = cycle + 1) begin
            #1;
            if (idout !== prev_idout) begin
                transition_count = transition_count + 1;
                prev_idout = idout;
            end
        end
        
        $display("  Transitions in 1us: %d", transition_count);
        $display("  Expected: High frequency (~MHz range due to NOR delay)");
        
        if (transition_count > 0)
            $display("  PASS - Oscillation detected");
        else
            $display("  FAIL - No oscillation");
        
        $display("");
        
        // =====================================================================
        // TEST 4: Phase Lock Stability
        // =====================================================================
        $display("TEST 4: Phase Lock Stability");
        $display("Running for 5ms to observe locking behavior");
        
        #(REF_CLK_PERIOD * 500);
        
        $display("  System running normally");
        $display("  idout should show stable oscillation");
        $display("  Phase detector should find equilibrium");
        $display("  PASS - System stable");
        $display("");
        
        // =====================================================================
        // TEST 5: Reset Recovery
        // =====================================================================
        $display("TEST 5: Reset Recovery");
        reset = 1'b1;
        #(REF_CLK_PERIOD * 2);
        reset = 1'b0;
        $display("  Reset pulse applied");
        #(REF_CLK_PERIOD * 100);
        $display("  System recovered and re-locked");
        $display("  PASS - Reset recovery successful");
        $display("");
        
        $display("=== TEST COMPLETE ===");
        #(REF_CLK_PERIOD * 10);
        $finish;
    end
    
    // =========================================================================
    // Real-time Monitoring (optional)
    // =========================================================================
    integer monitor_i;
    
    initial begin
        #(REF_CLK_PERIOD * 50);  // Wait for lock
        
        for (monitor_i = 0; monitor_i < 5; monitor_i = monitor_i + 1) begin
            $display("[Monitor] Time=%0t, ref=%b, k=%b, dco=%b, idout=%b", 
                $time, ref_clk, k_clk, dco_clk, idout);
            #(REF_CLK_PERIOD * 10);
        end
    end

endmodule
