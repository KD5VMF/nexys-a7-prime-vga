# Nexys A7 — Prime + Clocks (VGA + 7‑seg)

A collection of **clean, working Vivado 2022.1** designs for the **Digilent Nexys A7‑100T (XC7A100T‑CSG324‑1)**:

- **Prime_v2** — 640×480 VGA prime demo with 7‑seg mirror (single ~25.2 MHz pixel clock domain).
- **Clock_v10** — Real‑time clock on the **8‑digit 7‑segment** display (five‑button UI, blinking colon).
- **VGA_Clock_v8** — Big, bright‑green time on **VGA** with a screensaver‑style **bouncing** motion; 7‑seg is disabled.

All projects are self‑contained RTL (Verilog‑2001) + XDC and have been tested on Nexys A7‑100T with Vivado 2022.1.

---

## Repository layout

```
.
├── Clock_v10/                     # 7‑segment RTC (buttons: C/U/D/L/R)
├── VGA_Clock_v8/                  # VGA clock (bright green, bounces; 7‑seg off)
├── Prime_v2/                      # Original prime‑finder VGA demo with 7‑seg mirror
└── nexys_a7_hello_vga_640x480/    # Minimal VGA timing hello (reference)
```

Each subfolder contains:
- `src/` — synthesizable RTL
- `constr/` — XDC constraints for the Nexys A7 (100 MHz clock + pinout)
- (some folders include `build/` Tcl helpers for a one‑click project)

---

## Hardware

- **Board**: Digilent Nexys A7‑100T
- **FPGA**: XC7A100T‑CSG324‑1
- **System clock**: 100 MHz onboard oscillator
- **Video**: VGA 640×480 @ 60 Hz (12‑bit RGB via resistor ladder DAC)
- **Inputs**: 5 push buttons (BTNC/BTNU/BTND/BTNL/BTNR)

---

## Build (Vivado 2022.1)

> Repeat these steps for the subproject you want (e.g., `VGA_Clock_v8`).

1. **Create RTL project** (no board preset required). Target device: `xc7a100tcsg324-1`.
2. **Add Sources** → add everything from the project’s `src/` directory.
3. **Add Constraints** → add the XDC under `constr/` for that project.
   - Make sure the XDC has a `create_clock` for the 100 MHz pin **E3** and the correct VGA + 7‑seg pins.
4. **Set Top** to the project’s top module (see its `src/`).
5. **Synthesize → Implement → Generate Bitstream**.
6. **Program** (see next section).

> Tips:
> - Projects use a single, low‑frequency pixel clock domain (~25 MHz) for timing simplicity.
> - VGA text renderers use an 8×16 font (scaled).
> - 7‑seg decoder treats `4'hF` as a blank (no segment lit).

---

## Run it on the board

### A) Program the FPGA (volatile, via JTAG/USB)
- Open **Hardware Manager** → *Open Target → Auto Connect* → *Program Device* with the `.bit` file.
- Works immediately, but the design is **lost on power‑off**.

### B) Program Quad‑SPI Flash (non‑volatile, from power‑up)
1. **Generate MCS/BIN**: *File → Generate Memory Configuration File…*
   - Format: **MCS**
   - Device/Interface: **s25fl128s** / **SPIx4**
   - Load your `*.bit`, output e.g. `project.mcs`
2. **Write to flash**: *Hardware Manager → Add Configuration Memory Device…*
   - Pick `s25fl128s`, point to `project.mcs`, Erase/Program/Verify
3. Set the mode jumper(s) for **QSPI** boot and power‑cycle. Your design now loads at reset.

### C) Configure from **USB flash drive** or **microSD card** (no PC required)
- Format the device as **FAT32**.
- Copy **one** `*.bit` file into the **root** of the drive/card.
- On the Nexys A7:
  - Set the **Programming Mode** jumper to **USB/SD**.
  - Use the **select jumper** to choose **USB** vs **SD**.
  - Press **PROG** or power‑cycle. The on‑board microcontroller streams the bitstream to the FPGA.
- If the status LED indicates an error, check the device selection, FAT32 formatting, and that the bitstream targets **XC7A100T**.

---

## Project notes

### `Clock_v10` — 7‑segment RTC
- **UI**: `BTN_C` toggles **set mode**; `BTN_L/BTN_R` select field (HH/MM/SS); `BTN_U/BTN_D` inc/dec.
- **Display**: 8‑digit 7‑seg + blinking colon (DP).
- **Timing**: 1 Hz tick from the 100 MHz clock; the colon blinks at 1 Hz.

### `VGA_Clock_v8` — VGA bouncing clock
- **Output**: bright‑green `HH:MM:SS` on a black background.
- **Motion**: updates once per second; **reflect‑and‑clamp** screensaver bounce (no wrap‑through).
- **Seven‑seg**: ports remain, but driven **OFF** in RTL so only VGA shows the time.

### `Prime_v2` — VGA prime finder
- Fast odd‑only search with restoring division.
- **UI pacing**: 1 Hz update of the displayed value; removes leading zeros on VGA & 7‑seg.
- **Clocking**: single ~25.2 MHz pixel clock via MMCME2 for simple timing.

---

## Known‑good pinout (summary)

- **Clock**: `clk100mhz` → **E3**, `IOSTANDARD LVCMOS33`
- **Buttons**: `btnC` N17, `btnU` M18, `btnD` P18, `btnL` P17, `btnR` M17
- **VGA**:
  - **HS** B11, **VS** B12
  - **R[3:0]** A4 C5 B4 A3
  - **G[3:0]** A6 B6 A5 C6
  - **B[3:0]** D8 D7 C7 B7
- **7‑seg**: `seg[6:0]` T10 R10 K16 K13 P15 T11 L18; `dp` H15; `an[7:0]` J17 J18 T9 J14 P14 T14 K2 U13

> The full XDCs in each project contain the exact `set_property` lines and the 100 MHz `create_clock`.

---

## License

MIT for the HDL in this repo unless otherwise noted.

## Credits

- Board: Digilent **Nexys A7‑100T**
- Tools: AMD/Xilinx **Vivado 2022.1**
- Thanks to the FPGA community for VGA timing references and clean constraint patterns.
