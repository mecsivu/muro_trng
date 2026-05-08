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
    input  wire ref_clk,      // fref riêng của từng RO
    input  wire k_clk,        // K/DCO clock riêng (= 8×fref)
    input  wire reset,
    output wire idout
);
    wire pd_out, carry;
    reg  fb_out;
    
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
        .clk(k_clk),
        .reset(reset),
        .carry(carry),
        .idout(idout)
    );
    
    // Divide-by-2 with Metastability Hardening (phản hồi về Phase Detector)
    // FIX: Use synchronizer instead of direct async clock to avoid gated clock
    always @(posedge k_clk or posedge reset) 
    begin
        if (reset) fb_out <= 1'b0;
        else       fb_out <= idout;   // sample DCO output để tạo feedback
    end

endmodule