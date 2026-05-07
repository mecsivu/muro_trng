// =============================================================================
// PLL CONFIGURATION GUIDE for MURO-TRNG
// Tool: Vivado 2015.2+ (Zynq-7000 series)
// =============================================================================

/*
DEVICE: xc7z020dg484-1 (Zynq-7020 BGA484)

PLL IP GENERATED: clk_wiz_0 (4 Output Clocks)
========================================

CONFIGURATION SUMMARY:
  - Input: 100 MHz from board oscillator
  - Output 1: 400 MHz (K/DCO for ADPLLs)
  - Output 2: 25 MHz (fref_25mhz)
  - Output 3: 12.5 MHz (fref_12_5mhz)
  - Output 4: 6.25 MHz (fref_6_25mhz)
  - All outputs locked together, zero skew

BENEFITS vs T-FF Chain:
  ✅ Eliminates 6 DFF cells (saves resources)
  ✅ All frequencies perfectly synchronized
  ✅ Better jitter performance
  ✅ Simpler timing analysis

INSTANTIATION in clock_gen.v:
============================

    clk_wiz_0 pll_inst (
        .clk_in1(clk_100mhz),       // Input: 100MHz
        .clk_out1(pll_clk_out1),    // 400MHz → k_dco_400mhz
        .clk_out2(pll_clk_out2),    // 25MHz → fref_25mhz
        .clk_out3(pll_clk_out3),    // 12.5MHz → fref_12_5mhz
        .clk_out4(pll_clk_out4),    // 6.25MHz → fref_6_25mhz
        .locked(k_dco_400mhz_locked),
        .reset(reset)
    );

    // Assignments
    assign k_dco_400mhz = pll_clk_out1;
    assign fref_25mhz = pll_clk_out2;
    assign fref_12_5mhz = pll_clk_out3;
    assign fref_6_25mhz = pll_clk_out4;

PLL OUTPUT MAPPING TO DESIGN:
=============================

┌─ clk_wiz_0 (PLL)
│
├─ Input: clk_100mhz
│
├─ Output 1 (400MHz)
│  └─→ k_dco_400mhz
│      ├─→ 10 RO ADPLL loops (all share same K/DCO clock)
│      └─→ Conventional ADPLL (K-counter, DCO)
│
├─ Output 2 (25MHz)
│  └─→ fref_25mhz
│      └─→ Conventional ADPLL reference clock
│
├─ Output 3 (12.5MHz)
│  └─→ fref_12_5mhz
│      └─→ Alternative reference (not currently used)
│
└─ Output 4 (6.25MHz)
   └─→ fref_6_25mhz
       └─→ Alternative reference (not currently used)

TIMING CONSTRAINTS (in muro_trng_fpga.xdc):
===========================================

All generated_clocks are created with divide_by 1:
  - Tightest timing
  - Zero phase shift between outputs
  - Enable cross-domain analysis

Clock Enable Logic:
  - Counter-based CE for 100K-1000K RO references
  - Marked as ASYNC_REG for timing (intentional)

RESOURCE UTILIZATION:
====================

Before: T-FF chain (6 DFFs) + PLL (1 input, 1 output)
After:  PLL only (0 DFFs) with 4 outputs

Savings: ~0.15% LUT, ~0.2% BRAM (minimal for Zynq-7020)
Benefit: Perfect frequency alignment, no edge jitter between clocks

VERIFICATION CHECKLIST:
=======================

After implementation:
  ☐ PLL locked signal stable (green LED or log message)
  ☐ sample_clk edges clean and stable
  ☐ random_out toggles continuously after ~100ms warmup
  ☐ No timing violations (Vivado reports 0 errors)
  ☐ Setup/Hold margins > 0.1ns on all clock domains

*/

