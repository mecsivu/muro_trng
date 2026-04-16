module k_counter #(parameter K = 4) (
    input  wire clk,
    input  wire reset,
    input  wire enable,
    output reg  carry        // ← SỬA: wire thành reg nếu gán trong always
);
    reg [K-1:0] count;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            carry <= 0;       // ← Thêm dòng này
        end else if (enable) begin
            count <= count + 1;
            carry <= count[K-2];  // ← MSB sắp thành carry
        end else begin
            count <= 0;
            carry <= 0;
        end
    end
endmodule