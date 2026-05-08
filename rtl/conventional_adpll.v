`timescale 1ns / 1ps

// =============================================================================
// Module: conventional_adpll.v
// Chức năng: ADPLL tạo xung lấy mẫu ổn định
//            fref = 25MHz (hoặc 12.5, 6.25)
//            Đầu ra: sample_clk (đã chia 2), idout (cho DFF thứ 11)
// =============================================================================

// THAY port list:
module conventional_adpll #(
    parameter K = 4,
    parameter M = 16,
    parameter N = 8
) (
    input  wire ref_clk,
    input  wire k_clk,        // 400 MHz — tạo từ clock_gen bằng counter hoặc MMCM
    input  wire reset,
    output wire sample_clk,
    output wire idout
);
    wire pd_out, carry;
    reg  fb_out;
    wire dco_out;
    reg div2_out;
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
        .idout(dco_out)
    );
    
    // Divider /N (phản hồi) - Asynchronous, generates jitter for entropy
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
    
    // Divide-by-2 để tạo sample_clk (Synchronous with metastability hardening)
    
    always @(posedge k_clk or posedge reset) begin
        if (reset) div2_out <= 1'b0;
        else       div2_out <= dco_out;   // sample DCO output
    end
    
    assign sample_clk = div2_out;
    assign idout      = dco_out;   
endmodule