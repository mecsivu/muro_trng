###############################################################
# MURO-TRNG XDC Constraints - Production Ready
# Device: Zynq-7020 (xc7z020dg484-1)
# Tool  : Vivado 2015.2+
# 
# Tham khảo: "MURO-TRNG: Multi-Oscillator Ring-Oscillator 
#            True Random Number Generator" 
#            - Meitei & Kumar, IEEE Access 2025
#
# Kiến trúc:
#   - Clock Generator: T-FF chain (100M→50M→25M→12.5M→6.25M)
#                      + Counter dividers (fref_100K-1000K + k_dco_clocks)
#   - 10 ADPLL-based Ring Oscillators (10 sources of entropy)
#   - Conventional ADPLL (sampling clock generator)
#   - XOR corrector (post-processing)
#
# Mục tiêu:
#   1. Định cấu hình chân I/O và điện áp
#   2. Ràng buộc timing cho clock chính
#   3. Tạo generated clocks từ logic counters
#   4. Cho phép metastability ý định (entropy source)
#   5. Xử lý CDC paths chính xác
###############################################################

###############################################################
# *** SECTION 1: PHYSICAL CONSTRAINTS ***
# 
# Mục đích: Chỉ cho Vivado vị trí chân vật lý trên board
#          trước khi Vivado có thể áp dụng timing constraints
#
# Lưu ý: PACKAGE_PIN và IOSTANDARD phải khớp với sơ đồ board
#        Nếu board của bạn khác (không phải Zynq-7020 từ Xilinx),
#        hãy cập nhật các giá trị này theo SCH board
###############################################################

# ==========================================
# [1.1] INPUT CLOCK - 100 MHz từ board oscillator
# ==========================================
# Pin: Y9 (LVCMOS33 — 3.3V logic)
# Tần số: 100 MHz (chu kỳ = 10ns)
# Chức năng: Làm base clock cho toàn bộ hệ thống
#
# Cách tìm pin trên board:
#   - Mở schematic board bạn đang dùng
#   - Tìm oscillator 100MHz (thường là thạch anh ngoài)
#   - Theo dõi đến pin FPGA nearest
#   - Kiểm tra tài liệu Pinout của Zynq-7020
set_property PACKAGE_PIN Y9      [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]

