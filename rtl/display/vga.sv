/* verilator lint_off DECLFILENAME */
module vga #(
    parameter H_DISPLAY = 640,
    parameter H_FRONT   = 16,
    parameter H_SYNC    = 96,
    // parameter H_BACK    = 48,
    parameter H_TOTAL   = 800,

    parameter V_DISPLAY = 480,
    parameter V_FRONT   = 10,
    parameter V_SYNC    = 2,
    // parameter V_BACK    = 33,
    parameter V_TOTAL   = 525,

    parameter COLORS = 3,
    parameter COLOR_DEPTH = 8
) (
    // input logic clk_25mhz,           // 25.175MHz pixel clock
    // input logic rst,
    
    input logic [COLORS*COLOR_DEPTH-1:0] pixel_data,
    input logic [$clog2(H_TOTAL)-1:0] curr_x,
    input logic [$clog2(V_TOTAL)-1:0] curr_y,
    
    output logic [COLOR_DEPTH-1:0] vga_r, vga_g, vga_b,
    output logic vga_hsync, vga_vsync
);

logic display_enable;

assign vga_hsync = !((curr_x >= H_DISPLAY + H_FRONT) && 
                    (curr_x < H_DISPLAY + H_FRONT + H_SYNC));
assign vga_vsync = !((curr_y >= V_DISPLAY + V_FRONT) && 
                    (curr_y < V_DISPLAY + V_FRONT + V_SYNC));
assign display_enable = (curr_x < H_DISPLAY) && (curr_y < V_DISPLAY);

assign vga_r = display_enable ? pixel_data[COLOR_DEPTH*3-1:COLOR_DEPTH*2] : {COLOR_DEPTH{1'b0}};
assign vga_g = display_enable ? pixel_data[COLOR_DEPTH*2-1:COLOR_DEPTH]  : {COLOR_DEPTH{1'b0}};
assign vga_b = display_enable ? pixel_data[COLOR_DEPTH-1:0]   : {COLOR_DEPTH{1'b0}};

endmodule
