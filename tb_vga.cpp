#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vdisplay_controller.h"
#include <iostream>
#include <memory>
#include <vector>
#include <SDL2/SDL.h>
#include <fstream>

#define WIDTH 640
#define HEIGHT 480

class VGATestbench {
private:
    std::unique_ptr<Vdisplay_controller> dut;
    std::unique_ptr<VerilatedVcdC> trace;
    uint64_t sim_time;
    SDL_Window* window;
    SDL_Renderer* renderer;
    std::vector<uint32_t> frame_buffer;
public:
    VGATestbench() : sim_time(0), frame_buffer(WIDTH*HEIGHT) {
        // Initialize SDL
        if (SDL_Init(SDL_INIT_VIDEO) < 0) {
            std::cerr << "SDL initialization failed: " << SDL_GetError() << std::endl;
            exit(1);
        }
        // Create window
        window = SDL_CreateWindow("VGA Test", 
                                SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                WIDTH, HEIGHT,
                                SDL_WINDOW_SHOWN);
        if (!window) {
            std::cerr << "Window creation failed: " << SDL_GetError() << std::endl;
            exit(1);
        }
        renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
        if (!renderer) {
            std::cerr << "Renderer creation failed: " << SDL_GetError() << std::endl;
            exit(1);
        }
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);
        SDL_RenderPresent(renderer);

        dut = std::make_unique<Vdisplay_controller>();
        
        // Initialize trace
        Verilated::traceEverOn(true);
        trace = std::make_unique<VerilatedVcdC>();
        dut->trace(trace.get(), 99);
        trace->open("vga_trace.vcd");
        
        // Initialize DUT
        dut->clk = 0;
        dut->rst = 1;
    
        // Initialize buffer with test pattern
        for (int i = 0; i < WIDTH; i++) {
            uint8_t r, g, b;
            
            if (i < 213) {
                r = 255; g = 0; b = 0;
            } else if (i < 426) {
                r = 0; g = 255; b = 0;
            } else {
                r = 0; g = 0; b = 255;
            }
            
            
            dut->buffer[i] = 0xff << 24 | (r << 16) | (g << 8) | b;
        }
    }
    
    ~VGATestbench() {
        trace->close();
    }
    
    void clock_tick() {
        // Rising edge
        dut->clk = 1;
        dut->eval();
        trace->dump(sim_time);
        sim_time++;
        
        // Falling edge
        dut->clk = 0;
        dut->eval();
        trace->dump(sim_time);
        sim_time++;
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
        uint64_t last_frame_cycle = 0;
        uint64_t frame_cycle_count = 0;
        uint64_t frame_count = 0;
        bool last_vsync = false;
        
        for (uint64_t cycle = 0; cycle < max_cycles; cycle++) {
            clock_tick();
            
            if(dut->curr_y < HEIGHT && dut->curr_x < WIDTH) {
                frame_buffer[dut->curr_y * WIDTH + dut->curr_x] = dut->vga_r << 16 | dut->vga_g << 8 | dut->vga_b;
            }

            // Detect frame completion (vsync rising edge)
            if (dut->vga_vsync && !last_vsync) {
                frame_count++;
                std::cout << "Frame " << frame_count << " completed at cycle " << cycle << std::endl;

                // Render the frame
                SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
                SDL_RenderClear(renderer);
                for (int y = 0; y < HEIGHT; y++) {
                    for (int x = 0; x < WIDTH; x++) {
                        SDL_SetRenderDrawColor(renderer, frame_buffer[y * WIDTH + x] >> 16, frame_buffer[y * WIDTH + x] >> 8, frame_buffer[y * WIDTH + x], 255);
                        SDL_RenderDrawPoint(renderer, x, y);
                    }
                }
                SDL_RenderPresent(renderer);
                frame_cycle_count = cycle - last_frame_cycle;
                std::cout << "Frame cycle count: " << frame_cycle_count << std::endl;
                last_frame_cycle = cycle;
            }
                
            last_vsync = dut->vga_vsync;
            
            // Progress report every 100k cycles
            if (cycle - last_report >= 100000) {
                std::cout << "Cycle " << cycle << " - Frame " << frame_count << std::endl;
                last_report = cycle;
            }
            
            // Early exit after a few frames for testing
            if (frame_count >= 10) {
                std::cout << "Completed " << frame_count << " frames, ending simulation" << std::endl;
                break;
            }
        }
        
        std::cout << "Simulation complete. Total cycles: " << sim_time/2 << std::endl;
        std::cout << "Generated trace file: vga_trace.vcd" << std::endl;

        // Save the frame buffer to a bmp file
        SDL_Surface* surface = SDL_CreateRGBSurfaceFrom(frame_buffer.data(), WIDTH, HEIGHT, 32, WIDTH * 4, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
        SDL_SaveBMP(surface, "frame_buffer.bmp");
        SDL_FreeSurface(surface);

        // Save the frame buffer to a binary file
        std::ofstream frame_buffer_file("frame_buffer.bin", std::ios::binary);
        frame_buffer_file.write(reinterpret_cast<char*>(frame_buffer.data()), frame_buffer.size() * sizeof(uint32_t));
        frame_buffer_file.close();

        // Close the window
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
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
    tb.run(1000000000);
    
    return 0;
} 