# ==========================================
# [1.2] RESET INPUT - Active HIGH, asynchronous
# ==========================================
# Pin: K18 (LVCMOS33)
# Chức năng: Khởi tạo các register (async assert, sync deassert)
#
# Lưu ý: Trong RTL, reset được xử lý synchronous
#        nhưng physical reset từ board là asynchronous
set_property PACKAGE_PIN K18     [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# ==========================================
# [1.3] OUTPUT - Random bit (LSB/MSB)
# ==========================================
# Pin: M15 (LVCMOS33)
# Chức năng: Output ngõ ra bit ngẫu nhiên để LED/logic ngoài
# Tần số: ~100 KHz (sau post-processing)
set_property PACKAGE_PIN M15     [get_ports random_out]
set_property IOSTANDARD LVCMOS33 [get_ports random_out]

# ==========================================
# [1.4] BOARD CONFIGURATION
# ==========================================
# Xilinx FPGA 7-series board config
set_property CONFIG_VOLTAGE 3.3  [current_design]
set_property CFGBVS VCCO         [current_design]

###############################################################
# *** SECTION 2: PRIMARY CLOCK CONSTRAINT ***
#
# Mục đích: Định nghĩa clock chính của hệ thống
#          Vivado sẽ tính timing dựa trên period này
#
# Công thức: period (ns) = 1 / frequency (MHz) × 1000
#           period (ns) = 1 / 100 MHz × 1000 = 10 ns
#
# Cảnh báo: Nếu board của bạn dùng clock khác (ví dụ 50MHz),
#          hãy cập nhật giá trị 10.000 thành 20.000 (hoặc tương ứng)
###############################################################

create_clock -period 10.000 \
             -name clk_100mhz \
             [get_ports clk_100mhz]

###############################################################
# *** SECTION 3: GENERATED CLOCKS - T-FF CHAIN ***
#
# Mục đích: Định nghĩa clocks được tạo từ T-FF chain
#          T-FF toggle mỗi clock edge → chia đôi tần số
#
# Cây T-FF: 100M → 50M → 25M → 12.5M → 6.25M
#          Tất cả SYNCHRONOUS (không sai pha)
#
# Cách tìm paths:
#   - clock_gen.v có các register tff_50mhz, tff_25mhz, v.v.
#   - Thường Vivado tìm được paths này tự động
#   - Nếu không, dùng: get_pins {cgen/tff_25mhz_reg/Q}
###############################################################

# ===============================================
# [3.1] T-FF Chain Stage 1: 100MHz → 50MHz
# ===============================================
create_generated_clock -name tff_50mhz \
    -source [get_ports clk_100mhz] \
    -divide_by 2 \
    [get_pins cgen/tff_50mhz]

# ===============================================
# [3.2] T-FF Chain Stage 2: 50MHz → 25MHz
# ===============================================
create_generated_clock -name tff_25mhz \
    -source [get_pins cgen/tff_50mhz] \
    -divide_by 2 \
    [get_pins cgen/tff_25mhz]

# Note: Tín hiệu 25MHz được output ra như fref_25mhz
# Tạo generated clock từ output port:
create_generated_clock -name fref_25mhz \
    -source [get_pins cgen/tff_25mhz] \
    [get_ports fref_25mhz]

# ===============================================
# [3.3] T-FF Chain Stage 3: 25MHz → 12.5MHz
# ===============================================
create_generated_clock -name tff_12_5mhz \
    -source [get_pins cgen/tff_25mhz] \
    -divide_by 2 \
    [get_pins cgen/tff_12_5mhz]

create_generated_clock -name fref_12_5mhz \
    -source [get_pins cgen/tff_12_5mhz] \
    [get_ports fref_12_5mhz]

# ===============================================
# [3.4] T-FF Chain Stage 4: 12.5MHz → 6.25MHz
# ===============================================
create_generated_clock -name tff_6_25mhz \
    -source [get_pins cgen/tff_12_5mhz] \
    -divide_by 2 \
    [get_pins cgen/tff_6_25mhz]

create_generated_clock -name fref_6_25mhz \
    -source [get_pins cgen/tff_6_25mhz] \
    [get_ports fref_6_25mhz]

###############################################################
# *** SECTION 4: GENERATED CLOCKS - COUNTER DIVIDERS ***
#
# Mục đích: Định nghĩa 10 reference clocks cho ROs (100K-1000K Hz)
#          và K/DCO clocks cho từng ADPLL
#
# Cách hoạt động:
#   - Counters đếm từ 0 đến (500/250/167/125/.../100)-1
#   - Khi count = max, toggle output register
#   - Kết quả: fout = 100MHz / (2 * divisor)
#
#   Ví dụ:
#   - fref_100khz: divisor = 500 → 100M/(2×500) = 100K
#   - fref_1000khz: divisor = 50 → 100M/(2×50) = 1M
#
# Các counter là ASYNCHRONOUS (không locked to main clock)
# → Tạo jitter → Tăng entropy
#
# Lưu ý: Nếu paths không tìm được, thử:
#   - get_pins cgen/cnt_100khz_reg/Q (hoặc _[*])
#   - Hoặc dùng ASYNC_REG constraint thay vì generated_clock
###############################################################

# ============ Reference Frequencies: 100K - 1000K Hz ============

create_generated_clock -name fref_100khz_clk \
    -source [get_ports clk_100mhz] \
    -divide_by 500 \
    [get_ports fref_100khz]

create_generated_clock -name fref_200khz_clk \
    -source [get_ports clk_100mhz] \
    -divide_by 250 \
    [get_ports fref_200khz]

create_generated_clock -name fref_300khz_clk \
    -source [get_ports clk_100mhz] \
    -divide_by 167 \
    [get_ports fref_300khz]

create_generated_clock -name fref_400khz_clk \
    -source [get_ports clk_100mhz] \
    -divide_by 125 \
    [get_ports fref_400khz]

create_generated_clock -name fref_500khz_clk \
    -source [get_ports clk_100mhz] \
    -divide_by 100 \
    [get_ports fref_500khz]

create_generated_clock -name fref_600khz_clk \
    -source [get_ports clk_100mhz] \
    -divide_by 83 \
    [get_ports fref_600khz]

create_generated_clock -name fref_700khz_clk \
    -source [get_ports clk_100mhz] \
    -divide_by 71 \
    [get_ports fref_700khz]

create_generated_clock -name fref_800khz_clk \
    -source [get_ports clk_100mhz] \
    -divide_by 63 \
    [get_ports fref_800khz]

create_generated_clock -name fref_900khz_clk \
    -source [get_ports clk_100mhz] \
    -divide_by 56 \
    [get_ports fref_900khz]

create_generated_clock -name fref_1000khz_clk \
    -source [get_ports clk_100mhz] \
    -divide_by 50 \
    [get_ports fref_1000khz]

# ============ K/DCO Clocks cho từng RO: 8×fref Hz ============
#
# Theo Paper Table 1: M=8, N=4
# K_clk = M × fref = 8 × fref
# 
# Ví dụ:
#   RO1: k_dco_clk_ro1 = 8 × 100K = 800K Hz
#   RO2: k_dco_clk_ro2 = 8 × 200K = 1.6M Hz
#   ...
#   RO10: k_dco_clk_ro10 = 8 × 1M = 8M Hz

create_generated_clock -name k_dco_clk_ro1 \
    -source [get_ports clk_100mhz] \
    -divide_by 63 \
    [get_ports k_dco_clk_ro1]

create_generated_clock -name k_dco_clk_ro2 \
    -source [get_ports clk_100mhz] \
    -divide_by 31 \
    [get_ports k_dco_clk_ro2]

create_generated_clock -name k_dco_clk_ro3 \
    -source [get_ports clk_100mhz] \
    -divide_by 21 \
    [get_ports k_dco_clk_ro3]

create_generated_clock -name k_dco_clk_ro4 \
    -source [get_ports clk_100mhz] \
    -divide_by 16 \
    [get_ports k_dco_clk_ro4]

create_generated_clock -name k_dco_clk_ro5 \
    -source [get_ports clk_100mhz] \
    -divide_by 13 \
    [get_ports k_dco_clk_ro5]

create_generated_clock -name k_dco_clk_ro6 \
    -source [get_ports clk_100mhz] \
    -divide_by 11 \
    [get_ports k_dco_clk_ro6]

create_generated_clock -name k_dco_clk_ro7 \
    -source [get_ports clk_100mhz] \
    -divide_by 9 \
    [get_ports k_dco_clk_ro7]

create_generated_clock -name k_dco_clk_ro8 \
    -source [get_ports clk_100mhz] \
    -divide_by 8 \
    [get_ports k_dco_clk_ro8]

create_generated_clock -name k_dco_clk_ro9 \
    -source [get_ports clk_100mhz] \
    -divide_by 7 \
    [get_ports k_dco_clk_ro9]

create_generated_clock -name k_dco_clk_ro10 \
    -source [get_ports clk_100mhz] \
    -divide_by 6 \
    [get_ports k_dco_clk_ro10]

###############################################################
# *** SECTION 5: FALSE PATHS - INTENTIONAL METASTABILITY ***
#
# Mục đích: Cho phép metastability ý định trên feedback paths
#          Đây là điều QUAN TRỌNG vì:
#          - TRNG cần jitter + chaos
#          - Timing closure ở đây là ĐẠN NGẠ
#          - Vivado sẽ cảnh báo nếu không set_false_path
#
# Cảnh báo: Nếu bạn KHÔNG muốn metastability, xóa section này
#          Nhưng khi đó TRNG sẽ không hoạt động tốt!
###############################################################

# =====================================================
# [5.1] DCO Feedback Paths → Divide-by-2 Synchronizers
# =====================================================
# DCO output (asynchronous) đi vào divide_by_2_sync
# Synchronizer có 2 DFF stages để giảm metastability
# Nhưng vẫn có jitter ý định → tốt cho entropy
#
# Set false path vì timing closure không quan trọng ở đây

set_false_path -through [get_pins */divide_by_2_sync/async_in] \
               -through [get_pins */divide_by_2_sync/sync1]

# =====================================================
# [5.2] Async Clock Domain Crossing (CDC)
# =====================================================
# ADPLL DCO output → Synchronized DFFs → Sampling
# 
# Ví dụ: Conventional ADPLL DCO → 2-stage sync → Sample logic
# Set false path vì:
#   - DCO tần số cao (25MHz) → RO feedback asynchronous
#   - Sampling clock khác miền thời gian
#   - Jitter ở đây là ĐẠN NGẠ (entropy)

set_false_path -from [get_cells {cadpll/dco_inst/dff_q}] \
               -to [get_cells {cadpll/div_sample/sync1}]

set_false_path -from [get_cells {ro1/dco_inst/dff_q}] \
               -to [get_cells {ro1/div_fb/sync1}]

set_false_path -from [get_cells {ro2/dco_inst/dff_q}] \
               -to [get_cells {ro2/div_fb/sync1}]

set_false_path -from [get_cells {ro3/dco_inst/dff_q}] \
               -to [get_cells {ro3/div_fb/sync1}]

set_false_path -from [get_cells {ro4/dco_inst/dff_q}] \
               -to [get_cells {ro4/div_fb/sync1}]

set_false_path -from [get_cells {ro5/dco_inst/dff_q}] \
               -to [get_cells {ro5/div_fb/sync1}]

set_false_path -from [get_cells {ro6/dco_inst/dff_q}] \
               -to [get_cells {ro6/div_fb/sync1}]

set_false_path -from [get_cells {ro7/dco_inst/dff_q}] \
               -to [get_cells {ro7/div_fb/sync1}]

set_false_path -from [get_cells {ro8/dco_inst/dff_q}] \
               -to [get_cells {ro8/div_fb/sync1}]

set_false_path -from [get_cells {ro9/dco_inst/dff_q}] \
               -to [get_cells {ro9/div_fb/sync1}]

set_false_path -from [get_cells {ro10/dco_inst/dff_q}] \
               -to [get_cells {ro10/div_fb/sync1}]

###############################################################
# *** SECTION 6: I/O TIMING CONSTRAINTS ***
#
# Mục đích: Giới hạn thời gian truyền tín hiệu vào/ra FPGA
#          Ngăn chặn setup/hold violations ở I/O pads
#
# Cách tính:
#   - Setup time: Tín hiệu vào phải ổn định trước rising edge clock
#   - Hold time: Tín hiệu vào phải giữ nguyên sau rising edge
#   - Output delay: Output phải ổn định trong khoảng thời gian cho phép
###############################################################

# =====================================================
# [6.1] INPUT DELAYS - Clock và Reset
# =====================================================
# Tín hiệu input từ board đi vào FPGA
# Max delay = thời gian truyền trên board + margin an toàn

set_input_delay -clock clk_100mhz \
                -max 0.5 \
                [get_ports reset]

# =====================================================
# [6.2] OUTPUT DELAY - Random bit
# =====================================================
# Tín hiệu output từ FPGA ra board (LED, logic ngoài)
# Max delay = thời gian truyền trên board + margin

set_output_delay -clock clk_100mhz \
                 -max 0.5 \
                 [get_ports random_out]

###############################################################
# *** SECTION 7: ADDITIONAL CONSTRAINTS (OPTIONAL) ***
#
# Mục đích: Các constraint thêm để tối ưu hóa và ngăn chặn
#          các cảnh báo từ Vivado
###############################################################

# =====================================================
# [7.1] ASYNC_REG - Metastability Hardening
# =====================================================
# Các register trong synchronizers cần attribute này
# để Vivado biết là chúng có thể bị metastability
# và không cần tiên tiên timing closure

# set_property ASYNC_REG TRUE [get_cells {ro*/div_fb/sync_dff[*]}]
# set_property ASYNC_REG TRUE [get_cells {cadpll/div_sample/sync_dff[*]}]

# =====================================================
# [7.2] ALLOW_COMBINATORIAL_LOOPS
# =====================================================
# NOR chain trong DCO tạo feedback loop combinatorial
# Đây là ĐẠN NGẠ → Tạo ring oscillation
# Cho Vivado phép loop này tồn tại

# set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_cells {ro*/dco_inst/*}]
# set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_cells {cadpll/dco_inst/*}]

# =====================================================
# [7.3] MAXDELAY - Cross-Domain Timing
# =====================================================
# Nếu muốn Vivado kiểm tra ít nhất delay qua CDC paths
# (khác với set_false_path là bỏ qua hoàn toàn):

# set_max_delay -through [get_pins */divide_by_2_sync/async_in] 20.0

###############################################################
# *** NOTES FOR SYNTHESIS & IMPLEMENTATION ***
#
# 1. Nếu Vivado hiển thị:
#    "ERROR: [DRC ...] No timing constraints specified"
#    → Hãy chắc chắn rằng file này được thêm vào project
#    → Path: Project settings → Synthesis/Implementation → XDC file
#
# 2. Nếu synthesis báo cảnh về gated clocks:
#    → Đây là ĐẠN NGẠ (counter CE tạo gated logic)
#    → Có thể bỏ qua nếu timing OK
#
# 3. Để debug:
#    - Vivado → Tools → Generate Report → Timing Summary
#    - Xem "Failing endpoints" (nếu có)
#    - Đối với TRNG, có thể accept tính chất asynchronous
#
# 4. Trước khi deploy lên FPGA:
#    - Chạy Place & Route → xem "Timing Summary"
#    - Setup/Hold violations phải < 0
#    - Nếu có violations → điều chỉnh constraints hoặc architeture
#
###############################################################

# End of XDC Constraints File
