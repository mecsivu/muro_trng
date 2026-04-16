`timescale 1ns / 1ps

// =============================================================================
// Module: clock_gen.v
// Chức năng: Tạo tất cả tần số từ 100MHz bằng bộ đếm
// =============================================================================

module clock_gen (
    input  wire clk_100mhz,
    input  wire reset,
    
    // Tần số tham chiếu cho 10 RO
    output reg fref_100khz = 0,
    output reg fref_200khz = 0,
    output reg fref_300khz = 0,
    output reg fref_400khz = 0,
    output reg fref_500khz = 0,
    output reg fref_600khz = 0,
    output reg fref_700khz = 0,
    output reg fref_800khz = 0,
    output reg fref_900khz = 0,
    output reg fref_1000khz = 0,
    
    // Clock cho K-Counter (M=8 -> M*fo)
    output reg k_clk_100khz = 0,
    output reg k_clk_200khz = 0,
    output reg k_clk_300khz = 0,
    output reg k_clk_400khz = 0,
    output reg k_clk_500khz = 0,
    output reg k_clk_600khz = 0,
    output reg k_clk_700khz = 0,
    output reg k_clk_800khz = 0,
    output reg k_clk_900khz = 0,
    output reg k_clk_1000khz = 0,
    
    // Clock cho DCO (2N=8 -> 2N*fo)
    output reg dco_clk_100khz = 0,
    output reg dco_clk_200khz = 0,
    output reg dco_clk_300khz = 0,
    output reg dco_clk_400khz = 0,
    output reg dco_clk_500khz = 0,
    output reg dco_clk_600khz = 0,
    output reg dco_clk_700khz = 0,
    output reg dco_clk_800khz = 0,
    output reg dco_clk_900khz = 0,
    output reg dco_clk_1000khz = 0,
    
    // Tần số cho Conventional ADPLL
    output reg fref_25mhz = 0,
    output reg fref_12_5mhz = 0,
    output reg fref_6_25mhz = 0,
    output reg k_clk_25mhz = 0,
    output reg dco_clk_25mhz = 0
);

    // =========================================================================
    // Counter để tạo các tần số
    // =========================================================================
    integer count_100khz  = 0;
    integer count_200khz  = 0;
    integer count_300khz  = 0;
    integer count_400khz  = 0;
    integer count_500khz  = 0;
    integer count_600khz  = 0;
    integer count_700khz  = 0;
    integer count_800khz  = 0;
    integer count_900khz  = 0;
    integer count_1000khz = 0;
    integer count_25mhz   = 0;
    
    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) begin
            count_100khz  <= 0;
            count_200khz  <= 0;
            count_300khz  <= 0;
            count_400khz  <= 0;
            count_500khz  <= 0;
            count_600khz  <= 0;
            count_700khz  <= 0;
            count_800khz  <= 0;
            count_900khz  <= 0;
            count_1000khz <= 0;
            count_25mhz   <= 0;
            
            fref_100khz  <= 0;
            fref_200khz  <= 0;
            fref_300khz  <= 0;
            fref_400khz  <= 0;
            fref_500khz  <= 0;
            fref_600khz  <= 0;
            fref_700khz  <= 0;
            fref_800khz  <= 0;
            fref_900khz  <= 0;
            fref_1000khz <= 0;
            fref_25mhz   <= 0;
        end else begin
            // 100KHz = 100MHz / 1000 (đếm đến 500 rồi toggle)
            if (count_100khz >= 499) begin
                count_100khz <= 0;
                fref_100khz <= ~fref_100khz;
                k_clk_100khz <= ~k_clk_100khz;
                dco_clk_100khz <= ~dco_clk_100khz;
            end else begin
                count_100khz <= count_100khz + 1;
            end
            
            // 200KHz = 100MHz / 500
            if (count_200khz >= 249) begin
                count_200khz <= 0;
                fref_200khz <= ~fref_200khz;
                k_clk_200khz <= ~k_clk_200khz;
                dco_clk_200khz <= ~dco_clk_200khz;
            end else begin
                count_200khz <= count_200khz + 1;
            end
            
            // 300KHz ≈ 100MHz / 333
            if (count_300khz >= 166) begin
                count_300khz <= 0;
                fref_300khz <= ~fref_300khz;
                k_clk_300khz <= ~k_clk_300khz;
                dco_clk_300khz <= ~dco_clk_300khz;
            end else begin
                count_300khz <= count_300khz + 1;
            end
            
            // 400KHz = 100MHz / 250
            if (count_400khz >= 124) begin
                count_400khz <= 0;
                fref_400khz <= ~fref_400khz;
                k_clk_400khz <= ~k_clk_400khz;
                dco_clk_400khz <= ~dco_clk_400khz;
            end else begin
                count_400khz <= count_400khz + 1;
            end
            
            // 500KHz = 100MHz / 200
            if (count_500khz >= 99) begin
                count_500khz <= 0;
                fref_500khz <= ~fref_500khz;
                k_clk_500khz <= ~k_clk_500khz;
                dco_clk_500khz <= ~dco_clk_500khz;
            end else begin
                count_500khz <= count_500khz + 1;
            end
            
            // 600KHz ≈ 100MHz / 166
            if (count_600khz >= 82) begin
                count_600khz <= 0;
                fref_600khz <= ~fref_600khz;
                k_clk_600khz <= ~k_clk_600khz;
                dco_clk_600khz <= ~dco_clk_600khz;
            end else begin
                count_600khz <= count_600khz + 1;
            end
            
            // 700KHz ≈ 100MHz / 143
            if (count_700khz >= 71) begin
                count_700khz <= 0;
                fref_700khz <= ~fref_700khz;
                k_clk_700khz <= ~k_clk_700khz;
                dco_clk_700khz <= ~dco_clk_700khz;
            end else begin
                count_700khz <= count_700khz + 1;
            end
            
            // 800KHz = 100MHz / 125
            if (count_800khz >= 62) begin
                count_800khz <= 0;
                fref_800khz <= ~fref_800khz;
                k_clk_800khz <= ~k_clk_800khz;
                dco_clk_800khz <= ~dco_clk_800khz;
            end else begin
                count_800khz <= count_800khz + 1;
            end
            
            // 900KHz ≈ 100MHz / 111
            if (count_900khz >= 55) begin
                count_900khz <= 0;
                fref_900khz <= ~fref_900khz;
                k_clk_900khz <= ~k_clk_900khz;
                dco_clk_900khz <= ~dco_clk_900khz;
            end else begin
                count_900khz <= count_900khz + 1;
            end
            
            // 1000KHz = 1MHz = 100MHz / 100
            if (count_1000khz >= 49) begin
                count_1000khz <= 0;
                fref_1000khz <= ~fref_1000khz;
                k_clk_1000khz <= ~k_clk_1000khz;
                dco_clk_1000khz <= ~dco_clk_1000khz;
            end else begin
                count_1000khz <= count_1000khz + 1;
            end
            
            // 25MHz = 100MHz / 4
            if (count_25mhz >= 1) begin
                count_25mhz <= 0;
                fref_25mhz <= ~fref_25mhz;
                k_clk_25mhz <= ~k_clk_25mhz;
                dco_clk_25mhz <= ~dco_clk_25mhz;
            end else begin
                count_25mhz <= count_25mhz + 1;
            end
        end
    end

endmodule