# VGA Display Controller Simulation

This project simulates a 640x480@60Hz VGA display controller using Verilog and a C++ testbench, with image-based framebuffer input. The simulation is run using [Verilator](https://www.veripool.org/verilator/) and outputs both waveform and framebuffer files for analysis.

## Features
- Verilog display controller and VGA signal generator
- C++ testbench with SDL2 visualization

## Prerequisites
- [Verilator](https://www.veripool.org/verilator/)
- [GTKWave](http://gtkwave.sourceforge.net/) (for waveform viewing)
- [SDL2 development libraries](https://www.libsdl.org/)
- [Python 3](https://www.python.org/) and [Pillow](https://python-pillow.org/) (`pip install pillow`)
- C++14-compatible compiler (e.g., `g++`)

## Usage

### 1. Prepare Framebuffer Image
Place an image in the `img/` directory (default: `img/test_image.png`). To use a different image, update the `TEST_IMAGE` variable in the `Makefile`.

### 2. Build the Simulation
```sh
make
```
This compiles the Verilog and C++ sources and prepares the simulation executable.

### 3. Run the Simulation
```sh
make run
```
This runs the testbench, simulating the display controller and generating output files in the `output/` directory.

### 4. View the Output
- **Waveform:**
  ```sh
  make waves
  ```
  Opens `output/vga_trace.vcd` in GTKWave.
- **Framebuffer Screenshot:**
  - `output/frame_buffer.bmp` — BMP screenshot of the simulated VGA output
  - `output/frame_buffer.bin` — Raw framebuffer data (uint32_t per pixel, 640x480)

## File Structure
- `rtl/display_controller.sv` — Top-level display controller (instantiates `vga.sv`)
- `rtl/vga.sv` — VGA signal generator (640x480@60Hz)
- `tb/tb_vga.cpp` — C++ testbench (loads framebuffer, runs simulation, outputs files)
- `scripts/image_to_header.py` — Converts PNG to C header for framebuffer
- `img/test_image.png` — Example input image
- `obj_dir/image_data.h` — Generated framebuffer header (auto-created)
- `output/` — Simulation outputs: VCD, BMP, BIN
- `Makefile` — Build and run targets

## Output Files
- `output/vga_trace.vcd` — Waveform trace for GTKWave
- `output/frame_buffer.bmp` — Screenshot of VGA output
- `output/frame_buffer.bin` — Raw framebuffer (uint32_t[640*480])

## Future Goals
- Implement ASCII shader output (Inspired by: https://github.com/GarrettGunnell/AcerolaFX/blob/main/Shaders/AcerolaFX_ASCII.fx)
- Implement GPGPU (Inspired by: https://github.com/raster-gpu/raster-i)