# 🔍 BÁO CÁO KIỂM CHỨNG RTL - MURO-TRNG IMPLEMENTATION

**Người phân tích:** AI Expert (>10 years FPGA experience)  
**Ngày:** 8 May 2026  
**Dự án:** Khóa luận tốt nghiệp - MURO-TRNG (Paper: IEEE Access 2025 - Meitei & Kumar)

---

## 📋 MỤC LỤC

1. [Sơ lược Paper & Thiết kế](#sơ-lược-paper--thiết-kế)
2. [Phân tích Code Hiện tại](#phân-tích-code-hiện-tại)
3. [Các Vấn đề Tìm Thấy](#các-vấn-đề-tìm-thấy)
4. [Hướng Dẫn Chi Tiết](#hướng-dẫn-chi-tiết-fix)
5. [So Sánh Code vs Paper](#so-sánh-code-vs-paper)
6. [Kế Hoạch Fix](#kế-hoạch-fix)

---

## 🎯 Sơ Lược Paper & Thiết kế

### Kiến Trúc Chính (Hình 1, Paper)

```
┌─────────────────────────────────────────────┐
│  10 ADPLL-based Ring Oscillators (ROs)     │
│  ├─ RO1: fref=100KHz  → idout (jittered)   │
│  ├─ RO2: fref=200KHz  → idout              │
│  ├─ ...                                      │
│  └─ RO10: fref=1000KHz → idout             │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│  11 DFFs (Sampling Circuit)                │
│  ├─ DFF1-10: lấy mẫu 10 RO outputs          │
│  ├─ DFF11: lấy mẫu Conventional ADPLL      │
│  └─ Clock: sample_clk (từ Conventional    │
│            ADPLL, chia 2 từ 25/12.5/6.25M) │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│  XOR Gate (1 bit out = XOR of 11 DFF outs) │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│  XOR Corrector (Post-Processing)            │
│  out[i] = raw_bit[i] XOR raw_bit[i-1]      │
│  → Loại bỏ bias, giảm throughput /2         │
└─────────────────────────────────────────────┘
```

### Bảng Tham Số Paper (Table 1)

```
Ring Osc | fref    | K  | M | N | K-clk    | DCO-clk
---------|---------|----|----|------|----------|----------
RO1      | 100KHz  | 4  | 8  | 4  | 800KHz   | 800KHz (2×4×100K)
RO2      | 200KHz  | 4  | 8  | 4  | 1600KHz  | 1600KHz
...      | ...     | 4  | 8  | 4  | ...      | ...
RO10     | 1000KHz | 4  | 8  | 4  | 8000KHz  | 8000KHz
```

**Cách tính:**
- K_clk = M × fref = 8 × fref
- DCO_clk = 2N × fref = 8 × fref (vì N=4)
- **Chú ý:** K_clk = DCO_clk với M=8, N=4

---

## 🔬 Phân Tích Code Hiện Tại

### [A] clock_gen.v - Sinh các tần số

#### ✅ Phần 1: T-FF Chain (Chính xác - 100%)

```
Input: clk_100mhz (100 MHz)
       ↓ (T-FF stage 1)
100M → 50M (fref_50mhz)
       ↓ (T-FF stage 2)
50M  → 25M (fref_25mhz) ✅
       ↓ (T-FF stage 3)
25M  → 12.5M (fref_12_5mhz) ✅
       ↓ (T-FF stage 4)
12.5M → 6.25M (fref_6_25mhz) ✅
```

**Đánh giá:** 
- ✅ CHÍNH XÁC TUYỆT ĐỐI (power-of-2 divisions)
- ✅ 50% duty cycle
- ✅ Hoàn toàn synchronous từ 100MHz clock

---

#### ✅ Phần 2: Counter-based Dividers (Tốt - Sai số chấp nhận được)

**Công thức:**
```
fout = 100MHz / (2 × N_toggle)
⟹ N_toggle = 100M / (2 × fout)
```

**Bảng sai số:**
```
fout        N_toggle   Thực tế        Sai số
100 KHz     500        100.000 KHz    0%        ✅
200 KHz     250        200.000 KHz    0%        ✅
300 KHz     167        299.401 KHz    -0.20%    ✅
400 KHz     125        400.000 KHz    0%        ✅
500 KHz     100        500.000 KHz    0%        ✅
600 KHz     83         602.410 KHz    +0.40%    ✅
700 KHz     71         704.225 KHz    +0.60%    ✅
800 KHz     63         793.651 KHz    -0.79%    ⚠️ (nhưng OK)
900 KHz     56         892.857 KHz    -0.79%    ⚠️ (nhưng OK)
1000 KHz    50         1000.000 kHz   0%        ✅
```

**Đánh giá:** 
- ✅ Sai số tối đa ~0.8%, CHẤP NHẬN ĐƯỢC
- ✅ Cụ thể của FPGA, không chính xác như PLL nhưng đủ cho TRNG

---

#### ⚠️ Phần 3: K/DCO Clock Generation (CHƯA HOÀN CHỈNH)

**Code trong clock_gen.v:**
```verilog
// Tính toán K_clk cho mỗi RO
// RO1:  K_clk = 8×100K = 800K   (N_toggle = 62)
// RO2:  K_clk = 8×200K = 1600K  (N_toggle = 31)
// ...
// RO10: K_clk = 8×1000K = 8000K (N_toggle = 6)

// Output: k_dco_clk_ro1 ... k_dco_clk_ro10
```

**NHƯNG muro_trng_top.v:**
```verilog
// ❌ KHÔNG dùng k_dco_clk_ro1 ... k_dco_clk_ro10

// Thay vào đó, dùng 400MHz PLL cho tất cả:
adpll_ring_osc ro1 (
    .k_clk(k_dco_400mhz),    // ← 400MHz (cố định)
    .dco_clk(k_dco_400mhz),  // ← 400MHz (cố định)
    ...
);
```

**Đánh giá:**
- ⚠️ INCONSISTENT: clock_gen.v tính toán đúng nhưng top.v không dùng
- ⚠️ Có thể hoạt động nhưng SAI SO VỚI PAPER
- ⚠️ Lãng phí resource cho PLL 400MHz khi K_clk chỉ cần 800K-8M

---

### [B] muro_trng_top.v - Kết nối Hệ thống

**Cấu trúc:**

```verilog
clock_gen → [Outputs 10 fref, 25/12.5/6.25M frequencies]
    ↓
10 adpll_ring_osc (RO1-RO10)
    ↓ [11 outputs]
11 DFFs (sampled)
    ↓
XOR Gate (1 bit output)
    ↓
xor_corrector
    ↓
random_out
```

**Issues:**

| ID  | Issue | Severity | Status |
|-----|-------|----------|--------|
| I1  | Top.v không dùng individual K/DCO clocks | ⚠️ Medium | NEEDS FIX |
| I2  | Sử dụng 400MHz PLL cho all ROs | ⚠️ Medium | WORKS but NOT OPTIMAL |
| I3  | comment nói CE signals nhưng không code | ⚠️ Low | NEEDS CLEANUP |

---

### [C] ADPLL Ring Oscillator (adpll_ring_osc.v)

**Cấu trúc:**
```
Phase Detector ──→ K-Counter ──→ DCO ──┐
    ↑                              │
    └── Divide-by-2-Sync ──────────┘
```

**Đánh giá:**
- ✅ Phase Detector: XOR (đúng)
- ✅ K-Counter: Count khi PD=1, output MSB
- ✅ DCO: NOR chain + DFF (tạo jitter từ propagation delay)
- ✅ Divide-by-2-Sync: Metastability hardening ✅
- ✅ CHÍNH XÁC

---

### [D] DCO (dco.v)

```verilog
Carry (từ K-Counter)
   ↓ (NOR gate 1)
[NOR chain × 9 stages]
   ↓ (cascade delay)
Output
   ↓ (DFF)
idout (Jittered oscillation)
```

**Jitter Sources:**
1. ✅ Propagation delay của LUT cascade (không đều)
2. ✅ Routing variability (timing uncertainty)
3. ✅ Process/temperature variation trên silicon

**Đánh giá:** ✅ CHÍNH XÁC - DCO structure đúng theo paper

---

### [E] Divide-by-2-Sync (divide_by_2_sync.v)

**Cách hoạt động:**
```
async_in (từ DCO)
    ↓ [Sync stage 1]
sync1
    ↓ [Sync stage 2]
sync2
    ↓ [Edge detector: sync2 & ~sync_prev]
    ↓ [Toggle on edge]
out (divide by 2)
```

**Đánh giá:** 
- ✅ Metastability hardening: 2-stage synchronizer
- ✅ Edge detection không bị miss pulse
- ✅ CHÍNH XÁC

---

### [F] Phase Detector (phase_detector.v)

```verilog
assign out = ref ^ fb;
```

**Đánh giá:** ✅ Đúng - XOR detector như paper

---

### [G] K-Counter (k_counter.v)

```verilog
if (enable) begin
    count <= count + 1;
    carry <= count[K-1];  // MSB output
end
```

**Đánh giá:** ✅ Đúng - K-counter như paper

---

## 🚨 Các Vấn Đề Tìm Thấy

### 1. 🔴 CRITICAL: K/DCO Clock Architecture Inconsistency

**Vấn đề:**
```
clock_gen.v:
└─ Generates individual K/DCO clocks for each RO
   ├─ k_dco_clk_ro1 = 800KHz
   ├─ k_dco_clk_ro2 = 1600KHz
   ├─ ...
   └─ k_dco_clk_ro10 = 8000KHz

muro_trng_top.v:
└─ IGNORES all individual K/DCO clocks
   └─ Uses shared 400MHz PLL for ALL ROs
      (k_dco_400mhz → ro1, ro2, ..., ro10)
```

**Tác động:**
- ⚠️ Code hoạt động nhưng KHÔNG THEO PAPER
- ⚠️ Lãng phí: 400MHz PLL dùng hết khi K_clk only need 4.7-8MHz range
- ✅ Vẫn cho kết quả (chỉ là suboptimal)

**Fix:** Dùng individual K/DCO clocks hoặc giải thích lý do dùng 400MHz PLL

---

### 2. 🟡 MEDIUM: Clock Enable Signals Mentioned but Not Used

**Vấn đề:**
```
clock_gen.v comments:
"Convert CE pulses to continuous clock signals for 10 ROs"

muro_trng_top.v:
// Declares CE signals:
wire ce_fref_100khz, ce_fref_200khz, ...

// But code is:
if (ce_fref_100khz) fref_100khz <= ~fref_100khz;

// This is WRONG - outputs on every clock edge after CE pulse!
// Should be: continuous clock from counter
```

**Điều gì thực tế xảy ra:**
```
Counter reaches N_toggle
    ↓ (toggles fref_100khz output)
    ↓ (continuous square wave)
    ↓ (CORRECT - what we want)
```

**Đánh giá:** 
- ✅ Thực tế code WORKS vì counter toggles continuously
- ⚠️ Comments MISLEADING về CE signals

---

### 3. 🟡 MEDIUM: Missing Conventional ADPLL Implementation Details

**Vấn đề:**
```
conventional_adpll.v tham số:
parameter K = 4;
parameter M = 16;
parameter N = 8;
```

**Paper yêu cầu (Table 2, 3, 4):**
```
Conventional ADPLL @ fo=25MHz:
K=4, M=16, N=8

Conventional ADPLL @ fo=12.5MHz:
K=4, M=16, N=8  (cùng K,M,N)

Conventional ADPLL @ fo=6.25MHz:
K=4, M=16, N=8
```

**Current code:**
```verilog
muro_trng_top.v:
conventional_adpll cadpll (
    .clk_sys(clk_100mhz),
    .ref_clk(fref_25mhz),        // ← 25MHz
    .k_clk(k_dco_400mhz),
    .dco_clk(k_dco_400mhz),
    .reset(reset & pll_locked_sync),
    .sample_clk(sample_clk),
    .idout(adpll_idout)
);
```

**Issue:** Chỉ dùng 25MHz, không dùng 12.5M / 6.25M tùy chọn

**Paper says:**
```
"Conventional ADPLL operates at 3 different 
reference frequencies to sample the raw random bits"
```

**Đánh giá:**
- ⚠️ Paper support 3 loại (25M/12.5M/6.25M) để test, 
      nhưng implementation chỉ cần 1 loại là đủ
- ✅ Hiện tại chỉ 25MHz là OK, nhưng nên có lựa chọn

---

### 4. ✅ GOOD: Synchronization & Reset Handling

```verilog
// PLL lock synchronization
pll_locked_sync <= k_dco_400mhz_locked;

// Gating reset khi PLL chưa khóa
.reset(reset & pll_locked_sync)
```

**Đánh giá:** ✅ TỐTGOOD PRACTICE

---

### 5. ✅ GOOD: Metastability Hardening

```verilog
// Divide-by-2-Sync dùng 2-stage synchronizer
sync1 <= async_in;
sync2 <= sync1;
sync_prev <= sync2;
```

**Đánh giá:** ✅ BEST PRACTICE

---

## 📊 So Sánh Code vs Paper

| Component | Paper Spec | Current Code | Status |
|-----------|-----------|-----------|--------|
| 10 RO fref | 100K-1000K | ✅ Counter dividers | ✅ OK |
| 10 RO K-clk | 800K-8000K | ⚠️ 400MHz shared | ⚠️ SUBOPTIMAL |
| 10 RO DCO-clk | 800K-8000K | ⚠️ 400MHz shared | ⚠️ SUBOPTIMAL |
| Conv. ADPLL fo | 25/12.5/6.25MHz | ✅ 25MHz only | ✅ SUFFICIENT |
| 11 DFFs | Synchronous | ✅ Yes | ✅ OK |
| XOR Gate | 11-input | ✅ Yes | ✅ OK |
| XOR Corrector | Post-processing | ✅ Yes | ✅ OK |
| Phase Detector | XOR | ✅ Yes | ✅ OK |
| K-Counter | Count then MSB | ✅ Yes | ✅ OK |
| DCO | NOR ring + jitter | ✅ Yes | ✅ OK |
| Sample Clock | fo/4 from Conv ADPLL | ⚠️ Need verify | ⚠️ NEED CHECK |

---

## 🛠️ Hướng Dẫn Chi Tiết Fix

### FIX #1: Sử Dụng Individual K/DCO Clocks (RECOMMENDED)

**Current (SAI):**
```verilog
// muro_trng_top.v
adpll_ring_osc ro1 (
    .k_clk(k_dco_400mhz),      // ← ALL use 400MHz
    .dco_clk(k_dco_400mhz),    // ← Not optimal
    ...
);
```

**Fix Option A: Individual Clocks (BEST - theo Paper)**

1. Export từ clock_gen.v:
```verilog
output reg  k_dco_clk_ro1,   // 800 KHz
output reg  k_dco_clk_ro2,   // 1600 KHz
...
```

2. Kết nối trong top.v:
```verilog
adpll_ring_osc #(.K(4), .M(8), .N(4)) ro1 (
    .clk_sys(clk_100mhz),
    .ref_clk(fref_100khz),
    .k_clk(k_dco_clk_ro1),     // ← 800KHz (thay vì 400M)
    .dco_clk(k_dco_clk_ro1),   // ← 800KHz
    ...
);
```

3. Module port modification:
```verilog
// clock_gen.v - UNCOMMENT / ADD these outputs:
output reg  k_dco_clk_ro1,
output reg  k_dco_clk_ro2,
...
output reg  k_dco_clk_ro10
```

**Advantage:**
- ✅ Chính xác theo paper
- ✅ Bộ nhớ mỗi RO đúng frequency
- ✅ Elegant design

---

### FIX #2: Keep 400MHz PLL (ALTERNATIVE - nếu resource tight)

**Rationale:**
- 400MHz = LCM of all K/DCO clocks
- Can work but different from paper

**Implementation:**
```verilog
// Giữ nguyên - không cần fix
// Nhưng thêm comment giải thích:

// NOTE: Design Choice - Using 400MHz shared PLL instead of
// individual K/DCO clocks per ring oscillator. This is a
// resource optimization; paper uses individual clocks.
```

---

### FIX #3: Support Multiple fo for Conventional ADPLL

**Current:**
```verilog
conventional_adpll cadpll (
    .ref_clk(fref_25mhz),  // ← Only 25MHz
    ...
);
```

**Enhanced:**
```verilog
// Add parameter to select fo
parameter CADPLL_MODE = 0; // 0=25MHz, 1=12.5MHz, 2=6.25MHz

wire cadpll_fref;
assign cadpll_fref = (CADPLL_MODE == 0) ? fref_25mhz :
                     (CADPLL_MODE == 1) ? fref_12_5mhz :
                     fref_6_25mhz;

conventional_adpll cadpll (
    .ref_clk(cadpll_fref),
    ...
);
```

---

### FIX #4: Clean Up Comments

Remove misleading CE signal comments, or implement them correctly if needed.

---

## 📈 Kế Hoạch Fix

### Phase 1: Quick Fix (30 mins)
- [ ] Verify 400MHz PLL approach works or switch to individual clocks
- [ ] Update comments for clarity
- [ ] Test simulation

### Phase 2: Detailed Fix (2-3 hours)
- [ ] Implement individual K/DCO clocks if using Fix #1
- [ ] Add support for 12.5MHz / 6.25MHz conventional ADPLL modes
- [ ] Comprehensive testbench

### Phase 3: Validation (1-2 hours)
- [ ] Run NIST tests on simulated data
- [ ] Check resource usage (LUT/FF/BRAM)
- [ ] Timing analysis (setup/hold)

### Phase 4: Documentation (1 hour)
- [ ] Update README
- [ ] Add design notes
- [ ] Parameter table

---

## 📝 Tóm Tắt Kết Luận

| Aspect | Rating | Comment |
|--------|--------|---------|
| **Cấu trúc tổng thể** | ⭐⭐⭐⭐⭐ | Đúng theo paper |
| **DCO Design** | ⭐⭐⭐⭐⭐ | Jitter từ LUT delay tốt |
| **Phase Detector** | ⭐⭐⭐⭐⭐ | XOR implementation chính xác |
| **K-Counter** | ⭐⭐⭐⭐⭐ | Đúng theo paper |
| **Clock Generation** | ⭐⭐⭐⭐ | Tốt nhưng K/DCO chưa optimal |
| **Synchronization** | ⭐⭐⭐⭐⭐ | Metastability hardening tốt |
| **Documentation** | ⭐⭐⭐ | Code comments tốt nhưng cần làm sạch |

---

## 🎓 Khuyến Cáo Cho Khóa Luận

1. **Giải thích lựa chọn K/DCO clock:**
   - Nếu dùng individual: Giải thích tại sao follow paper
   - Nếu dùng 400MHz: Justify resource optimization

2. **Đo đạc Performance:**
   - LUT usage
   - FF usage
   - Power consumption
   - Throughput (Mbps)

3. **Testing:**
   - NIST SP 800-22 validation
   - Temperature/Voltage variations
   - Autocorrelation analysis

4. **Comparison:**
   - So sánh kết quả với paper (Table 8, 9)
   - Giải thích mọi khác biệt

---

**Tiếp theo:** Bạn muốn tôi cung cấp code fix cụ thể cho từng issue không?
