###############################################################################
# MURO-TRNG XDC Constraints for Arty A7-35T (Rev D/E)
# Device: XC7A35TICSG324-1L
# Tool  : Vivado 2015.2+
#
# D?a trên file m?u t? nhà s?n xu?t Digilent
###############################################################################

###############################################################
# SECTION 1: PHYSICAL CONSTRAINTS - I/O PINS
###############################################################

# -----------------------------------------------------------------------------
# Clock signal: 100MHz from board oscillator
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_100mhz]
# IO_L12P_T1_MRCC_35 Sch=gclk[100]

# -----------------------------------------------------------------------------
# Reset button: BTN0 (active high)
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports reset]
# IO_L6N_T0_VREF_16 Sch=btn[0]

# -----------------------------------------------------------------------------
# Output random bit: LED0 (user LED)
# -----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports random_out]
# IO_L24N_T3_35 Sch=led[4] (LED0)

# -----------------------------------------------------------------------------
# (Optional) Additional LEDs for debug - uncomment if needed
# -----------------------------------------------------------------------------
# set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports led_debug[0]]  # LED1
# set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports led_debug[1]]  # LED2
# set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports led_debug[2]]  # LED3

# -----------------------------------------------------------------------------
# Board configuration
# -----------------------------------------------------------------------------
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

###############################################################
# SECTION 2: PRIMARY CLOCK CONSTRAINT
###############################################################

# Define primary clock: 100MHz = 10ns period
create_clock -period 10.000 -name clk_100mhz -waveform {0.000 5.000} [get_ports clk_100mhz]

###############################################################
# SECTION 3: OUTPUT DELAY (minimal cho LED output)
###############################################################

# Output delay cho LED (không critical, ch? ?? tránh warning)
set_output_delay -clock clk_100mhz -max 2.000 [get_ports random_out]
set_output_delay -clock clk_100mhz -min 0.000 [get_ports random_out]

###############################################################
# SECTION 4: TIMING RELAXATION FOR TRNG
#
# MURO-TRNG dùng jitter t? ADPLL làm entropy source.
# Các ???ng d? li?u t? ring oscillators vào sampling DFFs
# là asynchronous m?c ?ích ? không c?n timing closure ch?t.
###############################################################

# ??t asynchronous clock groups ?? tránh phân tích timing không c?n thi?t
set_clock_groups -asynchronous -group [get_clocks clk_100mhz]

# False path cho reset (async)
set_false_path -from [get_ports reset]

###############################################################
# SECTION 5: (TÙY CH?N) Thêm UART ?? xu?t d? li?u ra máy tính
#
# B? comment n?u b?n thêm module UART sau này
# Chân D10 là UART TX, k?t n?i tr?c ti?p v?i USB-UART trên Arty
###############################################################

# set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports uart_tx]
# IO_L19N_T3_VREF_16 Sch=uart_rxd_out

# set_output_delay -clock clk_100mhz -max 10.0 [get_ports uart_tx]

###############################################################
# NOTES:
#
# 1. Arty A7 dùng clock 100MHz s?n có (chân E3)
#    ? Không c?n MMCM hay thay ??i code RTL
#
# 2. Reset dùng BTN0 (chân D9) - active HIGH
#    ? Nh?n nút ?? reset toàn b? h? th?ng
#
# 3. LED0 (chân H5) s? hi?n th? bit random
#    ? Quan sát LED nh?p nháy ng?u nhiên
#
# 4. N?u mu?n test trên nhi?u LED h?n, uncomment dòng led_debug
#
# 5. N?u g?p warning "no clock" ? ?ã ???c x? lý b?ng
#    set_clock_groups -asynchronous
#
###############################################################

# End of XDC


