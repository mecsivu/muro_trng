`timescale 1ns / 1ps

// =============================================================================
// Module: conventional_adpll.v  — Conventional ADPLL tạo sample_clk
//
// Theo paper Table 4 (fo = 6.25 MHz):
//   K = 4
//   M = 16
//   N = 8
//   fo (ref) = 6.25 MHz
//   K Counter clock = M × fo = 16 × 6.25 MHz = 100 MHz  ← dùng được clk_100mhz!
//
// Tại sao chọn Table 4 thay Table 2 (25 MHz)?
//   Table 2 yêu cầu K clock = 400 MHz → không thể generate từ 100MHz system clock
//   mà không dùng MMCM. Table 4 cho K clock = 100 MHz → dùng trực tiếp clk_100mhz.
//
// DCO architecture: dco_conventional (2 T-FF + XOR) theo Figure 5 của paper
//   KHÁC với dco.v (NOR chain) dùng cho 10 RO ADPLL.
//
// Divide-by-N/2 feedback: N=8 → divide-by-4
//   Feedback counter đếm đến N/2=4, toggle fb_out mỗi 4 DCO pulses
//   → fb frequency = fo/2 (sau khi chia 2 lần)
//
// sample_clk = T-FF output của idout (divide-by-2)
//   Đây là clock cho 11 DFF sampling circuit và XOR corrector
// =============================================================================

module conventional_adpll #(
    parameter K = 4,
    parameter M = 16,
    parameter N = 8
) (
    input  wire ref_clk,       // fref = 6.25 MHz (fref_6_25mhz từ clock_gen)
    input  wire k_clk,         // 100 MHz = M × fo (dùng clk_100mhz trực tiếp)
    input  wire reset,
    output wire sample_clk,    // DCO output ÷ 2 → sampling clock cho 11 DFFs
    output wire idout          // DCO raw output (cho DFF thứ 11)
);

    wire pd_out, carry;
    reg  fb_out;
    wire dco_out;

    // =========================================================================
    // Phase Detector: XOR(ref_clk, fb_out)
    // =========================================================================
    phase_detector pd (
        .ref(ref_clk),
        .fb (fb_out),
        .out(pd_out)
    );

    // =========================================================================
    // K-Counter: đếm khi pd_out=1 (phase error), MSB = carry → trigger DCO
    // =========================================================================
    k_counter #(.K(K)) kc (
        .clk   (k_clk),
        .reset (reset),
        .enable(pd_out),
        .carry (carry)
    );

    // =========================================================================
    // DCO: 2 T-FF + XOR (Figure 5) — stable oscillation cho sampling clock
    // =========================================================================
    dco_conventional dco_inst (
        .clk  (k_clk),
        .reset(reset),
        .carry(carry),
        .idout(dco_out)
    );

    // =========================================================================
    // Feedback divider ÷(N/2): tạo fb_out để compare với ref_clk
    // N=8 → ÷4 (toggle fb_out sau mỗi 4 rising edges của dco_out)
    //
    // NOTE: Dùng k_clk để clock counter, sample dco_out — tránh gated clock
    // =========================================================================
    reg [2:0] fb_count;
    reg       dco_r1, dco_r2;
    wire      dco_rise;

    // CDC: detect rising edge của dco_out trong k_clk domain
    always @(posedge k_clk or posedge reset) begin
        if (reset) begin
            dco_r1 <= 1'b0;
            dco_r2 <= 1'b0;
        end else begin
            dco_r1 <= dco_out;
            dco_r2 <= dco_r1;
        end
    end
    assign dco_rise = dco_r1 & ~dco_r2;  // rising edge pulse

    always @(posedge k_clk or posedge reset) begin
        if (reset) begin
            fb_count <= 3'd0;
            fb_out   <= 1'b0;
        end else if (dco_rise) begin
            if (fb_count == (N/2 - 1)) begin
                fb_count <= 3'd0;
                fb_out   <= ~fb_out;
            end else begin
                fb_count <= fb_count + 1;
            end
        end
    end

    // =========================================================================
    // Divide-by-2: tạo sample_clk từ dco_out (T-FF)
    // Synchronous trong k_clk domain
    // =========================================================================
    reg div2_ff;
    always @(posedge k_clk or posedge reset) begin
        if (reset)   div2_ff <= 1'b0;
        else if (dco_rise) div2_ff <= ~div2_ff;
    end

    assign sample_clk = div2_ff;
    assign idout      = dco_out;

endmodule