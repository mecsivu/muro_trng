module k_counter #(parameter K = 4) (
    input  wire clk,
    input  wire reset,
    input  wire enable,
    output reg  carry
);
    reg [K-1:0] count;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            carry <= 0;
        end else if (enable) begin
            count <= count + 1;
            carry <= count[K-1];
        end else begin
            count <= 0;
            carry <= 0;
        end
    end
endmodule