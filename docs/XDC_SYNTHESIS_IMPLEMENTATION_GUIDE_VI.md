# HƯỚNG DẪN SYNTHESIS & IMPLEMENTATION TRÊN VIVADO
## Với MURO-TRNG Constraints File

---

## 📋 MỤC LỤC
1. Hiểu rõ file .xdc
2. Chuẩn bị project Vivado
3. Synthesis & Implementation
4. Debug Timing Issues
5. Pre-FPGA Deployment

---

## 1️⃣ GIẢI THÍCH CHI TIẾT FILE .XDC

### 1.1 File .xdc là gì?

`.xdc` = **Xilinx Design Constraints** file
- Là một TCL script được Vivado đọc trong synthesis và implementation
- Định nghĩa:
  - **Physical constraints**: Chân I/O vật lý (PACKAGE_PIN)
  - **Timing constraints**: Giới hạn thời gian (clock, delays, false paths)
  - **Design rules**: ASYNC_REG, ALLOW_COMBINATORIAL_LOOPS, v.v.

### 1.2 Cấu trúc file muro_trng_final.xdc

```
SECTION 1: Physical Constraints
   ├─ [1.1] Input Clock 100MHz (pin Y9)
   ├─ [1.2] Reset Input (pin K18)
   ├─ [1.3] Random Output (pin M15)
   └─ [1.4] Board Config (LVCMOS33, 3.3V)

SECTION 2: Primary Clock
   └─ Định nghĩa clk_100mhz period = 10ns

SECTION 3: Generated Clocks - T-FF Chain
   ├─ 100MHz → 50MHz (T-FF stage 1)
   ├─ 50MHz → 25MHz (T-FF stage 2)
   ├─ 25MHz → 12.5MHz (T-FF stage 3)
   └─ 12.5MHz → 6.25MHz (T-FF stage 4)

SECTION 4: Generated Clocks - Counter Dividers
   ├─ fref_100k, 200k, ..., 1000k Hz (RO references)
   └─ k_dco_clk_ro1 ~ ro10 (8×fref mỗi RO)

SECTION 5: False Paths - Metastability Ý Định
   ├─ DCO feedback → Synchronizers
   └─ CDC paths (ADPLL DCO → Sample logic)

SECTION 6: I/O Timing
   ├─ Input delay (reset)
   └─ Output delay (random_out)

SECTION 7: Additional (optional)
   ├─ ASYNC_REG (Metastability hardening)
   ├─ ALLOW_COMBINATORIAL_LOOPS
   └─ MAXDELAY (CDC timing checks)
```

### 1.3 Lý thuyết: Tại sao cần False Paths?

```
TRNG Entropy Sources:
├─ Ring Oscillators (10 sources)
│  ├─ Tần số cao (~5MHz-8MHz after DCO)
│  ├─ Asynchronous → Jitter tự nhiên
│  └─ Feedback từ DCO (asynchronous)
│
├─ Conventional ADPLL
│  ├─ Tạo sampling clock
│  └─ DCO output → Async feedback
│
└─ Metastability Windows
   ├─ Khi async signal đi vào DFF ngay rising edge
   ├─ DFF output có thể settle giữa 0 và 1 (metastability)
   └─ Thời gian settle tùy thuộc vào setup/hold margins

VIVADO DEFAULT:
├─ Muốn timing closure trên TẤT CẢ paths
├─ Báo error nếu setup/hold violated
└─ Nhưng TRNG cần metastability → muốn set_false_path

SOLUTION:
├─ set_false_path → "Vivado ơi, bỏ qua path này không cần timing check"
├─ Vivado → OK, skip timing analysis ở đây
└─ DCO → Async feedback → Jitter → Entropy ✓
```

### 1.4 Các Constraint Chính

| Constraint | Mục đích | Ví dụ |
|-----------|---------|-------|
| `set_property PACKAGE_PIN` | Nói pin vật lý | Y9 = clock input |
| `create_clock` | Định clock chính | 100MHz period=10ns |
| `create_generated_clock` | Định generated clocks | 25MHz từ T-FF chia 4 lần |
| `set_false_path` | Bỏ qua timing check | DCO feedback paths |
| `set_input_delay` | Delay tín hiệu vào | Reset có delay 0.5ns |
| `set_output_delay` | Delay tín hiệu ra | Output có delay 0.5ns |
| `set_property ASYNC_REG` | Hardening metastability | sync_dff registers |

