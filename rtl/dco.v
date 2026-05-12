`timescale 1ns / 1ps

// =============================================================================
// Module: dco.v  — DCO cho ADPLL-based Ring Oscillator (Figure 3 của paper)
//
// Architecture: 9 NOR gates (2-input) + 1 DFF
//   NOR[0]: inputs = (carry, dff_q)   ← feedback từ DFF
//   NOR[1..8]: inputs = (NOR[i-1], carry)
//   DFF: clk = k_clk (= 2N×fo), D = NOR[8], Q = idout
//
// CRITICAL — Tại sao dùng LUT2 primitive thay assign:
//   Vivado synthesis sẽ detect "combinational loop" từ assign statements
//   và tự động break loop bằng cách thay bằng hằng số.
//   Instantiate LUT2 primitive trực tiếp → Vivado KHÔNG được phép optimize.
//   KEEP + DONT_TOUCH trên net/cell buộc P&R giữ nguyên kết nối.
//
// NOR = LUT2 với INIT = 4'b0001
//   I1 I0 | O
//    0  0  | 1
//    0  1  | 0
//    1  0  | 0
//    1  1  | 0
// =============================================================================

module dco #(
    parameter NUM_STAGES = 9
) (
    input  wire clk,      // ID clock = 2N×fo (từ clock_gen)
    input  wire reset,
    input  wire carry,    // MSB của K-counter
    output wire idout
);

    // =========================================================================
    // NOR chain — instantiate LUT2 primitive trực tiếp
    // Vivado không thể optimize primitives đã được instantiate
    // =========================================================================
    (* KEEP = "TRUE" *) wire [NUM_STAGES-1:0] nor_chain;

    reg dff_q;

    // Stage 0: NOR(carry, dff_q)
    (* DONT_TOUCH = "TRUE" *)
    LUT2 #(.INIT(4'b0001)) nor0 (
        .O (nor_chain[0]),
        .I0(carry),
        .I1(dff_q)
    );

    // Stage 1..8: NOR(nor_chain[i-1], carry)
    genvar i;
    generate
        for (i = 1; i < NUM_STAGES; i = i + 1) begin : nor_stage
            (* DONT_TOUCH = "TRUE" *)
            LUT2 #(.INIT(4'b0001)) nor_inst (
                .O (nor_chain[i]),
                .I0(nor_chain[i-1]),
                .I1(carry)
            );
        end
    endgenerate

    // =========================================================================
    // DFF: sample NOR chain output
    // Clock = 2N×fo (không phải ring oscillator clock — đây là ADPLL DCO,
    // DFF được drive bởi external clock để tạo jitter từ setup/hold violation)
    // =========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset)
            dff_q <= 1'b0;
        else
            dff_q <= nor_chain[NUM_STAGES-1];
    end

    assign idout = dff_q;

endmodule