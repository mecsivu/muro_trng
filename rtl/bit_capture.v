`timescale 1ns / 1ps

// =============================================================================
// Module: bit_capture.v
// Chức năng: Capture random bits, pack thành bytes (8 bits), trigger UART tx
// 
// Lấy 1 random bit mỗi khi có sample_clk
// Đóng gói 8 bits thành 1 byte rồi signal UART để gửi
// =============================================================================

module bit_capture (
    input  wire        clk,              // 100 MHz
    input  wire        sample_clk,       // Từ ADPLL (sampling clock)
    input  wire        random_bit_in,    // Single random bit từ TRNG
    input  wire        reset,            // Active high
    
    output wire [7:0]  byte_out,         // 8 bits ready to transmit
    output wire        byte_ready,       // Pulse high khi byte sẵn sàng
    input  wire        byte_ack          // UART xác nhận đã gửi
);

    // =========================================================================
    // Synchronize sample_clk vào clk domain (CDC)
    // =========================================================================
    (* KEEP = "TRUE" *) reg sample_clk_r1;
    (* KEEP = "TRUE" *) reg sample_clk_r2;
    (* KEEP = "TRUE" *) reg sample_clk_r3;
    wire sample_clk_pulse;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sample_clk_r1 <= 1'b0;
            sample_clk_r2 <= 1'b0;
            sample_clk_r3 <= 1'b0;
        end else begin
            sample_clk_r1 <= sample_clk;
            sample_clk_r2 <= sample_clk_r1;
            sample_clk_r3 <= sample_clk_r2;
        end
    end

    // Detect rising edge của sample_clk
    assign sample_clk_pulse = sample_clk_r2 && ~sample_clk_r3;

    // =========================================================================
    // Capture random bits (bit-by-bit)
    // =========================================================================
    reg [7:0]  bit_buffer;
    reg [2:0]  bit_count;  // 0-7
    wire       byte_full;

    assign byte_full = (bit_count == 3'b111);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bit_buffer <= 8'b0;
            bit_count <= 3'b0;
        end else if (sample_clk_pulse) begin
            bit_buffer <= {random_bit_in, bit_buffer[7:1]};  // Shift từ LSB
            if (byte_full)
                bit_count <= 3'b0;
            else
                bit_count <= bit_count + 1;
        end else if (byte_ack) begin
            // Reset sau khi UART confirms gửi xong
            bit_buffer <= 8'b0;
            bit_count <= 3'b0;
        end
    end

    // =========================================================================
    // Output ready signal
    // =========================================================================
    assign byte_out = bit_buffer;
    assign byte_ready = byte_full && sample_clk_pulse;

endmodule
