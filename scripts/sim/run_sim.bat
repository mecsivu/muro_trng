@echo off
iverilog -o sim_out ^
  rtl/dco.v ^
  rtl/phase_detector.v ^
  rtl/k_counter.v ^
  rtl/divider.v ^
  rtl/clock_gen.v ^
  rtl/xor_corrector.v ^
  rtl/adpll_ring_osc.v ^
  rtl/conventional_adpll.v ^
  rtl/muro_trng_top.v ^
  tb/tb_muro_trng.v

vvp sim_out
gtkwave dump.vcd