`timescale 1ns / 1ps

// =============================================================================
// Module: clock_gen.v (FIXED)
// Chức năng: Tạo tất cả tần số từ 100MHz bằng bộ đếm
// FIX: K-clock = M*fref, DCO-clock = 2N*fref
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
    
    // Tần số cho Conventional ADPLL (K=4, M=16, N=8)
    output reg fref_25mhz = 0,
    output reg fref_12_5mhz = 0,
    output reg fref_6_25mhz = 0,
    output reg k_clk_25mhz = 0,
    output reg dco_clk_25mhz = 0
);

    // =========================================================================
    // Helper module: divisor chuyên dụng
    // =========================================================================
    // Divisor values: 100MHz / target_freq / 2 (vì toggle 2 lần = 1 period)
    // fref_100khz: divisor = 100MHz / (100kHz*2) = 500
    // k_clk_100khz: divisor = 100MHz / (800kHz*2) = 62.5 ≈ 62
    // dco_clk_100khz: divisor = 100MHz / (800kHz*2) = 62.5 ≈ 62
    
    integer counter_fref_100khz = 0, counter_k_100khz = 0, counter_dco_100khz = 0;
    integer counter_fref_200khz = 0, counter_k_200khz = 0, counter_dco_200khz = 0;
    integer counter_fref_300khz = 0, counter_k_300khz = 0, counter_dco_300khz = 0;
    integer counter_fref_400khz = 0, counter_k_400khz = 0, counter_dco_400khz = 0;
    integer counter_fref_500khz = 0, counter_k_500khz = 0, counter_dco_500khz = 0;
    integer counter_fref_600khz = 0, counter_k_600khz = 0, counter_dco_600khz = 0;
    integer counter_fref_700khz = 0, counter_k_700khz = 0, counter_dco_700khz = 0;
    integer counter_fref_800khz = 0, counter_k_800khz = 0, counter_dco_800khz = 0;
    integer counter_fref_900khz = 0, counter_k_900khz = 0, counter_dco_900khz = 0;
    integer counter_fref_1000khz = 0, counter_k_1000khz = 0, counter_dco_1000khz = 0;
    integer counter_fref_25mhz = 0, counter_k_25mhz = 0, counter_dco_25mhz = 0;
    integer counter_fref_12_5mhz = 0, counter_fref_6_25mhz = 0;
    
    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) begin
            // Reset all counters and outputs
            counter_fref_100khz <= 0; counter_k_100khz <= 0; counter_dco_100khz <= 0;
            counter_fref_200khz <= 0; counter_k_200khz <= 0; counter_dco_200khz <= 0;
            counter_fref_300khz <= 0; counter_k_300khz <= 0; counter_dco_300khz <= 0;
            counter_fref_400khz <= 0; counter_k_400khz <= 0; counter_dco_400khz <= 0;
            counter_fref_500khz <= 0; counter_k_500khz <= 0; counter_dco_500khz <= 0;
            counter_fref_600khz <= 0; counter_k_600khz <= 0; counter_dco_600khz <= 0;
            counter_fref_700khz <= 0; counter_k_700khz <= 0; counter_dco_700khz <= 0;
            counter_fref_800khz <= 0; counter_k_800khz <= 0; counter_dco_800khz <= 0;
            counter_fref_900khz <= 0; counter_k_900khz <= 0; counter_dco_900khz <= 0;
            counter_fref_1000khz <= 0; counter_k_1000khz <= 0; counter_dco_1000khz <= 0;
            counter_fref_25mhz <= 0; counter_k_25mhz <= 0; counter_dco_25mhz <= 0;
            counter_fref_12_5mhz <= 0; counter_fref_6_25mhz <= 0;
            
            fref_100khz <= 0; k_clk_100khz <= 0; dco_clk_100khz <= 0;
            fref_200khz <= 0; k_clk_200khz <= 0; dco_clk_200khz <= 0;
            fref_300khz <= 0; k_clk_300khz <= 0; dco_clk_300khz <= 0;
            fref_400khz <= 0; k_clk_400khz <= 0; dco_clk_400khz <= 0;
            fref_500khz <= 0; k_clk_500khz <= 0; dco_clk_500khz <= 0;
            fref_600khz <= 0; k_clk_600khz <= 0; dco_clk_600khz <= 0;
            fref_700khz <= 0; k_clk_700khz <= 0; dco_clk_700khz <= 0;
            fref_800khz <= 0; k_clk_800khz <= 0; dco_clk_800khz <= 0;
            fref_900khz <= 0; k_clk_900khz <= 0; dco_clk_900khz <= 0;
            fref_1000khz <= 0; k_clk_1000khz <= 0; dco_clk_1000khz <= 0;
            fref_25mhz <= 0; k_clk_25mhz <= 0; dco_clk_25mhz <= 0;
            fref_12_5mhz <= 0; fref_6_25mhz <= 0;
        end else begin
            // ===== 100 KHz (M=8, 2N=8) =====
            if (counter_fref_100khz >= 499) begin
                counter_fref_100khz <= 0;
                fref_100khz <= ~fref_100khz;
            end else
                counter_fref_100khz <= counter_fref_100khz + 1;
                
            if (counter_k_100khz >= 61) begin  // 800KHz: 100MHz/(800k*2)=62.5→62
                counter_k_100khz <= 0;
                k_clk_100khz <= ~k_clk_100khz;
            end else
                counter_k_100khz <= counter_k_100khz + 1;
                
            if (counter_dco_100khz >= 61) begin  // 800KHz
                counter_dco_100khz <= 0;
                dco_clk_100khz <= ~dco_clk_100khz;
            end else
                counter_dco_100khz <= counter_dco_100khz + 1;
            
            // ===== 200 KHz (M=8, 2N=8) =====
            if (counter_fref_200khz >= 249) begin
                counter_fref_200khz <= 0;
                fref_200khz <= ~fref_200khz;
            end else
                counter_fref_200khz <= counter_fref_200khz + 1;
                
            if (counter_k_200khz >= 30) begin  // 1600KHz: 100MHz/(1600k*2)=31.25→31
                counter_k_200khz <= 0;
                k_clk_200khz <= ~k_clk_200khz;
            end else
                counter_k_200khz <= counter_k_200khz + 1;
                
            if (counter_dco_200khz >= 30) begin
                counter_dco_200khz <= 0;
                dco_clk_200khz <= ~dco_clk_200khz;
            end else
                counter_dco_200khz <= counter_dco_200khz + 1;
            
            // ===== 300 KHz (M=8, 2N=8) =====
            if (counter_fref_300khz >= 166) begin
                counter_fref_300khz <= 0;
                fref_300khz <= ~fref_300khz;
            end else
                counter_fref_300khz <= counter_fref_300khz + 1;
                
            if (counter_k_300khz >= 20) begin  // 2400KHz: 100MHz/(2400k*2)=20.83→20
                counter_k_300khz <= 0;
                k_clk_300khz <= ~k_clk_300khz;
            end else
                counter_k_300khz <= counter_k_300khz + 1;
                
            if (counter_dco_300khz >= 20) begin
                counter_dco_300khz <= 0;
                dco_clk_300khz <= ~dco_clk_300khz;
            end else
                counter_dco_300khz <= counter_dco_300khz + 1;
            
            // ===== 400 KHz (M=8, 2N=8) =====
            if (counter_fref_400khz >= 124) begin
                counter_fref_400khz <= 0;
                fref_400khz <= ~fref_400khz;
            end else
                counter_fref_400khz <= counter_fref_400khz + 1;
                
            if (counter_k_400khz >= 15) begin  // 3200KHz
                counter_k_400khz <= 0;
                k_clk_400khz <= ~k_clk_400khz;
            end else
                counter_k_400khz <= counter_k_400khz + 1;
                
            if (counter_dco_400khz >= 15) begin
                counter_dco_400khz <= 0;
                dco_clk_400khz <= ~dco_clk_400khz;
            end else
                counter_dco_400khz <= counter_dco_400khz + 1;
            
            // ===== 500 KHz (M=8, 2N=8) =====
            if (counter_fref_500khz >= 99) begin
                counter_fref_500khz <= 0;
                fref_500khz <= ~fref_500khz;
            end else
                counter_fref_500khz <= counter_fref_500khz + 1;
                
            if (counter_k_500khz >= 12) begin  // 4000KHz
                counter_k_500khz <= 0;
                k_clk_500khz <= ~k_clk_500khz;
            end else
                counter_k_500khz <= counter_k_500khz + 1;
                
            if (counter_dco_500khz >= 12) begin
                counter_dco_500khz <= 0;
                dco_clk_500khz <= ~dco_clk_500khz;
            end else
                counter_dco_500khz <= counter_dco_500khz + 1;
            
            // ===== 600 KHz (M=8, 2N=8) =====
            if (counter_fref_600khz >= 82) begin
                counter_fref_600khz <= 0;
                fref_600khz <= ~fref_600khz;
            end else
                counter_fref_600khz <= counter_fref_600khz + 1;
                
            if (counter_k_600khz >= 10) begin  // 4800KHz
                counter_k_600khz <= 0;
                k_clk_600khz <= ~k_clk_600khz;
            end else
                counter_k_600khz <= counter_k_600khz + 1;
                
            if (counter_dco_600khz >= 10) begin
                counter_dco_600khz <= 0;
                dco_clk_600khz <= ~dco_clk_600khz;
            end else
                counter_dco_600khz <= counter_dco_600khz + 1;
            
            // ===== 700 KHz (M=8, 2N=8) =====
            if (counter_fref_700khz >= 71) begin
                counter_fref_700khz <= 0;
                fref_700khz <= ~fref_700khz;
            end else
                counter_fref_700khz <= counter_fref_700khz + 1;
                
            if (counter_k_700khz >= 8) begin  // 5600KHz
                counter_k_700khz <= 0;
                k_clk_700khz <= ~k_clk_700khz;
            end else
                counter_k_700khz <= counter_k_700khz + 1;
                
            if (counter_dco_700khz >= 8) begin
                counter_dco_700khz <= 0;
                dco_clk_700khz <= ~dco_clk_700khz;
            end else
                counter_dco_700khz <= counter_dco_700khz + 1;
            
            // ===== 800 KHz (M=8, 2N=8) =====
            if (counter_fref_800khz >= 62) begin
                counter_fref_800khz <= 0;
                fref_800khz <= ~fref_800khz;
            end else
                counter_fref_800khz <= counter_fref_800khz + 1;
                
            if (counter_k_800khz >= 7) begin  // 6400KHz
                counter_k_800khz <= 0;
                k_clk_800khz <= ~k_clk_800khz;
            end else
                counter_k_800khz <= counter_k_800khz + 1;
                
            if (counter_dco_800khz >= 7) begin
                counter_dco_800khz <= 0;
                dco_clk_800khz <= ~dco_clk_800khz;
            end else
                counter_dco_800khz <= counter_dco_800khz + 1;
            
            // ===== 900 KHz (M=8, 2N=8) =====
            if (counter_fref_900khz >= 55) begin
                counter_fref_900khz <= 0;
                fref_900khz <= ~fref_900khz;
            end else
                counter_fref_900khz <= counter_fref_900khz + 1;
                
            if (counter_k_900khz >= 6) begin  // 7200KHz
                counter_k_900khz <= 0;
                k_clk_900khz <= ~k_clk_900khz;
            end else
                counter_k_900khz <= counter_k_900khz + 1;
                
            if (counter_dco_900khz >= 6) begin
                counter_dco_900khz <= 0;
                dco_clk_900khz <= ~dco_clk_900khz;
            end else
                counter_dco_900khz <= counter_dco_900khz + 1;
            
            // ===== 1000 KHz (M=8, 2N=8) =====
            if (counter_fref_1000khz >= 49) begin
                counter_fref_1000khz <= 0;
                fref_1000khz <= ~fref_1000khz;
            end else
                counter_fref_1000khz <= counter_fref_1000khz + 1;
                
            if (counter_k_1000khz >= 6) begin  // 8000KHz
                counter_k_1000khz <= 0;
                k_clk_1000khz <= ~k_clk_1000khz;
            end else
                counter_k_1000khz <= counter_k_1000khz + 1;
                
            if (counter_dco_1000khz >= 6) begin
                counter_dco_1000khz <= 0;
                dco_clk_1000khz <= ~dco_clk_1000khz;
            end else
                counter_dco_1000khz <= counter_dco_1000khz + 1;
            
            // ===== Conventional ADPLL @ 25MHz (K=4, M=16, N=8) =====
            if (counter_fref_25mhz >= 1) begin  // 25MHz
                counter_fref_25mhz <= 0;
                fref_25mhz <= ~fref_25mhz;
            end else
                counter_fref_25mhz <= counter_fref_25mhz + 1;
                
            if (counter_k_25mhz >= 0) begin  // 400MHz (M=16: 16*25M=400M)
                counter_k_25mhz <= 0;
                k_clk_25mhz <= ~k_clk_25mhz;
            end else
                counter_k_25mhz <= counter_k_25mhz + 1;
                
            if (counter_dco_25mhz >= 0) begin  // 400MHz (2N=16: 16*25M=400M)
                counter_dco_25mhz <= 0;
                dco_clk_25mhz <= ~dco_clk_25mhz;
            end else
                counter_dco_25mhz <= counter_dco_25mhz + 1;
            
            // ===== Conventional ADPLL @ 12.5MHz =====
            if (counter_fref_12_5mhz >= 3) begin
                counter_fref_12_5mhz <= 0;
                fref_12_5mhz <= ~fref_12_5mhz;
            end else
                counter_fref_12_5mhz <= counter_fref_12_5mhz + 1;
            
            // ===== Conventional ADPLL @ 6.25MHz =====
            if (counter_fref_6_25mhz >= 7) begin
                counter_fref_6_25mhz <= 0;
                fref_6_25mhz <= ~fref_6_25mhz;
            end else
                counter_fref_6_25mhz <= counter_fref_6_25mhz + 1;
        end
    end

endmodule
