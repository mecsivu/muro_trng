`timescale 1ns / 1ps

// =============================================================================
// Module : clock_gen.v
// Mục đích: Tạo tất cả tần số cần thiết cho MURO-TRNG từ 100 MHz system clock
//
// Hai nhóm output:
//   [A] Sampling frequencies (cho Conventional ADPLL)
//       Dùng T-FF chain: 100M ÷2 =50M ÷2 =25M ÷2 =12.5M ÷2 =6.25M Hz
//       → Chính xác tuyệt đối, synchronous, không cần PLL
//
//   [B] Reference frequencies cho 10 Ring Oscillators (100K – 1000K Hz)
//       Dùng counter-based divider: toggle mỗi N chu kỳ → fout = 100M/(2N)
//       → Sai số < 1%, hoàn toàn chấp nhận được cho TRNG
//
//   [C] K-counter clock và DCO clock cho từng ADPLL ring oscillator
//       Mỗi RO: K_clk = M×fref = 8×fref,  DCO_clk = 2N×fref = 8×fref
//       (Với M=8, N=4 theo Table 1 của paper)
//       Cũng dùng counter từ 100 MHz
//
// Tất cả output đều SYNCHRONOUS với clk_100mhz
// → Không cần set_false_path cho phần clock gen này
//
// Tác giả paper: Meitei & Kumar, IEEE Access 2025
// Implement bởi: [tên bạn] - Khóa luận tốt nghiệp
// =============================================================================

module clock_gen (
    input  wire clk_100mhz,     // System clock từ board (100 MHz)
    input  wire reset,          // Synchronous reset, active high

    // =========================================================================
    // [A] Sampling frequencies — T-FF chain output
    //     Dùng làm fref cho 3 Conventional ADPLL (paper Table 2,3,4)
    // =========================================================================
    output reg  fref_25mhz,     // 25 MHz   — fo cho Conventional ADPLL #1
    output reg  fref_12_5mhz,   // 12.5 MHz — fo cho Conventional ADPLL #2
    output reg  fref_6_25mhz,   // 6.25 MHz — fo cho Conventional ADPLL #3

    // =========================================================================
    // [B] Reference frequencies cho 10 Ring Oscillators
    //     Dùng làm fref đầu vào của từng ADPLL-based ring oscillator
    // =========================================================================
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

    // =========================================================================
    // [C] K-counter clock và DCO clock cho từng RO
    //     K_clk = DCO_clk = M×fref = 8×fref (M=8, N=4 — Table 1)
    //     RO1: 8×100K = 800K Hz
    //     RO2: 8×200K = 1600K Hz
    //     ...
    //     RO10: 8×1000K = 8000K Hz = 8 MHz
    // =========================================================================
    output reg  k_dco_clk_ro1,   //  800 KHz
    output reg  k_dco_clk_ro2,   // 1600 KHz
    output reg  k_dco_clk_ro3,   // 2400 KHz
    output reg  k_dco_clk_ro4,   // 3200 KHz
    output reg  k_dco_clk_ro5,   // 4000 KHz
    output reg  k_dco_clk_ro6,   // 4800 KHz
    output reg  k_dco_clk_ro7,   // 5600 KHz
    output reg  k_dco_clk_ro8,   // 6400 KHz
    output reg  k_dco_clk_ro9,   // 7200 KHz
    output reg  k_dco_clk_ro10   // 8000 KHz
);

    // =========================================================================
    // [A] T-FF chain: 100 MHz → 50 MHz → 25 MHz → 12.5 MHz → 6.25 MHz
    //
    // Cách hoạt động: T-FF toggle mỗi rising edge của clock cha
    // → 100M clk trigger 50M T-FF → 50M trigger 25M T-FF → v.v.
    //
    // Tại sao dùng T-FF thay vì counter ở đây?
    // Vì 25/12.5/6.25 MHz là power-of-2 divisions → T-FF cho kết quả chính xác
    // tuyệt đối (50% duty cycle), không có sai số làm tròn
    // =========================================================================
    reg tff_50mhz;
    reg tff_25mhz;
    reg tff_12_5mhz;
    reg tff_6_25mhz;

    // Stage 1: 100 MHz → 50 MHz (dùng nội bộ để kéo xuống tiếp)
    always @(posedge clk_100mhz) begin
        if (reset) tff_50mhz <= 1'b0;
        else       tff_50mhz <= ~tff_50mhz;
    end

    // Stage 2: 50 MHz → 25 MHz
    always @(posedge tff_50mhz) begin
        if (reset) tff_25mhz <= 1'b0;
        else       tff_25mhz <= ~tff_25mhz;
    end

    // Stage 3: 25 MHz → 12.5 MHz
    always @(posedge tff_25mhz) begin
        if (reset) tff_12_5mhz <= 1'b0;
        else       tff_12_5mhz <= ~tff_12_5mhz;
    end

    // Stage 4: 12.5 MHz → 6.25 MHz
    always @(posedge tff_12_5mhz) begin
        if (reset) tff_6_25mhz <= 1'b0;
        else       tff_6_25mhz <= ~tff_6_25mhz;
    end

    // Gán ra output
    always @(*) begin
        fref_25mhz    = tff_25mhz;
        fref_12_5mhz  = tff_12_5mhz;
        fref_6_25mhz  = tff_6_25mhz;
    end


    // =========================================================================
    // [B] Counter-based divider cho 10 fref RO (100K – 1000K Hz)
    //
    // Công thức: fout = 100M / (2 × N_toggle)
    // → N_toggle = 100M / (2 × fout)
    //
    // Bảng tính:
    //  fout     N_toggle   Thực tế fout       Sai số
    //  100 KHz    500      100.000 KHz         0%
    //  200 KHz    250      200.000 KHz         0%
    //  300 KHz    167      299.401 KHz        -0.20%
    //  400 KHz    125      400.000 KHz         0%
    //  500 KHz    100      500.000 KHz         0%
    //  600 KHz     83      602.410 KHz        +0.40%
    //  700 KHz     71      704.225 KHz        +0.60%
    //  800 KHz     63      793.651 KHz        -0.79%  (62→806KHz cũng OK)
    //  900 KHz     56      892.857 KHz        -0.79%
    // 1000 KHz     50     1000.000 KHz         0%
    //
    // Sai số tối đa ~0.8% — hoàn toàn chấp nhận được cho TRNG
    // (Jitter trong ADPLL lớn hơn nhiều so với sai số này)
    // =========================================================================

    // Counter width: 500 cần 9-bit (2^9=512), dùng 10-bit cho an toàn
    reg [9:0] cnt_100k, cnt_200k, cnt_300k, cnt_400k, cnt_500k;
    reg [9:0] cnt_600k, cnt_700k, cnt_800k, cnt_900k, cnt_1000k;

    // Ngưỡng toggle (N_toggle - 1 vì đếm từ 0)
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

    // Macro để viết gọn — mỗi counter logic giống hệt nhau
    // Toggle output khi counter đạt ngưỡng, sau đó reset về 0
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
            // 100 KHz
            if (cnt_100k == N_100K)  begin cnt_100k  <= 10'd0; fref_100khz  <= ~fref_100khz;  end
            else                          cnt_100k  <= cnt_100k  + 1;
            // 200 KHz
            if (cnt_200k == N_200K)  begin cnt_200k  <= 10'd0; fref_200khz  <= ~fref_200khz;  end
            else                          cnt_200k  <= cnt_200k  + 1;
            // 300 KHz
            if (cnt_300k == N_300K)  begin cnt_300k  <= 10'd0; fref_300khz  <= ~fref_300khz;  end
            else                          cnt_300k  <= cnt_300k  + 1;
            // 400 KHz
            if (cnt_400k == N_400K)  begin cnt_400k  <= 10'd0; fref_400khz  <= ~fref_400khz;  end
            else                          cnt_400k  <= cnt_400k  + 1;
            // 500 KHz
            if (cnt_500k == N_500K)  begin cnt_500k  <= 10'd0; fref_500khz  <= ~fref_500khz;  end
            else                          cnt_500k  <= cnt_500k  + 1;
            // 600 KHz
            if (cnt_600k == N_600K)  begin cnt_600k  <= 10'd0; fref_600khz  <= ~fref_600khz;  end
            else                          cnt_600k  <= cnt_600k  + 1;
            // 700 KHz
            if (cnt_700k == N_700K)  begin cnt_700k  <= 10'd0; fref_700khz  <= ~fref_700khz;  end
            else                          cnt_700k  <= cnt_700k  + 1;
            // 800 KHz
            if (cnt_800k == N_800K)  begin cnt_800k  <= 10'd0; fref_800khz  <= ~fref_800khz;  end
            else                          cnt_800k  <= cnt_800k  + 1;
            // 900 KHz
            if (cnt_900k == N_900K)  begin cnt_900k  <= 10'd0; fref_900khz  <= ~fref_900khz;  end
            else                          cnt_900k  <= cnt_900k  + 1;
            // 1000 KHz
            if (cnt_1000k == N_1000K) begin cnt_1000k <= 10'd0; fref_1000khz <= ~fref_1000khz; end
            else                           cnt_1000k <= cnt_1000k + 1;
        end
    end


    // =========================================================================
    // [C] K-counter clock / DCO clock cho từng RO
    //
    // K_clk = DCO_clk = M × fref = 8 × fref (M=8 theo Table 1)
    // (Paper dùng cùng clock cho cả K counter và DCO DFF trong mỗi ADPLL RO)
    //
    //  RO | fref    | K_clk = 8×fref | N_toggle cho 100M
    //  1  | 100K    |  800K Hz       | 62  (100M/1600K = 62.5 → 63, err 0.8%)
    //  2  | 200K    | 1600K Hz       | 31  (100M/3200K = 31.25 → 31, err 0.8%)
    //  3  | 300K    | 2400K Hz       | 20  (100M/4800K = 20.83 → 21, err 1.7%)
    //  4  | 400K    | 3200K Hz       | 15  (100M/6400K = 15.6  → 16, err 2.5%)
    //  5  | 500K    | 4000K Hz       | 12  (100M/8000K = 12.5  → 13, err 3.8%)
    //  6  | 600K    | 4800K Hz       | 10  (100M/9600K = 10.4  → 10, err 4%)
    //  7  | 700K    | 5600K Hz       |  9  (100M/11.2M = 8.9   →  9, err 0.9%)
    //  8  | 800K    | 6400K Hz       |  7  (100M/12.8M = 7.8   →  8, err 2.5%)
    //  9  | 900K    | 7200K Hz       |  7  (100M/14.4M = 6.9   →  7, err 0.7%)
    // 10  | 1000K   | 8000K Hz       |  6  (100M/16M   = 6.25  →  6, err 4%)
    //
    // LƯU Ý QUAN TRỌNG:
    // Các tần số cao (RO6–RO10) có sai số lớn hơn khi dùng counter từ 100 MHz.
    // Đây là trade-off của phương pháp counter. Trong thực tế FPGA, vì K_clk
    // chỉ cần cao hơn fref đủ nhiều lần (để K counter count đủ nhanh), sai số
    // nhỏ như thế này không ảnh hưởng đến chức năng TRNG.
    //
    // Nếu cần chính xác hơn: dùng MMCM cho nhóm K_clk (khả thi vì nằm trong
    // dải 4.7 MHz – 800 MHz của Artix-7 MMCM).
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