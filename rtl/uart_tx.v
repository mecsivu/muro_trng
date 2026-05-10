`timescale 1ns / 1ps

// =============================================================================
// Module: uart_tx.v
// Chức năng: UART Transmitter - Gửi dữ liệu qua cổng serial
// Baud rate: 115200 @ 100MHz clock (8-N-1 format)
// 
// Độ chia: 100MHz / 115200 = 868 clock cycles per bit
// =============================================================================

module uart_tx (
    input  wire        clk,           // 100 MHz
    input  wire        reset,         // Active high
    input  wire [7:0]  data_in,       // 8-bit data to send
    input  wire        data_valid,    // Pulse high to start transmission
    output wire        uart_tx,       // Serial TX output
    output wire        tx_busy        // High while transmitting
);

    // Baud rate divider: 100MHz / 115200 = 868 cycles
    localparam BAUD_DIVISOR = 868;
    localparam BAUD_WIDTH = 10;

    // State machine
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0]  state, next_state;
    reg [9:0]  baud_counter;
    reg [3:0]  bit_counter;
    reg [9:0]  shift_reg;

    // =========================================================================
    // Baud Rate Clock Generator
    // =========================================================================
    wire baud_tick;
    assign baud_tick = (baud_counter == BAUD_DIVISOR - 1);

    always @(posedge clk or posedge reset) begin
        if (reset)
            baud_counter <= 0;
        else if (baud_tick)
            baud_counter <= 0;
        else if (state != IDLE)
            baud_counter <= baud_counter + 1;
    end

    // =========================================================================
    // TX Output Selection
    // =========================================================================
    // UART format: START (0) + 8-bit DATA (LSB first) + STOP (1)
    assign uart_tx = shift_reg[0];
    assign tx_busy = (state != IDLE);

    // =========================================================================
    // State Machine - Main Logic
    // =========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            shift_reg <= 10'b1111111111;  // Idle = all 1s
            bit_counter <= 0;
        end else begin
            if (baud_tick) begin
                case (state)
                    IDLE: begin
                        if (data_valid) begin
                            state <= START;
                            shift_reg <= {1'b1, data_in, 1'b0};  // STOP(1) + DATA(8) + START(0)
                            bit_counter <= 0;
                        end
                    end

                    START: begin
                        // After START bit, move to DATA
                        shift_reg <= {1'b1, shift_reg[9:1]};
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 0) state <= DATA;
                    end

                    DATA: begin
                        // Shift out data bits (8 bits)
                        shift_reg <= {1'b1, shift_reg[9:1]};
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 7) state <= STOP;
                    end

                    STOP: begin
                        // STOP bit duration
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 0) begin
                            state <= IDLE;
                            shift_reg <= 10'b1111111111;
                        end
                    end
                endcase
            end
        end
    end

endmodule
