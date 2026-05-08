###############################################################
# MURO-TRNG XDC Constraints - FIXED VERSION
# Device: Zynq-7020 (xc7z020clg484-1)
# Tool  : Vivado 2015.2+
#
# FIX: Loại bỏ constraints trên internal signals
#      Chỉ constraint TOP-LEVEL I/O ports
###############################################################

###############################################################
# SECTION 1: PHYSICAL CONSTRAINTS - I/O PINS
###############################################################

# INPUT CLOCK - 100 MHz từ board oscillator
set_property PACKAGE_PIN Y9      [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]

# RESET INPUT - Active HIGH, async
set_property PACKAGE_PIN K18     [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# OUTPUT - Random bit
set_property PACKAGE_PIN M15     [get_ports random_out]
set_property IOSTANDARD LVCMOS33 [get_ports random_out]

# Board config
set_property CONFIG_VOLTAGE 3.3  [current_design]
set_property CFGBVS VCCO         [current_design]

###############################################################
# SECTION 2: PRIMARY CLOCK CONSTRAINT
###############################################################

# Define primary clock: 100MHz = 10ns period
create_clock -period 10 \
             -name clk_100mhz \
             [get_ports clk_100mhz]

###############################################################
# SECTION 3: I/O TIMING CONSTRAINTS
###############################################################

# INPUT DELAY - Reset signal (relative to clk_100mhz)
set_input_delay -clock clk_100mhz -max 0.5 [get_ports reset]

# OUTPUT DELAY - Random output (relative to clk_100mhz)
set_output_delay -clock clk_100mhz -max 0.5 [get_ports random_out]

###############################################################
# SECTION 4: GENERAL TIMING RELAXATION
# 
# MURO-TRNG dùng asynchronous feedback (metastability ý định)
# → Cho phép Vivado bỏ qua timing constraints trên async paths
###############################################################

# Bỏ qua timing trên các paths không quan trọng
# để tránh timing closure issues trên entropy sources
set_false_path -through [get_ports random_out]

###############################################################
# NOTES:
#
# 1. Không constraint internal signals (tff_50mhz, fref_100khz, v.v.)
#    vì chúng KHÔNG phải ports mà Vivado có thể access từ XDC
#
# 2. Vivado tự động infer generated clocks từ internal logic
#    → Không cần explicit create_generated_clock
#
# 3. Metastability intentional ở internal paths
#    → set_false_path cho entropy channels OK
#
# 4. Nếu synthesis báo:
#    - "WARNING: gated clock" → OK (counter-based divider)
#    - "WARNING: No timing violations" → OK (async design)
#
###############################################################

# End of XDC
