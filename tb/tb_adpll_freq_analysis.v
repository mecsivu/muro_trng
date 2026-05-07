`timescale 1ns / 1ps

module tb_adpll_freq_analysis();
    
    parameter K = 4;
    parameter M = 8;
    parameter N = 4;
    
    parameter REF_CLK_PERIOD = 10000;    // 100KHz ref clock
    parameter K_CLK_PERIOD = 1250;       // 800KHz k_clk
    parameter DCO_CLK_PERIOD = 1250;     // 800KHz dco_clk
    
    reg clk_100mhz;
    reg reset;
    wire ref_clk;
    wire k_clk;
    wire dco_clk;
    wire idout;
    
    reg ref_clk_gen;
    reg k_clk_gen;
    reg dco_clk_gen;
    
    // Module Instance
    adpll_ring_osc #(.K(K), .M(M), .N(N)) dut (
        .ref_clk(ref_clk),
        .k_clk(k_clk),
        .dco_clk(dco_clk),
        .reset(reset),
        .idout(idout)
    );
    
    assign ref_clk = ref_clk_gen;
    assign k_clk = k_clk_gen;
    assign dco_clk = dco_clk_gen;
    
    // Clock Generators
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
    // Main Test
    // =========================================================================
    integer ref_edges, idout_edges;
    integer window_size;
    integer i;
    real ref_freq, idout_freq, freq_ratio;
    
    initial begin
        $dumpfile("tb_adpll_freq.vcd");
        $dumpvars(0, tb_adpll_freq_analysis);
        
        $display("=== ADPLL FREQUENCY ANALYSIS ===");
        $display("Parameters: K=%d, M=%d, N=%d", K, M, N);
        $display("");
        
        // Reset
        reset = 1'b1;
        #(REF_CLK_PERIOD * 10);
        reset = 1'b0;
        
        $display("Reset released, ADPLL starting to lock...");
        $display("");
        
        // Wait for initial transient
        $display("Waiting 100ms for ADPLL to stabilize...");
        #(REF_CLK_PERIOD * 1000000);
        
        $display("Taking frequency measurements...");
        $display("");
        
        // =====================================================================
        // Measurement Window 1: 100ms observation
        // =====================================================================
        $display("Measurement 1: 100ms window");
        window_size = REF_CLK_PERIOD * 1000000;  // 100ms
        ref_edges = 0;
        idout_edges = 0;
        
        // Count ref_clk edges
        for (i = 0; i < window_size; i = i + 1) begin
            if ((i > 0) && (ref_clk !== prev_ref)) ref_edges = ref_edges + 1;
            prev_ref = ref_clk;
            #1;
        end
        
        // Count idout edges  
        for (i = 0; i < window_size; i = i + 1) begin
            if ((i > 0) && (idout !== prev_idout)) idout_edges = idout_edges + 1;
            prev_idout = idout;
            #1;
        end
        
        ref_freq = (ref_edges * 1e9) / window_size;
        idout_freq = (idout_edges * 1e9) / window_size;
        freq_ratio = idout_freq / ref_freq;
        
        $display("  ref_clk edges: %d (freq: %.0f Hz)", ref_edges, ref_freq);
        $display("  idout edges: %d (freq: %.0f Hz)", idout_edges, idout_freq);
        $display("  Frequency ratio (idout/ref): %.2f", freq_ratio);
        
        if (freq_ratio > 90 && freq_ratio < 110)
            $display("  Status: FREQUENCY LOCKED (ratio close to target)");
        else
            $display("  Status: Frequencies not yet aligned");
        
        $display("");
        
        // =====================================================================
        // Measurement Window 2: Continue for another 100ms
        // =====================================================================
        $display("Measurement 2: Another 100ms window");
        ref_edges = 0;
        idout_edges = 0;
        
        for (i = 0; i < window_size; i = i + 1) begin
            if ((i > 0) && (ref_clk !== prev_ref)) ref_edges = ref_edges + 1;
            prev_ref = ref_clk;
            #1;
        end
        
        for (i = 0; i < window_size; i = i + 1) begin
            if ((i > 0) && (idout !== prev_idout)) idout_edges = idout_edges + 1;
            prev_idout = idout;
            #1;
        end
        
        ref_freq = (ref_edges * 1e9) / window_size;
        idout_freq = (idout_edges * 1e9) / window_size;
        freq_ratio = idout_freq / ref_freq;
        
        $display("  ref_clk edges: %d (freq: %.0f Hz)", ref_edges, ref_freq);
        $display("  idout edges: %d (freq: %.0f Hz)", idout_edges, idout_freq);
        $display("  Frequency ratio (idout/ref): %.2f", freq_ratio);
        
        if (freq_ratio > 90 && freq_ratio < 110)
            $display("  Status: FREQUENCY LOCKED");
        else
            $display("  Status: Frequencies diverging");
        
        $display("");
        $display("=== ANALYSIS COMPLETE ===");
        $finish;
    end
    
    reg prev_ref = 0;
    reg prev_idout = 0;

endmodule
