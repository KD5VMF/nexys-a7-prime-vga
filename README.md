
# Nexys A7 Prime VGA

A complete, timing-clean VGA demo for the **Digilent Nexys A7-100T** (XC7A100T) that:
- Finds primes continuously in hardware.
- Shows the latest prime **once per second** on both VGA and 7-segment.
- Renders a centered, bright-green title (2× scaled) and centered `PRIME: XXXXXXXX` line.
- Removes leading zeros on both VGA and 7-segment.
- Uses a **single clock domain** derived from 100 MHz → **~25.2 MHz** pixel clock via **MMCME2**, so timing is easy.

> Targeted and tested with **Vivado 2022.1**.

---

## Features

- **Prime searcher** (`prime_finder_seq.v`) using restoring division.  
  - Width = **27 bits** (supports numbers up to 99,999,999).
  - Rolls over to 3 after hitting **99,999,999**.
  - Emits `2` exactly once after reset, then odd primes.
- **1 Hz UI pacing**: finder runs continuously, but the UI (VGA/7-seg) updates once/second to the **latest prime**.
- **VGA overlay** (`text_overlay_prime.v`):
  - 640×480 @ 60 Hz timing (`vga_640x480_timing.v`).
  - Title is **2×** (16×32), centered.
  - `PRIME: XXXXXXXX` is centered below the title.
  - **Bright green** text; easy to tweak.
  - Treats BCD nibble `4'hF` as **blank** (no leading zeros).
- **Seven-seg**: mirrors the same BCD digits; assumes `4'hF` blanks a digit in your decoder.
- **Single clock domain @ ~25.200 MHz** pixel clock using **MMCME2** (no Clocking Wizard IP required).  
  If you prefer exact **25.175 MHz**, see “Exact 25.175 MHz” below.

---

## Hardware

- Board: **Digilent Nexys A7-100T**
- FPGA: **XC7A100T-CSG324-1**
- System clock: 100 MHz on-board oscillator
- Configuration flash: **S25FL128S** (128 Mbit, Quad-SPI capable)
- VGA output: 640×480 @ 60 Hz

---

## Toolchain / Software

- **Xilinx Vivado 2022.1**
  - Synthesis, implementation, bitstream, HW Manager
  - (Optional) Memory Configuration File Generator (for QSPI MCS/BIN)
- No other external tools required.

---

## Repo layout

```
.
├── src/
│   ├── top_nexys_a7_prime_7seg.v        # Top-level (single 25.2 MHz domain)
│   ├── prime_finder_seq.v               # 27-bit, rollover at 99,999,999
│   ├── vga_640x480_timing.v             # 640×480@60 timing generator
│   ├── text_overlay_prime.v             # 2× title, centered, bright green
│   ├── font8x16.v                       # 8×16 bitmap font ROM
│   ├── sevenseg_mux.v                   # 7-seg scan; treat 4'hF as blank
│   └── bcd_convert_dd.v                 # Binary→BCD (param BIN_WIDTH/DIGITS)
└── constr/
    └── nexys_a7_vga.xdc                 # Pinout + 100 MHz board clock
```

> If you already have your own `sevenseg_mux.v` and `bcd_convert_dd.v`, keep them—just ensure they match the signals and params used here (see “Integration notes”).

---

## Build (Vivado 2022.1)

1. **Create a new RTL project** (no board preset required).
2. **Add Sources** → add everything under `src/`.
3. **Add Constraints** → add `constr/nexys_a7_vga.xdc`.  
   Make sure it has:
   - A `create_clock` on the 100 MHz input pin.
   - Correct VGA pin mappings for HS/VS/R/G/B nibble pins.
   - 7-segment and AN pin mappings.