---

## 2️⃣ CHUẨN BỊ PROJECT VIVADO

### Step 2.1: Tạo Vivado Project Mới

```tcl
# Trong Vivado TCL Console:

# Tạo project
create_project muro_trng ~/vivado_workspace -part xc7z020dg484-1 -force

# Nếu muốn tạo từ GUI:
# File → New Project → 
#   Project name: muro_trng
#   Location: C:\vivado_workspace\
#   Device: Zynq-7020 (xc7z020dg484-1)
```

### Step 2.2: Thêm RTL Files

1. **Phương pháp 1: GUI (khuyến khích cho lần đầu)**
   ```
   Vivado → Project Manager → Add Files
   ├─ rtl/muro_trng_top.v
   ├─ rtl/clock_gen.v
   ├─ rtl/adpll_ring_osc.v
   ├─ rtl/conventional_adpll.v
   ├─ rtl/dco.v
   ├─ rtl/divide_by_2_sync.v
   ├─ rtl/divide_by_2.v
   ├─ rtl/k_counter.v
   ├─ rtl/phase_detector.v
   └─ rtl/xor_corrector.v
   ```

2. **Phương pháp 2: TCL Script**
   ```tcl
   add_files -fileset sources_1 \
       {rtl/muro_trng_top.v \
        rtl/clock_gen.v \
        rtl/adpll_ring_osc.v \
        ...}
   ```

### Step 2.3: Thêm Constraints File

```
Vivado → Project Manager → Add Files → muro_trng_final.xdc
├─ Chọn "Constraints fileset"
└─ Vivado sẽ load tự động trong Synthesis & Implementation
```

**Lưu ý**: Nếu board của bạn KHÁC Zynq-7020 hoặc khác pinout:
- Mở file board schematic (SCH)
- Tìm các pin khác cho clock/reset/output
- Update PACKAGE_PIN trong .xdc file

### Step 2.4: Kiểm Tra Constraint Loading

```
Vivado → Constraints → 
├─ Xem danh sách constraints
└─ Verify muro_trng_final.xdc được load
```

---

## 3️⃣ SYNTHESIS & IMPLEMENTATION

### Step 3.1: Synthesis

```
Flow:
├─ Right-click "Generate HDL" → Synthesis
│  └─ Hoặc: Tasks → Run Synthesis
│
├─ Vivado:
│  ├─ Đọc RTL files (.v)
│  ├─ Đọc Constraints (.xdc)
│  ├─ Phân tích logic
│  ├─ Tối ưu (optimization)
│  └─ Output: Netlist (.edn) + XilinxISE format
│
└─ Kết quả:
   ├─ Synthesis Complete ✓
   ├─ Synthesized RTL = Design Summary
   └─ Warning/Error log → xsim.log
```

**Nếu có ERROR:**

| Error | Nguyên nhân | Cách fix |
|-------|-----------|---------|
| `HDL PARSING ERROR` | Syntax sai trong .v | Kiểm tra RTL syntax |
| `CONSTRAINT ERROR` | XDC constraint sai | Fix PACKAGE_PIN, syntax |
| `UNBOUND CONSTRAINT` | Pin không tồn tại | Verify port name trong RTL |
| `UNRESOLVED REFERENCE` | Module không tìm thấy | Thêm file vào project |

### Step 3.2: Implementation

```
Flow:
├─ Run Implementation
│  ├─ Place & Route
│  └─ Generate bitstream
│
├─ Substeps:
│  ├─ [1] Opt Design (tiếp tục optimization)
│  ├─ [2] Place Design (đặt logic lên FPGA)
│  ├─ [3] Route Design (kết nối wires)
│  └─ [4] Generate Bitstream (file .bit để lập trình)
│
└─ Output:
   ├─ Design Complete ✓
   ├─ bitstream: muro_trng.bit
   ├─ Report: utilization.txt, timing_summary.txt
   └─ Errors/Warnings → impl_1/runme.log
```

### Step 3.3: Kiểm Tra Timing Report

Sau Implementation hoàn tất:

