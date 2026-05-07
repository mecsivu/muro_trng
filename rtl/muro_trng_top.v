`timescale 1ns / 1ps

// =============================================================================
// Module: muro_trng_top.v (FPGA OPTIMIZED)
// Chức năng: TOP LEVEL - Kết nối toàn bộ hệ thống MURO-TRNG
//            - T-FF Chain cho sampling frequencies (25M/12.5M/6.25M)
//            - Counter Enable cho 10 RO reference frequencies (100K-1000K)
//            - PLL upsampler cho 400MHz K/DCO clocks
// =============================================================================

module muro_trng_top (
    input  wire clk_100mhz,
    input  wire reset,
    output wire random_out
);
    
    // =========================================================================
    // Clock Generator (Optimized for FPGA)
    // =========================================================================
    wire fref_50mhz, fref_25mhz, fref_12_5mhz, fref_6_25mhz;
    wire k_dco_400mhz, k_dco_400mhz_locked;
    
    // Clock enable signals for 10 ROs
    wire ce_fref_100khz, ce_fref_200khz, ce_fref_300khz, ce_fref_400khz, ce_fref_500khz;
    wire ce_fref_600khz, ce_fref_700khz, ce_fref_800khz, ce_fref_900khz, ce_fref_1000khz;
    
    clock_gen cgen (
        .clk_100mhz(clk_100mhz),
        .reset(reset),
        
        // T-FF Chain outputs
        .fref_50mhz(fref_50mhz),
        .fref_25mhz(fref_25mhz),
        .fref_12_5mhz(fref_12_5mhz),
        .fref_6_25mhz(fref_6_25mhz),
        
        // PLL output
        .k_dco_400mhz(k_dco_400mhz),
        .k_dco_400mhz_locked(k_dco_400mhz_locked),
        
        // Clock enable signals for 10 RO references
        .ce_fref_100khz(ce_fref_100khz),
        .ce_fref_200khz(ce_fref_200khz),
        .ce_fref_300khz(ce_fref_300khz),
        .ce_fref_400khz(ce_fref_400khz),
        .ce_fref_500khz(ce_fref_500khz),
        .ce_fref_600khz(ce_fref_600khz),
        .ce_fref_700khz(ce_fref_700khz),
        .ce_fref_800khz(ce_fref_800khz),
        .ce_fref_900khz(ce_fref_900khz),
        .ce_fref_1000khz(ce_fref_1000khz)
    );
    
    // =========================================================================
    // Clock Enable to Clock Signal Conversion (DFF with CE logic)
    // Convert CE pulses to continuous clock signals for 10 ROs
    // =========================================================================
    reg fref_100khz, fref_200khz, fref_300khz, fref_400khz, fref_500khz;
    reg fref_600khz, fref_700khz, fref_800khz, fref_900khz, fref_1000khz;
    
    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) begin
            fref_100khz  <= 0;
            fref_200khz  <= 0;
            fref_300khz  <= 0;
            fref_400khz  <= 0;
            fref_500khz  <= 0;
            fref_600khz  <= 0;
            fref_700khz  <= 0;
            fref_800khz  <= 0;
            fref_900khz  <= 0;
            fref_1000khz <= 0;
        end else begin
            if (ce_fref_100khz)  fref_100khz  <= ~fref_100khz;
            if (ce_fref_200khz)  fref_200khz  <= ~fref_200khz;
            if (ce_fref_300khz)  fref_300khz  <= ~fref_300khz;
            if (ce_fref_400khz)  fref_400khz  <= ~fref_400khz;
            if (ce_fref_500khz)  fref_500khz  <= ~fref_500khz;
            if (ce_fref_600khz)  fref_600khz  <= ~fref_600khz;
            if (ce_fref_700khz)  fref_700khz  <= ~fref_700khz;
            if (ce_fref_800khz)  fref_800khz  <= ~fref_800khz;
            if (ce_fref_900khz)  fref_900khz  <= ~fref_900khz;
            if (ce_fref_1000khz) fref_1000khz <= ~fref_1000khz;
        end
    end
    
    // =========================================================================
    // Wait for PLL Lock before starting
    // =========================================================================
    reg pll_locked_sync;
    always @(posedge clk_100mhz or posedge reset) begin
        if (reset)
            pll_locked_sync <= 0;
        else
            pll_locked_sync <= k_dco_400mhz_locked;
    end
    
    // =========================================================================
    // 10 Ring Oscillators (ADPLL-based)
    // =========================================================================
    wire [9:0] ro_outputs;
    
    // RO 1 - 100KHz reference
    adpll_ring_osc ro1 (
        .clk_sys(clk_100mhz),
        .ref_clk(fref_100khz),
        .k_clk(k_dco_400mhz),
        .dco_clk(k_dco_400mhz),
        .reset(reset),
        .idout(ro_outputs[0])
    );
    
    // RO 2 - 200KHz reference
    adpll_ring_osc ro2 (
        .clk_sys(clk_100mhz),
        .ref_clk(fref_200khz),
        .k_clk(k_dco_400mhz),
        .dco_clk(k_dco_400mhz),
        .reset(reset),
        .idout(ro_outputs[1])
    );
    
    // RO 3 - 300KHz reference
    adpll_ring_osc ro3 (
        .clk_sys(clk_100mhz),
        .ref_clk(fref_300khz),
        .k_clk(k_dco_400mhz),
        .dco_clk(k_dco_400mhz),
        .reset(reset),
        .idout(ro_outputs[2])
    );
    
    // RO 4 - 400KHz reference
    adpll_ring_osc ro4 (
        .clk_sys(clk_100mhz),
        .ref_clk(fref_400khz),
        .k_clk(k_dco_400mhz),
        .dco_clk(k_dco_400mhz),
        .reset(reset),
        .idout(ro_outputs[3])
    );
    
    // RO 5 - 500KHz reference
    adpll_ring_osc ro5 (
        .clk_sys(clk_100mhz),
        .ref_clk(fref_500khz),
        .k_clk(k_dco_400mhz),
        .dco_clk(k_dco_400mhz),
        .reset(reset),
        .idout(ro_outputs[4])
    );
    
    // RO 6 - 600KHz reference
    adpll_ring_osc ro6 (
        .clk_sys(clk_100mhz),
        .ref_clk(fref_600khz),
        .k_clk(k_dco_400mhz),
        .dco_clk(k_dco_400mhz),
        .reset(reset),
        .idout(ro_outputs[5])
    );
    
    // RO 7 - 700KHz reference
    adpll_ring_osc ro7 (
        .clk_sys(clk_100mhz),
        .ref_clk(fref_700khz),
        .k_clk(k_dco_400mhz),
        .dco_clk(k_dco_400mhz),
        .reset(reset),
        .idout(ro_outputs[6])
    );
    
    // RO 8 - 800KHz reference
    adpll_ring_osc ro8 (
        .clk_sys(clk_100mhz),
        .ref_clk(fref_800khz),
        .k_clk(k_dco_400mhz),
        .dco_clk(k_dco_400mhz),
        .reset(reset),
        .idout(ro_outputs[7])
    );
    
    // RO 9 - 900KHz reference
    adpll_ring_osc ro9 (
        .clk_sys(clk_100mhz),
        .ref_clk(fref_900khz),
        .k_clk(k_dco_400mhz),
        .dco_clk(k_dco_400mhz),
        .reset(reset),
        .idout(ro_outputs[8])
    );
    
    // RO 10 - 1000KHz (1MHz) reference
    adpll_ring_osc ro10 (
        .clk_sys(clk_100mhz),
        .ref_clk(fref_1000khz),
        .k_clk(k_dco_400mhz),
        .dco_clk(k_dco_400mhz),
        .reset(reset),
        .idout(ro_outputs[9])
    );
    
    // =========================================================================
    // Conventional ADPLL (Generate sampling clock from 25MHz)
    // =========================================================================
    wire sample_clk, adpll_idout;
    
    conventional_adpll cadpll (
        .clk_sys(clk_100mhz),
        .ref_clk(fref_25mhz),
        .k_clk(k_dco_400mhz),
        .dco_clk(k_dco_400mhz),
        .reset(reset & pll_locked_sync),
        .sample_clk(sample_clk),
        .idout(adpll_idout)
    );
    
    // =========================================================================
    // 11 DFFs + XOR Gate (Sampling and Mixing)
    // =========================================================================
    reg [10:0] sampled_bits;
    
    always @(posedge sample_clk or posedge reset) begin
        if (reset)
            sampled_bits <= 11'b0;
        else
            sampled_bits <= {ro_outputs, adpll_idout};  // 10 RO + 1 Conventional ADPLL
    end
    
    wire raw_bit;
    assign raw_bit = ^sampled_bits;  // XOR all 11 bits
    
    // =========================================================================
    // XOR Corrector (Post-Processing)
    // =========================================================================
    xor_corrector post_proc (
        .clk(sample_clk),
        .reset(reset),
        .raw_bit(raw_bit),
        .processed_bit(random_out)
    );

endmodule
    
    // =========================================================================
    // Clock Generator
    // =========================================================================
    wire fref_25mhz, k_clk_25mhz, dco_clk_25mhz;
    wire fref_100khz,  fref_200khz,  fref_300khz,  fref_400khz,  fref_500khz;
    wire fref_600khz,  fref_700khz,  fref_800khz,  fref_900khz,  fref_1000khz;
    wire k_clk_100khz, k_clk_200khz, k_clk_300khz, k_clk_400khz, k_clk_500khz;
    wire k_clk_600khz, k_clk_700khz, k_clk_800khz, k_clk_900khz, k_clk_1000khz;
    wire dco_clk_100khz, dco_clk_200khz, dco_clk_300khz, dco_clk_400khz, dco_clk_500khz;
    wire dco_clk_600khz, dco_clk_700khz, dco_clk_800khz, dco_clk_900khz, dco_clk_1000khz;
    wire fref_12_5mhz, fref_6_25mhz;
    
    clock_gen cgen (
        .clk_100mhz(clk_100mhz),
        .reset(reset),
        
        // Tần số cho Conventional ADPLL
        .fref_25mhz(fref_25mhz),
        .fref_12_5mhz(fref_12_5mhz),
        .fref_6_25mhz(fref_6_25mhz),
        .k_clk_25mhz(k_clk_25mhz),
        .dco_clk_25mhz(dco_clk_25mhz),
        
        // Tần số tham chiếu cho 10 RO
        .fref_100khz(fref_100khz),
        .fref_200khz(fref_200khz),
        .fref_300khz(fref_300khz),
        .fref_400khz(fref_400khz),
        .fref_500khz(fref_500khz),
        .fref_600khz(fref_600khz),
        .fref_700khz(fref_700khz),
        .fref_800khz(fref_800khz),
        .fref_900khz(fref_900khz),
        .fref_1000khz(fref_1000khz),
        
        // Clock cho K-Counter
        .k_clk_100khz(k_clk_100khz),
        .k_clk_200khz(k_clk_200khz),
        .k_clk_300khz(k_clk_300khz),
        .k_clk_400khz(k_clk_400khz),
        .k_clk_500khz(k_clk_500khz),
        .k_clk_600khz(k_clk_600khz),
        .k_clk_700khz(k_clk_700khz),
        .k_clk_800khz(k_clk_800khz),
        .k_clk_900khz(k_clk_900khz),
        .k_clk_1000khz(k_clk_1000khz),
        
        // Clock cho DCO
        .dco_clk_100khz(dco_clk_100khz),
        .dco_clk_200khz(dco_clk_200khz),
        .dco_clk_300khz(dco_clk_300khz),
        .dco_clk_400khz(dco_clk_400khz),
        .dco_clk_500khz(dco_clk_500khz),
        .dco_clk_600khz(dco_clk_600khz),
        .dco_clk_700khz(dco_clk_700khz),
        .dco_clk_800khz(dco_clk_800khz),
        .dco_clk_900khz(dco_clk_900khz),
        .dco_clk_1000khz(dco_clk_1000khz)
    );
    
    // =========================================================================
    // 10 Ring Oscillators (MỖI RO CÓ TẦN SỐ RIÊNG)
    // =========================================================================
    wire [9:0] ro_outputs;
    
    // RO 1 - 100KHz
    adpll_ring_osc ro1 (
        .ref_clk(fref_100khz),
        .k_clk(k_clk_100khz),
        .dco_clk(dco_clk_100khz),
        .reset(reset),
        .idout(ro_outputs[0])
    );
    
    // RO 2 - 200KHz
    adpll_ring_osc ro2 (
        .ref_clk(fref_200khz),
        .k_clk(k_clk_200khz),
        .dco_clk(dco_clk_200khz),
        .reset(reset),
        .idout(ro_outputs[1])
    );
    
    // RO 3 - 300KHz
    adpll_ring_osc ro3 (
        .ref_clk(fref_300khz),
        .k_clk(k_clk_300khz),
        .dco_clk(dco_clk_300khz),
        .reset(reset),
        .idout(ro_outputs[2])
    );
    
    // RO 4 - 400KHz
    adpll_ring_osc ro4 (
        .ref_clk(fref_400khz),
        .k_clk(k_clk_400khz),
        .dco_clk(dco_clk_400khz),
        .reset(reset),
        .idout(ro_outputs[3])
    );
    
    // RO 5 - 500KHz
    adpll_ring_osc ro5 (
        .ref_clk(fref_500khz),
        .k_clk(k_clk_500khz),
        .dco_clk(dco_clk_500khz),
        .reset(reset),
        .idout(ro_outputs[4])
    );
    
    // RO 6 - 600KHz
    adpll_ring_osc ro6 (
        .ref_clk(fref_600khz),
        .k_clk(k_clk_600khz),
        .dco_clk(dco_clk_600khz),
        .reset(reset),
        .idout(ro_outputs[5])
    );
    
    // RO 7 - 700KHz
    adpll_ring_osc ro7 (
        .ref_clk(fref_700khz),
        .k_clk(k_clk_700khz),
        .dco_clk(dco_clk_700khz),
        .reset(reset),
        .idout(ro_outputs[6])
    );
    
    // RO 8 - 800KHz
    adpll_ring_osc ro8 (
        .ref_clk(fref_800khz),
        .k_clk(k_clk_800khz),
        .dco_clk(dco_clk_800khz),
        .reset(reset),
        .idout(ro_outputs[7])
    );
    
    // RO 9 - 900KHz
    adpll_ring_osc ro9 (
        .ref_clk(fref_900khz),
        .k_clk(k_clk_900khz),
        .dco_clk(dco_clk_900khz),
        .reset(reset),
        .idout(ro_outputs[8])
    );
    
    // RO 10 - 1000KHz (1MHz)
    adpll_ring_osc ro10 (
        .ref_clk(fref_1000khz),
        .k_clk(k_clk_1000khz),
        .dco_clk(dco_clk_1000khz),
        .reset(reset),
        .idout(ro_outputs[9])
    );
    
    // =========================================================================
    // Conventional ADPLL (Tạo sample clock)
    // =========================================================================
    wire sample_clk, adpll_idout;
    
    conventional_adpll cadpll (
        .ref_clk(fref_25mhz),
        .k_clk(k_clk_25mhz),
        .dco_clk(dco_clk_25mhz),
        .reset(reset),
        .sample_clk(sample_clk),
        .idout(adpll_idout)
    );
    
    // =========================================================================
    // 11 DFFs + XOR Gate (Lấy mẫu và trộn)
    // =========================================================================
    reg [10:0] sampled_bits;
    
    always @(posedge sample_clk or posedge reset) begin
        if (reset)
            sampled_bits <= 11'b0;
        else
            sampled_bits <= {ro_outputs, adpll_idout};  // 10 RO + 1 ADPLL
    end
    
    wire raw_bit;
    assign raw_bit = ^sampled_bits;  // XOR 11 bit
    
    // =========================================================================
    // XOR Corrector (Post-Processing)
    // =========================================================================
    xor_corrector post_proc (
        .clk(sample_clk),
        .reset(reset),
        .raw_bit(raw_bit),
        .processed_bit(random_out)
    );

endmodule