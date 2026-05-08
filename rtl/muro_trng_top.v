`timescale 1ns / 1ps

// =============================================================================
// Module: muro_trng_top.v
// Chức năng: TOP LEVEL - MURO-TRNG
// Cấu trúc:
//   - clock_gen: tạo fref cho 10 RO + k_dco_clk riêng từng RO + 25/12.5/6.25MHz
//   - 10 adpll_ring_osc: nguồn entropy
//   - conventional_adpll: tạo sample_clk
//   - 11 DFFs + XOR: lấy mẫu và trộn
//   - xor_corrector: post-processing
// =============================================================================

module muro_trng_top (
    input  wire clk_100mhz,
    input  wire reset,
    output wire random_out
);

    // =========================================================================
    // Clock Generator
    // =========================================================================
    wire fref_25mhz, fref_12_5mhz, fref_6_25mhz;
    wire fref_100khz, fref_200khz, fref_300khz, fref_400khz, fref_500khz;
    wire fref_600khz, fref_700khz, fref_800khz, fref_900khz, fref_1000khz;
    wire k_dco_clk_ro1,  k_dco_clk_ro2,  k_dco_clk_ro3,  k_dco_clk_ro4,  k_dco_clk_ro5;
    wire k_dco_clk_ro6,  k_dco_clk_ro7,  k_dco_clk_ro8,  k_dco_clk_ro9,  k_dco_clk_ro10;

    clock_gen cgen (
        .clk_100mhz     (clk_100mhz),
        .reset          (reset),
        .fref_25mhz     (fref_25mhz),
        .fref_12_5mhz   (fref_12_5mhz),
        .fref_6_25mhz   (fref_6_25mhz),
        .fref_100khz    (fref_100khz),
        .fref_200khz    (fref_200khz),
        .fref_300khz    (fref_300khz),
        .fref_400khz    (fref_400khz),
        .fref_500khz    (fref_500khz),
        .fref_600khz    (fref_600khz),
        .fref_700khz    (fref_700khz),
        .fref_800khz    (fref_800khz),
        .fref_900khz    (fref_900khz),
        .fref_1000khz   (fref_1000khz),
        .k_dco_clk_ro1  (k_dco_clk_ro1),
        .k_dco_clk_ro2  (k_dco_clk_ro2),
        .k_dco_clk_ro3  (k_dco_clk_ro3),
        .k_dco_clk_ro4  (k_dco_clk_ro4),
        .k_dco_clk_ro5  (k_dco_clk_ro5),
        .k_dco_clk_ro6  (k_dco_clk_ro6),
        .k_dco_clk_ro7  (k_dco_clk_ro7),
        .k_dco_clk_ro8  (k_dco_clk_ro8),
        .k_dco_clk_ro9  (k_dco_clk_ro9),
        .k_dco_clk_ro10 (k_dco_clk_ro10)
    );

    // =========================================================================
    // 10 Ring Oscillators (ADPLL-based)
    // Mỗi RO dùng fref và k_clk riêng — tạo jitter với tần số khác nhau
    // =========================================================================
    wire [9:0] ro_outputs;

    adpll_ring_osc ro1  (.ref_clk(fref_100khz),  .k_clk(k_dco_clk_ro1),  .reset(reset), .idout(ro_outputs[0]));
    adpll_ring_osc ro2  (.ref_clk(fref_200khz),  .k_clk(k_dco_clk_ro2),  .reset(reset), .idout(ro_outputs[1]));
    adpll_ring_osc ro3  (.ref_clk(fref_300khz),  .k_clk(k_dco_clk_ro3),  .reset(reset), .idout(ro_outputs[2]));
    adpll_ring_osc ro4  (.ref_clk(fref_400khz),  .k_clk(k_dco_clk_ro4),  .reset(reset), .idout(ro_outputs[3]));
    adpll_ring_osc ro5  (.ref_clk(fref_500khz),  .k_clk(k_dco_clk_ro5),  .reset(reset), .idout(ro_outputs[4]));
    adpll_ring_osc ro6  (.ref_clk(fref_600khz),  .k_clk(k_dco_clk_ro6),  .reset(reset), .idout(ro_outputs[5]));
    adpll_ring_osc ro7  (.ref_clk(fref_700khz),  .k_clk(k_dco_clk_ro7),  .reset(reset), .idout(ro_outputs[6]));
    adpll_ring_osc ro8  (.ref_clk(fref_800khz),  .k_clk(k_dco_clk_ro8),  .reset(reset), .idout(ro_outputs[7]));
    adpll_ring_osc ro9  (.ref_clk(fref_900khz),  .k_clk(k_dco_clk_ro9),  .reset(reset), .idout(ro_outputs[8]));
    adpll_ring_osc ro10 (.ref_clk(fref_1000khz), .k_clk(k_dco_clk_ro10), .reset(reset), .idout(ro_outputs[9]));

    // =========================================================================
    // Conventional ADPLL — tạo sample_clk
    // ref_clk = fref_25mhz (từ T-FF chain trong clock_gen)
    // k_clk   = clk_100mhz (100MHz >> 25MHz, đủ để K counter hoạt động)
    // =========================================================================
    wire sample_clk, adpll_idout;

    conventional_adpll cadpll (
        .ref_clk    (fref_25mhz),
        .k_clk      (clk_100mhz),
        .reset      (reset),
        .sample_clk (sample_clk),
        .idout      (adpll_idout)
    );

    // =========================================================================
    // 11 DFFs lấy mẫu + XOR gate
    // 10 RO outputs + 1 Conventional ADPLL idout → XOR → raw_bit
    // =========================================================================
    reg [10:0] sampled_bits;

    always @(posedge sample_clk or posedge reset) begin
        if (reset) sampled_bits <= 11'b0;
        else       sampled_bits <= {ro_outputs, adpll_idout};
    end

    wire raw_bit;
    assign raw_bit = ^sampled_bits;  // XOR tất cả 11 bit

    // =========================================================================
    // XOR Corrector — post-processing để giảm bias
    // =========================================================================
    xor_corrector post_proc (
        .clk          (sample_clk),
        .reset        (reset),
        .raw_bit      (raw_bit),
        .processed_bit(random_out)
    );

endmodule