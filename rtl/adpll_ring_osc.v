`timescale 1ns / 1ps

// =============================================================================
// Module: adpll_ring_osc.v
// Chức năng: ADPLL hoàn chỉnh cho 1 Ring Oscillator
//            Tích hợp: Phase Detector + K-Counter + DCO + Divider
// =============================================================================

module adpll_ring_osc #(
    parameter K = 4,
    parameter M = 8,
    parameter N = 4
) (
    input  wire ref_clk,      // Tần số tham chiếu (100KHz - 1000KHz)
    input  wire k_clk,        // Clock cho K-Counter (M*fo)
    input  wire dco_clk,      // Clock cho DCO (2N*fo)
    input  wire reset,
    output wire idout         // Đầu ra dao động (có jitter)
);
    wire pd_out, carry, fb_out;
    
    // Phase Detector
    phase_detector pd (
        .ref(ref_clk),
        .fb(fb_out),
        .out(pd_out)
    );
    
    // K-Counter
    k_counter #(.K(K)) kc (
        .clk(k_clk),
        .reset(reset),
        .enable(pd_out),
        .carry(carry)
    );
    
    // DCO
    dco #(.NUM_STAGES(9)) dco_inst (
        .clk(dco_clk),
        .reset(reset),
        .carry(carry),
        .idout(idout)
    );
    
    // Divide-by-2 (phản hồi về Phase Detector)
    // N=4 -> N/2=2 -> cần chia 2
    divide_by_2 div_fb (
        .clk(idout),
        .reset(reset),
        .out(fb_out)
    );
endmodule