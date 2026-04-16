`timescale 1ns / 1ps

// =============================================================================
// Module: dco.v
// Chức năng: Digital Controlled Oscillator
//            Chuỗi 9 NOR gates + DFF tạo dao động có jitter
// =============================================================================

module dco #(
    parameter NUM_STAGES = 9  // Số NOR gates
) (
    input  wire clk,          // Clock cho DFF (2N*fo)
    input  wire reset,        // Reset
    input  wire carry,        // Từ K-Counter (điều khiển tần số)
    output wire idout         // Đầu ra dao động
);
    wire [NUM_STAGES-1:0] nor_chain;
    reg dff_q;
    
    // NOR đầu tiên: nhận carry và phản hồi từ DFF
    assign nor_chain[0] = ~(carry | dff_q);
    
    // Các NOR tiếp theo: nối đuôi nhau
    genvar i;
    generate
        for (i = 1; i < NUM_STAGES; i = i + 1) begin : nor_stage
            assign nor_chain[i] = ~(nor_chain[i-1] | 1'b0);
        end
    endgenerate
    
    // DFF lấy mẫu đầu ra của chuỗi NOR
    always @(posedge clk or posedge reset) begin
        if (reset)
            dff_q <= 1'b0;
        else
            dff_q <= nor_chain[NUM_STAGES-1];
    end
    
    assign idout = dff_q;
endmodule