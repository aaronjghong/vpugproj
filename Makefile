# Makefile for VGA Verilator testbench

# Verilator and compiler settings
VERILATOR = verilator
CXX = g++
VERILATOR_FLAGS = -Wall --cc --exe --trace
VERILATOR_FLAGS += -CFLAGS "-std=c++14 -O2"
VERILATOR_FLAGS += -LDFLAGS "-pthread $(shell sdl2-config --libs)"
VERILATOR_FLAGS += -Irtl

# Source files
VERILOG_SOURCES = rtl/display_controller.sv rtl/vga.sv
CPP_SOURCES = tb_vga.cpp
TOP_MODULE = display_controller

# Output files
EXECUTABLE = obj_dir/V$(TOP_MODULE)
TRACE_FILE = vga_trace.vcd

# Default target
all: $(EXECUTABLE)

# Build the executable
$(EXECUTABLE): $(VERILOG_SOURCES) $(CPP_SOURCES)
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $(TOP_MODULE) $(VERILOG_SOURCES) $(CPP_SOURCES)
	make -C obj_dir -f V$(TOP_MODULE).mk

# Run the simulation
run: $(EXECUTABLE)
	@echo "Running VGA simulation..."
	./$(EXECUTABLE)
	@echo "Simulation complete. Trace file: $(TRACE_FILE)"

# View the waveform (requires GTKWave)
waves: $(TRACE_FILE)
	@if command -v gtkwave >/dev/null 2>&1; then \
		if [ -f vga_signals.gtkw ]; then \
			gtkwave $(TRACE_FILE) vga_signals.gtkw & \
		else \
			gtkwave $(TRACE_FILE) & \
		fi; \
	else \
		echo "GTKWave not found. Please install GTKWave to view waveforms."; \
		echo "On Ubuntu/Debian: sudo apt install gtkwave"; \
	fi

# Clean build artifacts
clean:
	rm -rf obj_dir/
	rm -f $(TRACE_FILE)

# Lint the Verilog code
lint:
	$(VERILATOR) --lint-only $(VERILOG_SOURCES) --top-module $(TOP_MODULE)

# Run simulation and open waveforms
sim: run waves

# Help target
help:
	@echo "Available targets:"
	@echo "  all     - Build the executable (default)"
	@echo "  run     - Run the simulation"
	@echo "  waves   - Open waveform viewer (requires GTKWave)"
	@echo "  sim     - Run simulation and open waveforms"
	@echo "  lint    - Check Verilog syntax"
	@echo "  clean   - Clean build artifacts"
	@echo "  help    - Show this help message"

# Debug target with verbose output
debug: VERILATOR_FLAGS += -CFLAGS "-DDEBUG -g"
debug: $(EXECUTABLE)
	@echo "Debug build complete. Run with: ./$(EXECUTABLE)"

# Install dependencies (Ubuntu/Debian)
install-deps:
	@echo "Installing Verilator, GTKWave, and SDL2..."
	sudo apt update
	sudo apt install verilator gtkwave libsdl2-dev

.PHONY: all run waves clean lint sim help debug install-deps 