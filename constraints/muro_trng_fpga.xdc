###############################################################
# MURO-TRNG XDC Constraints (FPGA with PLL 4-Outputs)
# Device: Zynq-7020 (xc7z020dg484-1)
# Tool  : Vivado 2015.2+
# Updated for: PLL 4-output configuration
###############################################################

###############################################################
# PHYSICAL CONSTRAINTS
###############################################################

# Clock - 100MHz from board oscillator
set_property PACKAGE_PIN Y9      [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]

# Reset - active high, async
set_property PACKAGE_PIN K18     [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# Output - random bit to LED
set_property PACKAGE_PIN M15     [get_ports random_out]
set_property IOSTANDARD LVCMOS33 [get_ports random_out]

# Board config
set_property CONFIG_VOLTAGE 3.3  [current_design]
set_property CFGBVS VCCO         [current_design]

###############################################################
# PRIMARY CLOCK CONSTRAINT
###############################################################

create_clock -period 10.000 \
             -name clk_100mhz \
             [get_ports clk_100mhz]

###############################################################
# PLL OUTPUT CLOCKS (4 synchronized outputs from clk_wiz_0)
###############################################################

# clk_out1: 400 MHz (K/DCO clock for ADPLLs)
create_generated_clock -name k_dco_400mhz \
    -source [get_pins cgen/pll_inst/clk_out1] \
    -divide_by 1 \
    [get_pins cgen/pll_inst/clk_out1]

# clk_out2: 25 MHz (fref_25mhz for Conventional ADPLL)
create_generated_clock -name fref_25mhz \
    -source [get_pins cgen/pll_inst/clk_out2] \
    -divide_by 1 \
    [get_pins cgen/pll_inst/clk_out2]

# clk_out3: 12.5 MHz (fref_12_5mhz alternative)
create_generated_clock -name fref_12_5mhz \
    -source [get_pins cgen/pll_inst/clk_out3] \
    -divide_by 1 \
    [get_pins cgen/pll_inst/clk_out3]

# clk_out4: 6.25 MHz (fref_6_25mhz alternative)
create_generated_clock -name fref_6_25mhz \
    -source [get_pins cgen/pll_inst/clk_out4] \
    -divide_by 1 \
    [get_pins cgen/pll_inst/clk_out4]

# PLL Lock signal (status only, not timing)
set_false_path -from [get_pins cgen/pll_inst/locked]

###############################################################
# COUNTER-GENERATED CLOCKS (100K-1000K via CE logic)
###############################################################

# These are data signals (clock enable pulses), not real clocks
# Constraint them as async logic (no timing closure required)

set_property ASYNC_REG TRUE [get_cells {cgen/cnt_100khz_*}]
set_property ASYNC_REG TRUE [get_cells {cgen/cnt_200khz_*}]
set_property ASYNC_REG TRUE [get_cells {cgen/cnt_300khz_*}]
set_property ASYNC_REG TRUE [get_cells {cgen/cnt_400khz_*}]
set_property ASYNC_REG TRUE [get_cells {cgen/cnt_500khz_*}]
set_property ASYNC_REG TRUE [get_cells {cgen/cnt_600khz_*}]
set_property ASYNC_REG TRUE [get_cells {cgen/cnt_700khz_*}]
set_property ASYNC_REG TRUE [get_cells {cgen/cnt_800khz_*}]
set_property ASYNC_REG TRUE [get_cells {cgen/cnt_900khz_*}]
set_property ASYNC_REG TRUE [get_cells {cgen/cnt_1000khz_*}]

###############################################################
# TIMING EXCEPTIONS
###############################################################

# Allow metastability on feedback paths (intentional for entropy)
set_false_path -through [get_pins */divide_by_2_sync/async_in]

# CDC: Async clock domain crossing (from DCO to sync logic)
set_false_path -from [get_cells {cadpll/dco_inst/dff_q}] \
               -to [get_cells {cadpll/div_sample/sync1}]

set_false_path -from [get_cells {ro*/dco_inst/dff_q}] \
               -to [get_cells {ro*/div_fb/sync1}]

###############################################################
# I/O TIMING
###############################################################

# Output can be slow (entropy is statistical, not timing-critical)
set_property SLEW SLOW [get_ports random_out]
set_property DRIVE 12 [get_ports random_out]

###############################################################
# OPTIMIZATION
###############################################################

# Keep hierarchy for debugging
set_property KEEP_HIERARCHY TRUE [get_cells cgen]
set_property KEEP_HIERARCHY TRUE [get_cells cadpll]

# Prevent optimization of ADPLL loops
set_property DONT_TOUCH TRUE [get_cells {ro*}]
set_property DONT_TOUCH TRUE [get_cells cadpll]