4. **Set Top**: `top_nexys_a7_prime_7seg`.
5. **Synthesize → Implement → Generate Bitstream`.

You should get clean timing (single ~25.2 MHz clock domain). If not, check that the XDC clock constraint is present and correct.

---

## Program the FPGA (volatile)

1. Open **Hardware Manager** → Open Target → Auto Connect.
2. **Program Device** → choose the generated `.bit`.

---

## Program QSPI flash (non-volatile)

Two steps:
1) Generate the memory image (MCS/BIN).  
2) Write it into the S25FL128S device.

### A) Generate MCS (Quad-SPI, SPIx4)

Your bitstream is already compatible. Use the GUI:

- **File → Generate Memory Configuration File…**
  - **Format**: `MCS`
  - **Memory Part**: `s25fl128s-spi-x1_x2_x4`
  - **Interface**: `SPIx4`
  - **Load bitstream**: your `top_nexys_a7_prime_7seg.bit`
  - Output file name (e.g., `prime_demo.mcs`)
  - Check “Overwrite” if re-generating.

Or Tcl:

```tcl
write_cfgmem -force -format mcs -size 16   -interface SPIx4   -loadbit "up 0x00000000 ./top_nexys_a7_prime_7seg.bit"   -file ./prime_demo.mcs
```

> If you ever need SPIx1 instead, you must set `BITSTREAM.CONFIG.SPI_BUSWIDTH 1` **before** generating the bitstream, then use `-interface SPIx1` for `write_cfgmem`. For SPIx4 (recommended), ensure `SPI_BUSWIDTH = 4`.

### B) Write to flash

- Set the board’s mode jumpers to **QSPI** (see Digilent manual).
- In **Hardware Manager**: **Add Configuration Memory Device…**
  - Select `s25fl128s` (or compatible).
  - Choose your `prime_demo.mcs`.
  - **Erase**, **Program**, **Verify**.
- Power-cycle. The FPGA will now boot from QSPI.

---

## Exact 25.175 MHz (optional)

This project uses an **MMCME2** to produce **~25.200 MHz** (within 0.1%; works on typical displays).  
If you want **exact 25.175 MHz**, you can:

- Add a **Clocking Wizard** IP (from IP Catalog):
  - Input: 100 MHz
  - Output0: **25.175 MHz**
  - Replace the MMCME2 instance in `top_nexys_a7_prime_7seg.v` with the Wizard’s module (or keep MMCME2 and add a second output if you prefer).
- Everything else stays the same.

---

## Integration notes

- **sevenseg_mux.v**: Ensure the nibble decoder blanks on `4'hF` (all segments off). Example:

  ```verilog
  case (nibble)
    4'h0: seg = 7'b1000000;
    // ...
    4'h9: seg = 7'b0010000;
    4'hF: seg = 7'b1111111; // blank
    default: seg = 7'b1111111;
  endcase
  ```

- **text_overlay_prime.v**: Already skips drawing when a BCD nibble is `4'hF`, so VGA has no leading zeros.
- **bcd_convert_dd.v**: Use `#(.BIN_WIDTH(27), .DIGITS(8))` to match our width and 8-digit display.  
- **prime_finder_seq.v**: Parameter `WIDTH=27` and roll-over at 99,999,999 are already included.

---

## Troubleshooting

- **“module not found” for Clocking Wizard**  
  This repo **does not** require a Clocking Wizard IP; it uses **MMCME2_BASE** directly. If you swap to Clocking Wizard, be sure to generate the IP and include it in the project.
- **Timing 38-282**  
  Make sure you are truly running everything in the **single ~25.2 MHz domain** from the MMCME2 output (no 100 MHz fabric left over). Confirm your XDC has the 100 MHz `create_clock`.
- **QSPI generation errors**  
  - `SMAPX8 is not compatible…`: choose **SPIx4** in `write_cfgmem`.
  - `SPI_BUSWIDTH property is set to 4…`: use **SPIx4** (or rebuild bitstream for SPIx1 if you insist).
  - “Cannot overwrite … .prm”: add `-force` or choose a new output filename.

---

## License

MIT

---

## Credits

- Digilent Nexys A7 (Artix-7) platform.
- Xilinx Vivado 2022.1.
- 8×16 font ROM; standard 640×480 porch/sync timings.
