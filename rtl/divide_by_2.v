`timescale 1ns / 1ps

// =============================================================================
// MODULE: divide_by_2 (T-FF)
// =============================================================================
module divide_by_2 (
    input  wire clk,
    input  wire reset,
    output reg  out
);
    always @(posedge clk or posedge reset) begin
        if (reset) out <= 0;
        else       out <= ~out;
    end
endmodule