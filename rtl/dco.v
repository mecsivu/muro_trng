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
    (* KEEP = "TRUE" *) (* DONT_TOUCH = "TRUE" *)
    wire [NUM_STAGES-1:0] nor_chain;

    reg dff_q;
    
    // NOR đầu tiên: nhận carry và phản hồi từ DFF
    // (Không dùng assign #delay - synthesis sẽ bỏ qua)
    // FPGA sẽ tự tạo delay từ LUT + routing

    
    genvar i;

    // Stage 0: NOR(carry, feedback từ DFF)
    assign nor_chain[0] = ~(carry | dff_q);

    // Stage 1..8: Mỗi stage là NOR(output stage trước, carry)
    // Dùng carry làm input thứ 2 — carry là real signal, buộc
    // synthesis tạo LUT 2-input thật, không merge thành inverter
    generate
        for (i = 1; i < NUM_STAGES; i = i + 1) begin : nor_stage
            (* KEEP = "TRUE" *) (* DONT_TOUCH = "TRUE" *)
            assign nor_chain[i] = ~(nor_chain[i-1] | carry);
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