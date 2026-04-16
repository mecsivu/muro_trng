`timescale 1ns / 1ps

// =============================================================================
// Module: xor_corrector.v
// Chức năng: Hậu xử lý - XOR bit hiện tại với bit trước để loại bỏ bias
//            out[i] = raw[i] XOR raw[i-1]
// =============================================================================

module xor_corrector (
    input  wire clk,
    input  wire reset,
    input  wire raw_bit,
    output reg  processed_bit
);
    reg prev_bit;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_bit      <= 1'b0;
            processed_bit <= 1'b0;
        end else begin
            processed_bit <= raw_bit ^ prev_bit;
            prev_bit      <= raw_bit;
        end
    end
endmodule