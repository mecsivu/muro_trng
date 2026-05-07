`timescale 1ns / 1ps

// =============================================================================
// Module: dco.v (FPGA-Optimized)
// Chức năng: Digital Controlled Oscillator
//            Ring oscillator thực tế: NOR chain với shift register delays
//            Để tạo jitter: LUT propagation delay
// NOTE: Delays từ combinational logic path, không phải explicit #delay
// =============================================================================

module dco #(
    parameter NUM_STAGES = 9,  // Số delay stages
    parameter NOR_DELAY = 10   // Đối tượng: delay 10ns (FPGA sẽ tự route)
) (
    input  wire clk,          // Clock cho DFF (2N*fo)
    input  wire reset,        // Reset
    input  wire carry,        // Từ K-Counter (điều khiển tần số)
    output wire idout         // Đầu ra dao động
);
    // =========================================================================
    // Ring Oscillator: Chuỗi NOR gates tạo vòng lặp
    // Jitter tự nhiên từ combinational delay propagation
    // =========================================================================
    wire [NUM_STAGES-1:0] nor_chain;
    reg dff_q;
    
    // NOR đầu tiên: nhận carry và phản hồi từ DFF
    // (Không dùng assign #delay - synthesis sẽ bỏ qua)
    // FPGA sẽ tự tạo delay từ LUT + routing
    assign nor_chain[0] = ~(carry | dff_q);
    
    // Các NOR stage tiếp theo: tạo delay qua cascade logic
    genvar i;
    generate
        for (i = 1; i < NUM_STAGES; i = i + 1) begin : nor_stage
            // Pure combinational - synthesis tự tạo delay thông qua resource
            assign nor_chain[i] = ~(nor_chain[i-1] | 1'b0);
        end
    endgenerate
    
    // DFF lấy mẫu từ ring oscillator
    // Jitter phát sinh từ:
    // 1. Propagation delay không đều của LUT cascade
    // 2. Routing variability (timing uncertainty)
    // 3. Process/temperature variation trên silicon
    always @(posedge clk or posedge reset) begin
        if (reset)
            dff_q <= 1'b0;
        else
            dff_q <= nor_chain[NUM_STAGES-1];
    end
    
    assign idout = dff_q;
endmodule