module top (
    input logic clk_25mhz,
    input logic rst,
    output logic [7:0] vga_r,
    output logic [7:0] vga_g,
    output logic [7:0] vga_b,
    output logic vga_hsync,
    output logic vga_vsync
);

logic [23:0] mem_data;
logic [18:0] mem_addr;
logic mem_read;


endmodule