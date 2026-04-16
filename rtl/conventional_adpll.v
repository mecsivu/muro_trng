`timescale 1ns / 1ps

// =============================================================================
// Module: conventional_adpll.v
// Chức năng: ADPLL tạo xung lấy mẫu ổn định
//            fref = 25MHz (hoặc 12.5, 6.25)
//            Đầu ra: sample_clk (đã chia 2), idout (cho DFF thứ 11)
// =============================================================================

module conventional_adpll #(
    parameter K = 4,
    parameter M = 16,
    parameter N = 8
) (
    input  wire ref_clk,      // Tần số tham chiếu (25MHz)
    input  wire k_clk,        // Clock cho K-Counter (M*fo)
    input  wire dco_clk,      // Clock cho DCO (2N*fo)
    input  wire reset,
    output wire sample_clk,   // Xung lấy mẫu (đã chia 2)
    output wire idout         // DCO output (cho DFF thứ 11)
);
    wire pd_out, carry;
    reg  fb_out;              // ← SỬA: wire thành reg
    wire dco_out;
    
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
        .idout(dco_out)
    );
    
    // Divider /N (phản hồi)
    // N=8 -> cần chia 8
    reg [2:0] fb_count;
    always @(posedge dco_out or posedge reset) begin
        if (reset) begin
            fb_count <= 0;
            fb_out   <= 0;
        end else if (fb_count == (N/2 - 1)) begin
            fb_count <= 0;
            fb_out   <= ~fb_out;
        end else begin
            fb_count <= fb_count + 1;
        end
    end
    
    // Divide-by-2 để tạo sample_clk
    divide_by_2 div_sample (
        .clk(dco_out),
        .reset(reset),
        .out(sample_clk)
    );
    
    assign idout = dco_out;
endmodule