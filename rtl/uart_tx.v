`timescale 1ns / 1ps

module uart_tx (
    input  wire        clk,
    input  wire        reset,
    input  wire [7:0]  data_in,
    input  wire        data_valid,
    output wire        uart_tx,
    output wire        tx_busy,
    output reg         tx_done      // ← THÊM output mới
);

    localparam BAUD_DIVISOR = 868;
    localparam BAUD_WIDTH = 10;

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0]  state;
    reg [9:0]  baud_counter;
    reg [3:0]  bit_counter;
    reg [9:0]  shift_reg;

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

    assign uart_tx = shift_reg[0];
    assign tx_busy = (state != IDLE);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            shift_reg   <= 10'b1111111111;
            bit_counter <= 0;
            tx_done     <= 1'b0;  // ← THÊM 1: khởi tạo trong reset
        end else begin
            tx_done <= 1'b0;      // ← THÊM 2: default mỗi cycle là LOW
                                  //    (nằm NGOÀI if baud_tick, luôn chạy)
            if (baud_tick) begin
                case (state)
                    IDLE: begin
                        if (data_valid) begin
                            state       <= START;
                            shift_reg   <= {1'b1, data_in, 1'b0};
                            bit_counter <= 0;
                        end
                        // tx_done không cần ghi ở đây
                        // vì dòng default ở trên đã xử lý
                    end

                    START: begin
                        shift_reg   <= {1'b1, shift_reg[9:1]};
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 0) state <= DATA;
                        // tx_done không cần ghi ở đây
                    end

                    DATA: begin
                        shift_reg   <= {1'b1, shift_reg[9:1]};
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 7) state <= STOP;
                        // tx_done không cần ghi ở đây
                    end

                    STOP: begin
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 0) begin
                            state     <= IDLE;
                            shift_reg <= 10'b1111111111;
                            tx_done   <= 1'b1;  // ← THÊM 3: pulse HIGH
                                                //    duy nhất ở đây
                        end
                        // bit_counter != 0: tx_done vẫn LOW nhờ default
                    end
                endcase
            end
        end
    end

endmodule