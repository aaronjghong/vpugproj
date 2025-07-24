module ascii_texture_sampler #(
    parameter TILE_WIDTH = 8,
    parameter TILE_HEIGHT = 8,
    parameter ASCII_LEVELS = 8,
) (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic edge_texture,
    input logic [ASCII_LEVELS-1:0] ascii_in,
    output logic [TILE_WIDTH-1:0][TILE_HEIGHT-1:0] pixel_out,
    output logic pixel_valid
);

`include "ascii_texture_fill.sv"
`include "ascii_texture_edge.sv"

initial begin
    pixel_out = 0;
    pixel_valid = 0;
end

always @(posedge clk) begin
    if (rst) begin
        pixel_out <= 0;
        pixel_valid <= 0;
    end else begin 
        if (enable) begin
            pixel_out <= edge_texture ? texture_data_edge[ascii_in] : texture_data_fill[ascii_in];
            pixel_valid <= 1;
        end else begin
            pixel_valid <= 0;
        end
    end
end


endmodule