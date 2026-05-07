`timescale 1ns / 1ps

// =============================================================================
// TESTBENCH: tb_muro_trng_top.v
// Chức năng: Mô phỏng toàn bộ hệ thống MURO-TRNG
//            Tạo ra file random_bits.txt để test NIST
// =============================================================================

module tb_muro_trng_top;

    // =========================================================================
    // Tín hiệu
    // =========================================================================
    reg clk_100mhz;
    reg reset;
    wire random_out;
    
    // =========================================================================
    // Instance MURO-TRNG TOP
    // =========================================================================
    muro_trng_top dut (
        .clk_100mhz(clk_100mhz),
        .reset(reset),
        .random_out(random_out)
    );
    
    // =========================================================================
    // Clock Generator (100MHz, chu kỳ 10ns)
    // =========================================================================
    initial begin
        clk_100mhz = 0;
        forever #5 clk_100mhz = ~clk_100mhz;
    end
    
    // =========================================================================
    // File output để lưu bit ngẫu nhiên
    // =========================================================================
    integer file_handle;
    integer bit_count;
    
    // =========================================================================
    // Test sequence
    // =========================================================================
    initial begin
        // Mở file để ghi
        file_handle = $fopen("random_bits.txt", "w");
        if (file_handle == 0) begin
            $display("[ERROR] Cannot open file random_bits.txt");
            $finish;
        end
        
        // Khởi tạo
        reset = 1;
        bit_count = 0;
        
        $display("========================================");
        $display("  MURO-TRNG SIMULATION");
        $display("========================================");
        $display("Clock: 100MHz (10ns period)");
        $display("Generating random bits...");
        $display("");
        
        // Reset trong 100ns
        #100;
        reset = 0;
        $display("Time=%0t ns: Reset released", $time);
        
        // Chờ hệ thống ổn định (PLL khóa)
        #10000;  // 10us
        $display("Time=%0t ns: System stable, start sampling...", $time);
        $display("");
        
        // Thu thập bit ngẫu nhiên
        // Mỗi bit được lấy mẫu tại cạnh lên của sample_clk
        // sample_clk = 200MHz (chu kỳ 5ns) sau khi chia 2 từ 400MHz
        
        repeat(1000000) begin
            @(posedge dut.sample_clk);
            bit_count = bit_count + 1;
            $fwrite(file_handle, "%b", random_out);
            
            // In ra mỗi 100 bit
            if (bit_count % 100 == 0) begin
                $display("Collected %d bits", bit_count);
            end
        end
        
        $fclose(file_handle);
        
        $display("");
        $display("========================================");
        $display("  SIMULATION COMPLETE!");
        $display("========================================");
        $display("Total bits generated: %d", bit_count);
        $display("Output file: random_bits.txt");
        $display("");
        
        // Kết thúc
        #1000;
        $finish;
    end
    
    // =========================================================================
    // Monitor (in ra console mỗi khi có bit mới - giới hạn 100 bit đầu)
    // =========================================================================
    integer print_count = 0;
    
    always @(posedge dut.sample_clk) begin
        if (!reset) begin
            if (print_count < 100) begin
                $display("Bit[%0d]: raw=%b, processed=%b, ro_out=%b_%b_%b_%b_%b_%b_%b_%b_%b_%b, adpll=%b", 
                    print_count, dut.raw_bit, random_out, 
                    dut.ro_outputs[0], dut.ro_outputs[1], dut.ro_outputs[2], dut.ro_outputs[3], dut.ro_outputs[4],
                    dut.ro_outputs[5], dut.ro_outputs[6], dut.ro_outputs[7], dut.ro_outputs[8], dut.ro_outputs[9],
                    dut.adpll_idout);
                print_count = print_count + 1;
            end
        end
    end
    
    // =========================================================================
    // Waveform dump
    // =========================================================================
    initial begin
        $dumpfile("dump_muro_trng.vcd");
        $dumpvars(0, tb_muro_trng_top);
        $dumpvars(1, dut.sample_clk);
        $dumpvars(1, dut.random_out);
        $dumpvars(1, dut.raw_bit);
    end

endmodule