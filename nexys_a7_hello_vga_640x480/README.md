# Nexys A7-100T — VGA "HELLO WORLD!" (640×480 @ 60 Hz)

This is a minimal, Vivado‑ready RTL that drives a VGA monitor from the Digilent **Nexys A7‑100T** using a 100 MHz system clock and a 25 MHz pixel enable (÷4). It renders **HELLO WORLD!** centered in white on black.

## Files

- `top_hello_vga.v` — Top‑level RTL with VGA timing and a tiny 8×8 font for the string.
- `Nexys-A7-100T-HELLO-VGA.xdc` — Constraints for the 100 MHz clock and VGA pins.
- `create_project_hello_vga.tcl` — One‑shot script to make a Vivado project and import files.

## Device / Tooling

- Board: Digilent **Nexys A7‑100T** (Artix‑7 XC7A100T‑CSG324‑1)
- Vivado: 2020.2–2024.x (tested with 2022.1 style flows)

## Quick Start

### A) Manual GUI

1. **Create Project** → RTL Project (no sources) → `xc7a100tcsg324-1`.
2. Add `top_hello_vga.v` (Sources) and `Nexys-A7-100T-HELLO-VGA.xdc` (Constraints).
3. Set top module to **`top_hello_vga`** if not auto‑detected.
4. Run Synthesis → Implementation → Generate Bitstream.
5. Program the board and connect a VGA monitor.

### B) TCL

In the Vivado Tcl Console:

```
cd <unzipped-folder>
source create_project_hello_vga.tcl
launch_runs synth_1 impl_1 -to_step write_bitstream
wait_on_run impl_1
open_run impl_1 -name impl_1
```

## Notes

- Timing uses standard **640×480@60** (H: 640/16/96/48; V: 480/10/2/33). Pixel clock is effectively 25 MHz using a clock enable; most monitors accept this. If your display is picky, swap in a `clk_wiz` for **25.175 MHz** and clock the logic directly.
- The reset pin (`CPU_RESETN`) is included in the port list but not used; you can keep the XDC line or comment it out.
- To change the message, edit the `text[...]` array. For longer strings or full ASCII, extend the font function or replace it with a ROM.

Have fun!
