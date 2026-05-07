`timescale 1ns / 1ps

// =============================================================================
// Module: divide_by_2_sync.v (Synchronous Feedback Divider)
// Chức năng: Chia 2 với metastability hardening cho asynchronous input
//
// Note: Dùng idout (từ DCO) làm clock sẽ tạo gated clock.
// Solution: Dùng clock enable từ system clock + asynchronous input handling
// =============================================================================

module divide_by_2_sync (
    input  wire clk_sys,        // System clock (100MHz) - real clock
    input  wire async_in,       // Asynchronous input (từ DCO)
    input  wire reset,
    output reg  out
);
    // Metastability hardening: 2-stage synchronizer
    reg sync1, sync2, sync_prev;
    wire edge_detect;
    
    // Stage 1-2: Synchronize asynchronous input to system clock domain
    always @(posedge clk_sys or posedge reset) begin
        if (reset) begin
            sync1 <= 0;
            sync2 <= 0;
            sync_prev <= 0;
        end else begin
            sync1 <= async_in;
            sync2 <= sync1;
            sync_prev <= sync2;
        end
    end
    
    // Edge detector: capture rising edges of synchronized signal
    assign edge_detect = sync2 & ~sync_prev;
    
    // Divide by 2: toggle output on each edge
    always @(posedge clk_sys or posedge reset) begin
        if (reset)
            out <= 0;
        else if (edge_detect)
            out <= ~out;
    end
    
endmodule
