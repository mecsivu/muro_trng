`timescale 1ns / 1ps

// =============================================================================
// Module : clock_gen.v
// =============================================================================

module clock_gen (
    input  wire clk_100mhz,     // System clock từ board (100 MHz)
    input  wire reset,          // Synchronous reset, active high

    // [A] Sampling frequencies
    output reg  fref_25mhz,     
    output reg  fref_12_5mhz,   
    output reg  fref_6_25mhz,   

    // [B] Reference frequencies cho 10 Ring Oscillators
    output reg  fref_100khz,
    output reg  fref_200khz,
    output reg  fref_300khz,
    output reg  fref_400khz,
    output reg  fref_500khz,
    output reg  fref_600khz,
    output reg  fref_700khz,
    output reg  fref_800khz,
    output reg  fref_900khz,
    output reg  fref_1000khz,

    // [C] K-counter clock và DCO clock cho từng RO
    output reg  k_dco_clk_ro1,   
    output reg  k_dco_clk_ro2,   
    output reg  k_dco_clk_ro3,   
    output reg  k_dco_clk_ro4,   
    output reg  k_dco_clk_ro5,   
    output reg  k_dco_clk_ro6,   
    output reg  k_dco_clk_ro7,   
    output reg  k_dco_clk_ro8,   
    output reg  k_dco_clk_ro9,   
    output reg  k_dco_clk_ro10   
);

    // =========================================================================
    // [A] SỬA LỖI BUG #8: Thay T-FF chain bằng counter đồng bộ
    // Tại sao: Tránh lỗi "non-clock source on clock pin" DRC.
    // Tất cả flip-flops ở đây đ�?u sẽ dùng clk_100mhz làm clock chính thức.
    // =========================================================================
    // [A] SỬA LỖI BUG #8: Dùng counter đơn giản hơn để Vivado dễ Map
    reg [3:0] div_cnt;

    always @(posedge clk_100mhz) begin
        if (reset) begin
            div_cnt      <= 4'b0000;
            fref_25mhz   <= 1'b0;
            fref_12_5mhz <= 1'b0;
            fref_6_25mhz <= 1'b0;
        end else begin
            div_cnt <= div_cnt + 1'b1;
            
            // Chia 4: 100MHz / 4 = 25MHz (Đảo trạng thái mỗi 2 chu kỳ clk_100)
            if (div_cnt[1:0] == 2'b11) 
                fref_25mhz <= ~fref_25mhz;
            
            // Chia 8: 12.5MHz (Đảo mỗi 4 chu kỳ)
            if (div_cnt[2:0] == 3'b111) 
                fref_12_5mhz <= ~fref_12_5mhz;
                
            // Chia 16: 6.25MHz (Đảo mỗi 8 chu kỳ)
            if (div_cnt[3:0] == 4'b1111) 
                fref_6_25mhz <= ~fref_6_25mhz;
        end
    end

    // =========================================================================
    // [B] Counter-based divider cho 10 fref RO (GIỮ NGUYÊN)
    // =========================================================================
    reg [9:0] cnt_100k, cnt_200k, cnt_300k, cnt_400k, cnt_500k;
    reg [9:0] cnt_600k, cnt_700k, cnt_800k, cnt_900k, cnt_1000k;

    localparam N_100K  = 10'd499;
    localparam N_200K  = 10'd249;
    localparam N_300K  = 10'd166;
    localparam N_400K  = 10'd124;
    localparam N_500K  = 10'd99;
    localparam N_600K  = 10'd82;
    localparam N_700K  = 10'd70;
    localparam N_800K  = 10'd62;
    localparam N_900K  = 10'd55;
    localparam N_1000K = 10'd49;

    always @(posedge clk_100mhz) begin
        if (reset) begin
            cnt_100k  <= 10'd0; fref_100khz  <= 1'b0;
            cnt_200k  <= 10'd0; fref_200khz  <= 1'b0;
            cnt_300k  <= 10'd0; fref_300khz  <= 1'b0;
            cnt_400k  <= 10'd0; fref_400khz  <= 1'b0;
            cnt_500k  <= 10'd0; fref_500khz  <= 1'b0;
            cnt_600k  <= 10'd0; fref_600khz  <= 1'b0;
            cnt_700k  <= 10'd0; fref_700khz  <= 1'b0;
            cnt_800k  <= 10'd0; fref_800khz  <= 1'b0;
            cnt_900k  <= 10'd0; fref_900khz  <= 1'b0;
            cnt_1000k <= 10'd0; fref_1000khz <= 1'b0;
        end else begin
            if (cnt_100k == N_100K)   begin cnt_100k  <= 10'd0; fref_100khz  <= ~fref_100khz;  end else cnt_100k  <= cnt_100k  + 1;
            if (cnt_200k == N_200K)   begin cnt_200k  <= 10'd0; fref_200khz  <= ~fref_200khz;  end else cnt_200k  <= cnt_200k  + 1;
            if (cnt_300k == N_300K)   begin cnt_300k  <= 10'd0; fref_300khz  <= ~fref_300khz;  end else cnt_300k  <= cnt_300k  + 1;
            if (cnt_400k == N_400K)   begin cnt_400k  <= 10'd0; fref_400khz  <= ~fref_400khz;  end else cnt_400k  <= cnt_400k  + 1;
            if (cnt_500k == N_500K)   begin cnt_500k  <= 10'd0; fref_500khz  <= ~fref_500khz;  end else cnt_500k  <= cnt_500k  + 1;
            if (cnt_600k == N_600K)   begin cnt_600k  <= 10'd0; fref_600khz  <= ~fref_600khz;  end else cnt_600k  <= cnt_600k  + 1;
            if (cnt_700k == N_700K)   begin cnt_700k  <= 10'd0; fref_700khz  <= ~fref_700khz;  end else cnt_700k  <= cnt_700k  + 1;
            if (cnt_800k == N_800K)   begin cnt_800k  <= 10'd0; fref_800khz  <= ~fref_800khz;  end else cnt_800k  <= cnt_800k  + 1;
            if (cnt_900k == N_900K)   begin cnt_900k  <= 10'd0; fref_900khz  <= ~fref_900khz;  end else cnt_900k  <= cnt_900k  + 1;
            if (cnt_1000k == N_1000K) begin cnt_1000k <= 10'd0; fref_1000khz <= ~fref_1000khz; end else cnt_1000k <= cnt_1000k + 1;
        end
    end

    // =========================================================================
    // [C] K-counter clock / DCO clock cho từng RO (GIỮ NGUYÊN)
    // =========================================================================
    reg [6:0] cntk_ro1,  cntk_ro2,  cntk_ro3,  cntk_ro4,  cntk_ro5;
    reg [6:0] cntk_ro6,  cntk_ro7,  cntk_ro8,  cntk_ro9,  cntk_ro10;

    localparam NK_RO1  = 7'd62;
    localparam NK_RO2  = 7'd31;
    localparam NK_RO3  = 7'd20;
    localparam NK_RO4  = 7'd15;
    localparam NK_RO5  = 7'd12;
    localparam NK_RO6  = 7'd10;
    localparam NK_RO7  = 7'd8;
    localparam NK_RO8  = 7'd7;
    localparam NK_RO9  = 7'd6;
    localparam NK_RO10 = 7'd6;

    always @(posedge clk_100mhz) begin
        if (reset) begin
            cntk_ro1  <= 7'd0; k_dco_clk_ro1  <= 1'b0;
            cntk_ro2  <= 7'd0; k_dco_clk_ro2  <= 1'b0;
            cntk_ro3  <= 7'd0; k_dco_clk_ro3  <= 1'b0;
            cntk_ro4  <= 7'd0; k_dco_clk_ro4  <= 1'b0;
            cntk_ro5  <= 7'd0; k_dco_clk_ro5  <= 1'b0;
            cntk_ro6  <= 7'd0; k_dco_clk_ro6  <= 1'b0;
            cntk_ro7  <= 7'd0; k_dco_clk_ro7  <= 1'b0;
            cntk_ro8  <= 7'd0; k_dco_clk_ro8  <= 1'b0;
            cntk_ro9  <= 7'd0; k_dco_clk_ro9  <= 1'b0;
            cntk_ro10 <= 7'd0; k_dco_clk_ro10 <= 1'b0;
        end else begin
            if (cntk_ro1  == NK_RO1)  begin cntk_ro1  <= 7'd0; k_dco_clk_ro1  <= ~k_dco_clk_ro1;  end else cntk_ro1  <= cntk_ro1  + 1;
            if (cntk_ro2  == NK_RO2)  begin cntk_ro2  <= 7'd0; k_dco_clk_ro2  <= ~k_dco_clk_ro2;  end else cntk_ro2  <= cntk_ro2  + 1;
            if (cntk_ro3  == NK_RO3)  begin cntk_ro3  <= 7'd0; k_dco_clk_ro3  <= ~k_dco_clk_ro3;  end else cntk_ro3  <= cntk_ro3  + 1;
            if (cntk_ro4  == NK_RO4)  begin cntk_ro4  <= 7'd0; k_dco_clk_ro4  <= ~k_dco_clk_ro4;  end else cntk_ro4  <= cntk_ro4  + 1;
            if (cntk_ro5  == NK_RO5)  begin cntk_ro5  <= 7'd0; k_dco_clk_ro5  <= ~k_dco_clk_ro5;  end else cntk_ro5  <= cntk_ro5  + 1;
            if (cntk_ro6  == NK_RO6)  begin cntk_ro6  <= 7'd0; k_dco_clk_ro6  <= ~k_dco_clk_ro6;  end else cntk_ro6  <= cntk_ro6  + 1;
            if (cntk_ro7  == NK_RO7)  begin cntk_ro7  <= 7'd0; k_dco_clk_ro7  <= ~k_dco_clk_ro7;  end else cntk_ro7  <= cntk_ro7  + 1;
            if (cntk_ro8  == NK_RO8)  begin cntk_ro8  <= 7'd0; k_dco_clk_ro8  <= ~k_dco_clk_ro8;  end else cntk_ro8  <= cntk_ro8  + 1;
            if (cntk_ro9  == NK_RO9)  begin cntk_ro9  <= 7'd0; k_dco_clk_ro9  <= ~k_dco_clk_ro9;  end else cntk_ro9  <= cntk_ro9  + 1;
            if (cntk_ro10 == NK_RO10) begin cntk_ro10 <= 7'd0; k_dco_clk_ro10 <= ~k_dco_clk_ro10; end else cntk_ro10 <= cntk_ro10 + 1;
        end
    end

endmodule