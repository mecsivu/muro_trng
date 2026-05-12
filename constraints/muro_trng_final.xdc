###############################################################################
# MURO-TRNG XDC Constraints - Arty A7-35T (Rev D/E)
# Device: XC7A35TICSG324-1L
# [FIXED - Timing 38-282: uart_tx output delay + no_clock registers]
###############################################################################

###############################################################
# SECTION 1: I/O PINS
###############################################################

set_property -dict {PACKAGE_PIN E3  IOSTANDARD LVCMOS33} [get_ports clk_100mhz]
set_property -dict {PACKAGE_PIN D9  IOSTANDARD LVCMOS33} [get_ports reset]
set_property -dict {PACKAGE_PIN H5  IOSTANDARD LVCMOS33} [get_ports random_out]
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports uart_tx]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

###############################################################
# SECTION 2: PRIMARY CLOCK
###############################################################

create_clock -period 10.000 -name clk_100mhz \
             -waveform {0.000 5.000} [get_ports clk_100mhz]

###############################################################
# SECTION 3: OUTPUT DELAY
#
# ROOT CAUSE c?a Timing 38-282 (-11.447ns slack):
#
#   set_output_delay -clock clk_100mhz -max 10.000 [get_ports uart_tx]
#
#   Constraint này có ngh?a: "thi?t b? nh?n (PC) latch uart_tx
#   10ns SAU rising edge clk_100mhz" - t?c là data ph?i ?n ??nh
#   t?i t = 10ns - 10ns = 0ns. Không th? ?áp ?ng vì OBUF m?t ~3.5ns.
#
#   TH?C T?: uart_tx là async UART signal. Không có external device
#   nào latch nó theo clk_100mhz. Output delay constraint ch? ??
#   tránh Vivado warning, không c?n tight.
#
# FIX: Dùng set_false_path thay vì set_output_delay cho uart_tx.
#   ? Vivado b? qua timing analysis cho path này hoàn toàn.
#   ? ?ây là cách ?úng cho async output (UART TX, LED, v.v.)
###############################################################

# random_out: LED, async, không c?n timing closure
set_false_path -to [get_ports random_out]

# uart_tx: UART async serial, không có external clock reference
# [FIX] Dùng false_path thay vì output_delay -max 10ns
set_false_path -to [get_ports uart_tx]

###############################################################
# SECTION 4: FALSE PATH - ASYNC RESET VÀ "NO CLOCK" REGISTERS
#
# T? timing report "checking no_clock":
#
#   cadpll/fb_out_reg_reg/C  ? 36 registers không có clock
#   cgen/k_dco_clk_ro*_reg/C ? 7 registers m?i RO, không có clock
#
# Lý do: các FF này ch?y trên signal ???c generate t? logic
# (fb_out_reg trong conventional_adpll, k_dco_clk_ro* trong clock_gen)
# không ph?i t? BUFG ? Vivado không nh?n di?n là "clock".
# ? "checking unconstrained_internal_endpoints: 190 pins" (HIGH)
#
# FIX: set_false_path -from các FF root ?ó ?? Vivado không c?
# analyze timing path t? chúng.
###############################################################

# Async reset
set_false_path -from [get_ports reset]

# fb_out_reg trong conventional_adpll: FF này là divider feedback,
# ch?y trên k_clk nh?ng output ???c dùng nh? data signal (async intent)
set_false_path -from [get_cells -hierarchical \
    -filter {NAME =~ *cadpll/fb_out_reg* && IS_SEQUENTIAL}]

# k_dco_clk_ro* trong clock_gen: FF output dùng làm "clock enable"
# cho các RO, v? b?n ch?t là async so v?i system clock domain
set_false_path -from [get_cells -hierarchical \
    -filter {NAME =~ *cgen/k_dco_clk_ro* && IS_SEQUENTIAL}]

###############################################################
# SECTION 5: FALSE PATH - CDC FLIP-FLOPS
#
# Các ASYNC_REG FF trong top module và submodules
###############################################################

# CDC: ro_outputs ? ro_sync1 (sample_clk domain)
set_false_path -to [get_cells -hierarchical \
    -filter {NAME =~ *ro_sync1_reg* && IS_SEQUENTIAL}]

# CDC: adpll_idout ? adpll_sync1
set_false_path -to [get_cells -hierarchical \
    -filter {NAME =~ *adpll_sync1_reg* && IS_SEQUENTIAL}]

# CDC: dco_out ? dco_r1 (trong conventional_adpll)
set_false_path -to [get_cells -hierarchical \
    -filter {NAME =~ *dco_r1_reg* && IS_SEQUENTIAL}]

# CDC: sample_clk ? sample_clk_r1 (trong bit_capture)
set_false_path -to [get_cells -hierarchical \
    -filter {NAME =~ *sample_clk_r1_reg* && IS_SEQUENTIAL}]

###############################################################
# SECTION 6: DONT_TOUCH backup cho DCO ring oscillator
###############################################################

# Uncomment n?u Vivado optimize away NOR chain trong dco.v:
# set_property DONT_TOUCH TRUE [get_cells -hierarchical \
#     -filter {NAME =~ *dco_inst* && IS_PRIMITIVE}]

###############################################################
# EXPECTED K?T QU? SAU FIX:
#
#   Timing Summary:
#     WNS ? 0  (không còn failing endpoints)
#     TNS = 0
#
#   check_timing:
#     no_clock: còn HIGH nh?ng ?ã ??? cover b?i false_path ? trên
#     unconstrained_internal_endpoints: gi?m ?áng k?
#
#   N?u v?n còn violation: ch?y report_timing_summary và
#   xem "Path 1" - paste vào chat ?? debug ti?p.
###############################################################
