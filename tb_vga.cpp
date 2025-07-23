#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vvga_chip.h"
#include <iostream>
#include <memory>
#include <vector>

class MemoryModel {
private:
    std::vector<uint32_t> memory;
    static const int MEMORY_SIZE = 640 * 480; // 640x480 pixels
    
public:
    MemoryModel() : memory(MEMORY_SIZE) {
        generateTestPattern();
    }
    
    void generateTestPattern() {
        // Generate a simple test pattern
        for (int y = 0; y < 480; y++) {
            for (int x = 0; x < 640; x++) {
                int addr = y * 640 + x;
                
                // Create a colorful test pattern
                uint8_t r, g, b;
                
                if (x < 213) {
                    // Red section
                    r = 255; g = 0; b = 0;
                } else if (x < 426) {
                    // Green section  
                    r = 0; g = 255; b = 0;
                } else {
                    // Blue section
                    r = 0; g = 0; b = 255;
                }
                
                // Add some vertical stripes
                if ((x / 32) % 2 == 0) {
                    r = r / 2; g = g / 2; b = b / 2;
                }
                
                // Add horizontal stripes
                if ((y / 16) % 2 == 0) {
                    r = (r + 128) / 2; 
                    g = (g + 128) / 2; 
                    b = (b + 128) / 2;
                }
                
                memory[addr] = (r << 16) | (g << 8) | b;
            }
        }
    }
    
    // Handle memory read requests (single pixel)
    uint32_t read_pixel(uint32_t addr) {
        if (addr >= MEMORY_SIZE) return 0;
        return memory[addr] & 0xFFFFFF; // Return 24-bit RGB
    }
};

class VGATestbench {
private:
    std::unique_ptr<Vvga_chip> dut;
    std::unique_ptr<VerilatedVcdC> trace;
    MemoryModel memory;
    uint64_t sim_time;
    
    // Memory interface state
    bool mem_request_pending;
    uint32_t mem_request_addr;
    int mem_delay_counter;
    static const int MEM_DELAY = 3; // 3 clock cycles memory latency
    
public:
    VGATestbench() : sim_time(0), mem_request_pending(false), mem_delay_counter(0) {
        dut = std::make_unique<Vvga_chip>();
        
        // Initialize trace
        Verilated::traceEverOn(true);
        trace = std::make_unique<VerilatedVcdC>();
        dut->trace(trace.get(), 99);
        trace->open("vga_trace.vcd");
        
        // Initialize DUT
        dut->clk_25mhz = 0;
        dut->rst = 1;
        dut->mem_valid = 0;
        dut->mem_data = 0;
    }
    
    ~VGATestbench() {
        trace->close();
    }
    
    void clock_tick() {
        // Handle memory interface
        handleMemoryInterface();
        
        // Rising edge
        dut->clk_25mhz = 1;
        dut->eval();
        trace->dump(sim_time);
        sim_time++;
        
        // Falling edge
        dut->clk_25mhz = 0;
        dut->eval();
        trace->dump(sim_time);
        sim_time++;
    }
    
    void handleMemoryInterface() {
        // Handle memory read requests
        if (dut->mem_read && !mem_request_pending) {
            // New memory request
            mem_request_pending = true;
            mem_request_addr = dut->mem_addr;
            mem_delay_counter = MEM_DELAY;
            dut->mem_valid = 0;
        }
        
        // Handle memory response with delay
        if (mem_request_pending) {
            if (mem_delay_counter > 0) {
                mem_delay_counter--;
                dut->mem_valid = 0;
            } else {
                // Memory data ready
                uint32_t pixel_data = memory.read_pixel(mem_request_addr);
                dut->mem_data = pixel_data;
                dut->mem_valid = 1;
                mem_request_pending = false;
            }
        }
        
        // Clear mem_valid if no read request
        if (!dut->mem_read) {
            dut->mem_valid = 0;
        }
    }
    
    void reset(int cycles = 10) {
        dut->rst = 1;
        for (int i = 0; i < cycles; i++) {
            clock_tick();
        }
        dut->rst = 0;
        std::cout << "Reset complete after " << cycles << " cycles" << std::endl;
    }
    
    void run(uint64_t max_cycles) {
        std::cout << "Starting VGA simulation for " << max_cycles << " cycles" << std::endl;
        
        uint64_t last_report = 0;
        uint64_t frame_count = 0;
        bool last_vsync = false;
        
        for (uint64_t cycle = 0; cycle < max_cycles; cycle++) {
            clock_tick();
            
            // Detect frame completion (vsync rising edge)
            if (dut->vga_vsync && !last_vsync) {
                frame_count++;
                std::cout << "Frame " << frame_count << " completed at cycle " << cycle << std::endl;
            }
            last_vsync = dut->vga_vsync;
            
            // Progress report every 100k cycles
            if (cycle - last_report >= 100000) {
                std::cout << "Cycle " << cycle << " - Frame " << frame_count << std::endl;
                last_report = cycle;
            }
            
            // Early exit after a few frames for testing
            if (frame_count >= 3) {
                std::cout << "Completed " << frame_count << " frames, ending simulation" << std::endl;
                break;
            }
        }
        
        std::cout << "Simulation complete. Total cycles: " << sim_time/2 << std::endl;
        std::cout << "Generated trace file: vga_trace.vcd" << std::endl;
    }
    
    void dumpVGAInfo() {
        std::cout << "\n=== VGA Status ===" << std::endl;
        std::cout << "HSYNC: " << (dut->vga_hsync ? "HIGH" : "LOW") << std::endl;
        std::cout << "VSYNC: " << (dut->vga_vsync ? "HIGH" : "LOW") << std::endl;
        std::cout << "RGB: (" << (int)dut->vga_r << ", " << (int)dut->vga_g << ", " << (int)dut->vga_b << ")" << std::endl;
        std::cout << "Memory Read: " << (dut->mem_read ? "ACTIVE" : "IDLE") << std::endl;
        std::cout << "Memory Valid: " << (dut->mem_valid ? "VALID" : "INVALID") << std::endl;
        std::cout << "Memory Address: 0x" << std::hex << dut->mem_addr << std::dec << std::endl;
    }
};

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    // Create testbench
    VGATestbench tb;
    
    // Reset the system
    tb.reset();
    
    // Run simulation
    // 60 FPS @ 25.175MHz = 419,430 cycles per frame
    // Let's run for about 3 frames = ~1.26M cycles
    tb.run(1260000);
    
    return 0;
} 