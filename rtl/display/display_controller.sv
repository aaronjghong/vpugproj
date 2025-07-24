// `include "vga.sv"

module display_controller #(
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
    parameter COLOR_DEPTH = 8,
    parameter DATA_WIDTH = COLORS * COLOR_DEPTH,
    parameter H_TOTAL_LOG2 = $clog2(H_TOTAL),
    parameter V_TOTAL_LOG2 = $clog2(V_TOTAL)
) (
    input logic clk,
    input logic rst,
    input logic [DATA_WIDTH-1:0] buffer [H_DISPLAY-1:0], // Here for now to test the display controller, should be received from fb
    output logic [COLOR_DEPTH-1:0] vga_r, vga_g, vga_b,
    output logic vga_hsync, vga_vsync,
    output logic [H_TOTAL_LOG2-1:0] curr_x,
    output logic [V_TOTAL_LOG2-1:0] curr_y
);
logic [DATA_WIDTH-1:0] pixel_data;

initial begin
    curr_x = 0;
    curr_y = 0;
    pixel_data = 0;
end

always @(posedge clk) begin
    if (rst) begin
        curr_x <= 0;
        curr_y <= 0;
        pixel_data <= 0;
    end else begin
        if (curr_x == H_TOTAL - 1) begin
            curr_x <= 0;
            if (curr_y == V_TOTAL - 1) begin
                curr_y <= 0;
            end else begin
                curr_y <= curr_y + 1;
            end
        end else begin
            curr_x <= curr_x + 1;
            pixel_data <= buffer[(curr_x < H_DISPLAY) ? curr_x : (H_DISPLAY-1)];
        end
    end
end

vga #(
    .H_DISPLAY(H_DISPLAY),
    .H_FRONT(H_FRONT),
    .H_SYNC(H_SYNC),
    // .H_BACK(H_BACK),
    .H_TOTAL(H_TOTAL),
    .V_DISPLAY(V_DISPLAY),
    .V_FRONT(V_FRONT),
    .V_SYNC(V_SYNC),
    // .V_BACK(V_BACK),
    .V_TOTAL(V_TOTAL),
    .COLORS(COLORS),
    .COLOR_DEPTH(COLOR_DEPTH)
    // .DATA_WIDTH(DATA_WIDTH)
)vga_output (
    // .clk_25mhz(clk),
    // .rst(rst),
    .pixel_data(pixel_data),
    .curr_x(curr_x),
    .curr_y(curr_y),
    .vga_r(vga_r),
    .vga_g(vga_g),
    .vga_b(vga_b),
    .vga_hsync(vga_hsync),
    .vga_vsync(vga_vsync)
);






endmodule
