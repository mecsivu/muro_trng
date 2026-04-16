`timescale 1ns / 1ps

// =============================================================================
// Module: phase_detector.v
// Chức năng: So sánh pha giữa tín hiệu tham chiếu và tín hiệu phản hồi
//            out = ref XOR fb
// =============================================================================

module phase_detector (
    input  wire ref,        // Tín hiệu tham chiếu
    input  wire fb,         // Tín hiệu phản hồi
    output wire out         // 1 = lệch pha, 0 = khóa pha
);
    assign out = ref ^ fb;
endmodule