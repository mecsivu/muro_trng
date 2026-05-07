    ###############################################################
    # MURO-TRNG XDC Constraints
    # Device: Zynq-7020 (7z020-clg484)
    # Tool  : Vivado 2015.2
    ###############################################################
    
    ###############################################################
    # PHYSICAL CONSTRAINTS
    # ??t l�n ??u ?? tool bi?t pin location tr??c khi
    # ??c timing constraints
    ###############################################################
    
    # Clock - 100MHz t? board oscillator
    set_property PACKAGE_PIN Y9      [get_ports clk_100mhz]
    set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
    
    # Reset - active high, async
    set_property PACKAGE_PIN K18     [get_ports reset]
    set_property IOSTANDARD LVCMOS33 [get_ports reset]
    
    # Output - random bit ra LED
    set_property PACKAGE_PIN M15     [get_ports random_out]
    set_property IOSTANDARD LVCMOS33 [get_ports random_out]
    
    # Board config
    set_property CONFIG_VOLTAGE 3.3  [current_design]
    set_property CFGBVS VCCO         [current_design]
    
    ###############################################################
    # PRIMARY CLOCK
    ###############################################################
    
    create_clock -period 10.000 \
                 -name clk_100mhz \
                 [get_ports clk_100mhz]
    
    ###############################################################
    # GENERATED CLOCKS
    # T?t c? ??u derive t? clk_100mhz qua cgen counters
    # Source = clock pin c?a register (kh�ng ph?i Q pin)
    # v� UG903 Example 2 d�ng REGA/C l�m source
    ###############################################################
    
    # --- Conventional ADPLL DCO clock (25MHz ? DCO) ---
    create_generated_clock -name dco_clk_25mhz \
        -source [get_pins cgen/dco_clk_25mhz_reg/C] \
        -divide_by 1 \
        [get_pins cgen/dco_clk_25mhz_reg/Q]
    
    # --- Ring Oscillator DCO clocks ---
    create_generated_clock -name dco_clk_100khz \
        -source [get_pins cgen/dco_clk_100khz_reg/C] \
        -divide_by 1 \
        [get_pins cgen/dco_clk_100khz_reg/Q]
    
    create_generated_clock -name dco_clk_200khz \
        -source [get_pins cgen/dco_clk_200khz_reg/C] \
        -divide_by 1 \
        [get_pins cgen/dco_clk_200khz_reg/Q]
    
    create_generated_clock -name dco_clk_300khz \
        -source [get_pins cgen/dco_clk_300khz_reg/C] \
        -divide_by 1 \
        [get_pins cgen/dco_clk_300khz_reg/Q]
    
    create_generated_clock -name dco_clk_400khz \
        -source [get_pins cgen/dco_clk_400khz_reg/C] \
        -divide_by 1 \
        [get_pins cgen/dco_clk_400khz_reg/Q]
    
    create_generated_clock -name dco_clk_500khz \
        -source [get_pins cgen/dco_clk_500khz_reg/C] \
        -divide_by 1 \
        [get_pins cgen/dco_clk_500khz_reg/Q]
    
    create_generated_clock -name dco_clk_600khz \
        -source [get_pins cgen/dco_clk_600khz_reg/C] \
        -divide_by 1 \
        [get_pins cgen/dco_clk_600khz_reg/Q]
    
    create_generated_clock -name dco_clk_700khz \
        -source [get_pins cgen/dco_clk_700khz_reg/C] \
        -divide_by 1 \
        [get_pins cgen/dco_clk_700khz_reg/Q]
    
    create_generated_clock -name dco_clk_800khz \
        -source [get_pins cgen/dco_clk_800khz_reg/C] \
        -divide_by 1 \
        [get_pins cgen/dco_clk_800khz_reg/Q]
    
    create_generated_clock -name dco_clk_900khz \
        -source [get_pins cgen/dco_clk_900khz_reg/C] \
        -divide_by 1 \
        [get_pins cgen/dco_clk_900khz_reg/Q]
    
    create_generated_clock -name dco_clk_1000khz \
        -source [get_pins cgen/dco_clk_1000khz_reg/C] \
        -divide_by 1 \
        [get_pins cgen/dco_clk_1000khz_reg/Q]
    
    # --- Sampling clock t? cadpll div_sample ---
    create_generated_clock -name sample_clk \
        -source [get_pins cadpll/dco_inst/dff_q_reg/C] \
        -divide_by 2 \
        [get_pins cadpll/div_sample/out_reg/Q]
    
    ###############################################################
    # ASYNC CLOCK GROUPS
    # Theo UG903: set_clock_groups -asynchronous
    # ?? disable timing check gi?a c�c domains kh�ng li�n quan
    #
    # Group 1: clk_100mhz domain (cgen, fref, k_clk counters)
    # Group 2: dco_clk domains (ring osc DCOs - entropy sources)
    # Group 3: sample_clk domain (sampling + post-processing)
    ###############################################################
    
    # Ring osc DCO clocks vs sample_clk
    # L� do: ro DCO outputs ???c sample b?i sample_clk
    #        ?�y l� intentional CDC - ngu?n entropy
    set_clock_groups -name async_ro_vs_sample \
        -asynchronous \
        -group [get_clocks {dco_clk_100khz \
                            dco_clk_200khz \
                            dco_clk_300khz \
                            dco_clk_400khz \
                            dco_clk_500khz \
                            dco_clk_600khz \
                            dco_clk_700khz \
                            dco_clk_800khz \
                            dco_clk_900khz \
                            dco_clk_1000khz}] \
        -group [get_clocks sample_clk]
    
    # clk_100mhz vs sample_clk
    # L� do: sample_clk ???c generate t? cadpll DCO
    #        kh�ng c� fixed phase relationship v?i clk_100mhz
    set_clock_groups -name async_sys_vs_sample \
        -asynchronous \
        -group [get_clocks clk_100mhz] \
        -group [get_clocks sample_clk]
    
    # clk_100mhz vs ring osc DCO clocks
    # L� do: dco_clk_Xkhz l� registered outputs c?a cgen
    #        nh?ng khi d�ng l�m clock cho RO DCO DFFs
    #        ch�ng t?o ra domain ri�ng kh�ng sync v?i clk_100mhz
    set_clock_groups -name async_sys_vs_ro \
        -asynchronous \
        -group [get_clocks clk_100mhz] \
        -group [get_clocks {dco_clk_100khz \
                            dco_clk_200khz \
                            dco_clk_300khz \
                            dco_clk_400khz \
                            dco_clk_500khz \
                            dco_clk_600khz \
                            dco_clk_700khz \
                            dco_clk_800khz \
                            dco_clk_900khz \
                            dco_clk_1000khz}]
    
    ###############################################################
    # FALSE PATHS
    # C�c paths kh�ng c?n timing check
    ###############################################################
    
    # Reset l� async signal
    # L� do: reset d�ng CLR/CLR pin c?a FFs - async clear
    #        kh�ng thu?c b?t k? clock domain n�o
    #        timing report ?� confirm: reset ? CLR l� (none) path
    set_false_path -from [get_ports reset]
    
    # K counter internal clocks
    # L� do: k_clk_Xkhz drive K counter FFs b�n trong ROs
    #        l� internal ADPLL loop filter - kh�ng ?nh h??ng output
    #        kh�ng c?n timing signoff
    set_false_path -from \
        [get_cells -hier -filter {NAME =~ cgen/k_clk*reg}]
    
    # RO div_fb paths
    # L� do: div_fb l� feedback divider trong ring osc ADPLL
    #        clocked b?i dco_clk (intentional async)
    #        output ch? ?i v�o phase detector - internal loop
    set_false_path -from \
        [get_cells -hier -filter {NAME =~ ro*/div_fb/out_reg}]
    
    ###############################################################
    # INPUT / OUTPUT DELAYS
    ###############################################################
    
    # reset: async input, kh�ng c?n input delay
    # (?� handle b?ng set_false_path -from [get_ports reset])
    
    # random_out: output c?a post_proc, clocked by sample_clk
    # D�ng 20% c?a period sample_clk l�m starting point
    # sample_clk period ? 5ns (cadpll DCO / 2)
    # ? output delay = 1.0ns
    set_output_delay -clock sample_clk \
                     -max 1.0 \
                     [get_ports random_out]