```
Vivado → Timing → Timing Summary
├─ Setup check: Slack ≥ 0 (good) hoặc < 0 (bad)
├─ Hold check: Slack ≥ 0 (good) hoặc < 0 (bad)
├─ Path details:
│  ├─ Source/Destination
│  ├─ Delay (ns)
│  └─ Slack (ns) = Required - Actual
│
└─ Kết luận:
   ├─ Slack ≥ 0 → Timing OK ✓
   ├─ Slack < 0 → Violation! Cần điều chỉnh
   └─ Với TRNG: Có thể accept negative slack trên false_path
```

**Đọc Timing Report:**

```
Setup slack = Required time - Actual delay

Ví dụ:
  Source: cadpll/dco_inst/Q (DCO output)
  Destination: muro_trng_top/sample_clk (input)
  Delay: 3.45 ns
  Required: 10.0 ns (1 clock period)
  Slack: 10.0 - 3.45 = 6.55 ns ✓ (positive = good)

Nhưng nếu có:
  Slack: 10.0 - 12.34 = -2.34 ns ✗ (negative = bad)
  → Nhưng này set_false_path → bỏ qua
```

---

## 4️⃣ DEBUG TIMING ISSUES

### Vấn đề 4.1: Setup Violation

```
Nguyên nhân:
├─ Combinatorial delay quá lớn
├─ Clock period quá ngắn
├─ Routing delay quá lớn
└─ Chậm implementation placement

Cách fix:
├─ Option 1: Giảm frequency (tăng clock period)
├─ Option 2: Thêm pipeline stages (pipelining)
├─ Option 3: Tối ưu combinatorial logic
├─ Option 4: set_false_path nếu không quan trọng
└─ Option 5: Điều chỉnh placement (Manual floor-planning)
```

### Vấn đề 4.2: Hold Violation

```
Nguyên nhân:
├─ Quá ít delay từ source đến DFF
├─ Timing path quá ngắn
└─ Routing tối ưu quá nhiều

Cách fix:
├─ Option 1: Thêm delay constraints (MAXDELAY)
├─ Option 2: Thêm buffer cells (BUFR, BUFG)
├─ Option 3: set_max_delay nếu cần kiểm soát
└─ Option 4: Điều chỉnh implementation settings
```

### Vấn đề 4.3: Gated Clock Warnings

```
Warning: Found gated clock on signal 'fref_100khz'

Nguyên nhân:
├─ Counter CE tạo gated clock (clock enable từ logic)
├─ Vivado muốn all clocks từ global clock tree
└─ Nhưng TRNG dùng CE → gated logic bình thường

Cách fix:
├─ Option 1: Bỏ qua (TRNG hoạt động đúng)
├─ Option 2: Thêm BUFG/CE constraint
└─ Option 3: Dùng PLL thay vì counter (phức tạp hơn)
```

---

## 5️⃣ PRE-FPGA DEPLOYMENT CHECKLIST

### ✅ Trước khi lập trình FPGA

- [ ] **Synthesis**
  - Synthesis Complete ✓
  - Errors = 0
  - Warnings = có thể accept (gated clock OK)

- [ ] **Implementation**
  - Place & Route Complete ✓
  - Routed = 100% (không có unrouted signals)
  - Errors = 0

- [ ] **Timing Closure**
  - Setup violations = 0 (hoặc set_false_path)
  - Hold violations = 0 (hoặc set_false_path)
  - Timing Summary → Review

- [ ] **Resource Utilization**
  ```
  Dự kiến MURO-TRNG:
  ├─ LUTs: ~2000-3000 (< 53,200 available)
  ├─ Registers: ~1500-2000
  ├─ BRAM: ~0-1
  └─ DSP: ~0
  ```

- [ ] **Bitstream Generation**
  - Generate Bitstream ✓
  - Output: muro_trng.bit (ready to program)

- [ ] **Constraints Verification**
  - Muro_trng_final.xdc loaded ✓
  - Pin locations verified ✓
  - No unbound constraints ✓

### 📝 Lập trình FPGA

```
Hardware:
├─ JTAG cable (Xilinx USB-JTAG hoặc tương tự)
├─ Zynq-7020 board (powered on)
└─ Máy tính + Vivado

Vivado:
├─ Program & Debug → Program → 
├─ Select bitstream: muro_trng.bit
├─ Program FPGA
└─ Status: "Programming FPGA... Done!"

Test:
├─ Monitor random_out pin (LED blinky hoặc logic analyzer)
├─ Verify output toggling ~100kHz (sau XOR corrector)
└─ Entropy test (nist, diehard, v.v.)
```

