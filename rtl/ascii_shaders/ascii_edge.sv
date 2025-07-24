`include "luminance.sv"

module ascii_edge #(
    parameter TILE_WIDTH = 8,
    parameter TILE_HEIGHT = 8,
    parameter ASCII_LEVELS = 8,

    parameter COLORS = 3,
    parameter COLOR_DEPTH = 8,
    parameter DATA_WIDTH = COLORS * COLOR_DEPTH
) (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic [DATA_WIDTH-1:0] tile_data[TILE_WIDTH-1:0][TILE_HEIGHT-1:0], // We'll associate 8x8 pixels to 1 ascii character
    output logic [$clog2(ASCII_LEVELS)-1:0] ascii,
    output logic ascii_ready,
    output logic edge_exists
);