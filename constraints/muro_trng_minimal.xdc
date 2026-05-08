# ============================================================================
# 1. Khai báo clock ??u vào duy nh?t: 100MHz
# ============================================================================
create_clock -period 10.000 -name clk_100mhz [get_ports clk_100mhz]

# ============================================================================
# 2. False path cho t?t c? các ???ng t? clk_100mhz ??n các flop dùng clock logic
#    (Vivado s? không báo no clock n?a vì ta ?ã nói rõ: không c?n phân tích)
# ============================================================================
set_false_path -from [get_clocks clk_100mhz] -to [get_pins -hierarchical -filter {IS_CLOCK_PIN == TRUE && NAME =~ *cgen/*}]

# ============================================================================
# 3. False path cho toàn b? ???ng d? li?u gi?a các mi?n clock không ??ng b?
#    (gi?a fref_xxx, sample_clk, và clk_100mhz)
# ============================================================================
set_clock_groups -asynchronous -group [get_clocks clk_100mhz]

# ============================================================================
# 4. ??m b?o sample_clk ???c coi nh? clock (n?u nó là output c?a ADPLL)
#    Không c?n create_generated_clock, ch? c?n b? qua timing v?i nó.
#    Tuy nhiên, ?? tránh warning "no clock" trên các flop dùng sample_clk,
#    ta dùng l?nh: set_false_path -to [get_pins -of_objects [get_nets sample_clk] -filter {IS_CLOCK_PIN == TRUE}]
# ============================================================================
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *sample_clk* && IS_CLOCK_PIN == TRUE}]

# ============================================================================
# 5. N?u v?n còn warning v?i các flop trong adpll_ring_osc (ví d? ro1/dco_inst/dfg_q_reg/C)
#    B?n có th? false path toàn b? các flop có ch?a "dco_inst" ho?c "kc".
# ============================================================================
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *dco_inst/* && IS_CLOCK_PIN == TRUE}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *kc/* && IS_CLOCK_PIN == TRUE}]

# ============================================================================
# 6. Output random_out (n?u ch?a dùng thì không c?n ràng bu?c, ho?c set false)
# ============================================================================
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -hierarchical -filter {NAME =~ *random_out*}]