---

## 6️⃣ GẶP SỰ CỐ THƯỜNG GẶP

### ❌ "CRITICAL ERROR [PART 010-1549]"

```
Full error: 
  CRITICAL ERROR [PART 010-1549] [...] 'xc7z020dg484-1' is not found

Nguyên nhân:
├─ Vivado không có part library
├─ Part name sai hoặc không install

Fix:
├─ Check: Help → About Vivado → Device Support
├─ Hoặc: Download Design Edition (free) từ xilinx.com
└─ Hoặc: Tạo project với part có sẵn (ví dụ xc7z020clg484-1)
```

### ❌ "CONSTRAINT ERROR [... ]"

```
Ví dụ:
  ERROR [...] No net matched pattern 'clk_100mhz'

Nguyên nhân:
├─ Port name không khớp với RTL
├─ Typo trong XDC file
└─ Port không export từ top module

Fix:
├─ RTL muro_trng_top: check port name = "clk_100mhz" ✓
├─ XDC: verify [get_ports clk_100mhz]
└─ Synthesis: xem Port List → verify
```

### ❌ Route có "Unrouted signals"

```
Nguyên nhân:
├─ Logic quá dense → tidak place được
├─ Timing constraint quá chặt
└─ Resource tính toán sai

Fix:
├─ Optimize constraints
├─ Thêm pipelining
└─ Hoặc giảm feature
```

---

## 7️⃣ TỔNG KẾT QUYTRÌNH

```
┌─────────────────────────────────────────────────────────┐
│ Step 1: Tạo Vivado Project                              │
│   - Device: xc7z020dg484-1                              │
│   - Add RTL files (muro_trng_top + dependencies)        │
│   - Add Constraints: muro_trng_final.xdc                │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│ Step 2: Synthesis                                        │
│   - Run → Synthesis                                      │
│   - Verify: No errors, Warnings OK                       │
│   - Output: Netlist                                      │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│ Step 3: Implementation (Place & Route)                   │
│   - Run → Implementation                                 │
│   - Substeps: Opt, Place, Route, Generate Bitstream     │
│   - Verify: No routing errors                           │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│ Step 4: Timing Analysis                                  │
│   - Check: Timing Summary                               │
│   - Verify: Setup/Hold slack ≥ 0 (or set_false_path)   │
│   - Review: Utilization report                          │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│ Step 5: Program FPGA                                    │
│   - Generate bitstream: muro_trng.bit                    │
│   - Program via JTAG                                     │
│   - Verify: Output working                              │
└─────────────────────────────────────────────────────────┘
```

---

## 📚 THAM KHẢO THÊM

1. **Xilinx UG903**: Design Constraints User Guide
   - https://docs.xilinx.com/

2. **Paper**: "MURO-TRNG: Multi-Oscillator RO-TRNG"
   - IEEE Access 2025 (Meitei & Kumar)

3. **Vivado Docs**:
   - `create_clock` command
   - `create_generated_clock` command
   - `set_false_path` command

4. **Tools hữu ích**:
   - Vivado Timing Analyzer (built-in)
   - Static timing analysis (STA)
   - Logic analyzer (debugging)

---

## 🎓 PHẦN EXTRA: Nếu muốn sử dụng PLL

Nếu bạn muốn sử dụng PLL thay vì counter dividers (để có tần số chính xác hơn):

```tcl
# Tạo PLL IP (Clocking Wizard)
# Vivado → IP Catalog → Clocking Wizard
# 
# Cấu hình:
# Input: 100 MHz
# Outputs:
#   - clk_out1: 400 MHz (K/DCO clocks)
#   - clk_out2: 25 MHz (fref)
#   - clk_out3: 12.5 MHz (fref alt)
#   - clk_out4: 6.25 MHz (fref alt)
#
# Constraints:
#   create_generated_clock -name pll_400mhz \
#       -source [get_pins clk_wiz_0_inst/clk_out1] \
#       [get_pins clk_wiz_0_inst/clk_out1]
```

---

**Tài liệu này được viết cho MURO-TRNG project**  
**Cập nhật: 2026-05-08**
