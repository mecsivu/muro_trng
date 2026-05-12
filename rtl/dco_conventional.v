`timescale 1ns / 1ps

// =============================================================================
// Module: dco_conventional.v  — DCO cho Conventional ADPLL (Figure 5 của paper)
//
// Architecture: 2 T-FF + XOR gate (KHÁC với dco.v dùng cho RO ADPLL)
//
//   T-FF1: clk=k_clk, T=carry  → Dco_out1
//   T-FF2: clk=k_clk, T=carry  → Dco_out2  (independent — tạo 2 pha khác nhau)
//   IDout = Dco_out1 XOR Dco_out2
//
// Tại sao 2 T-FF thay NOR chain?
//   Conventional ADPLL cần DCO stable hơn để tạo sample_clk ổn định.
//   2 T-FF tạo 2 tín hiệu có jitter độc lập, XOR amplify jitter giữa chúng.
//   Đây là thiết kế đúng theo Figure 5 của paper.
//
// K counter và DCO clock (Mfo) bằng nhau — theo paper Tables 2, 3, 4.
// =============================================================================

module dco_conventional (
    input  wire clk,      // Mfo clock (= M × fo, cũng là K counter clock)
    input  wire reset,
    input  wire carry,    // MSB của K-counter
    output wire idout
);

    // T-FF: toggle khi T=1 (carry=1), giữ khi T=0
    reg tff1, tff2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tff1 <= 1'b0;
            tff2 <= 1'b0;
        end else begin
            if (carry) tff1 <= ~tff1;
            if (carry) tff2 <= ~tff2;
        end
    end

    // XOR gate — IDout
    // Khi carry active, cả 2 T-FF toggle nhưng từ trạng thái khác nhau
    // → tạo XOR output có jitter từ sự lệch pha tích lũy giữa 2 T-FF
    assign idout = tff1 ^ tff2;

endmodule