module warp #(
    // Each tile is 8x8 pixels and each warp is 8x8 tiles (for now)
    parameter WARP_WIDTH = 8,
    parameter WARP_HEIGHT = 8,
    parameter TILE_WIDTH = 8,
    parameter TILE_HEIGHT = 8,
    parameter NUM_TILES = WARP_WIDTH * WARP_HEIGHT,

    parameter COLORS = 3,
    parameter COLOR_DEPTH = 8,
    parameter DATA_WIDTH = COLORS * COLOR_DEPTH
) (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic [DATA_WIDTH-1:0] tile_in[NUM_TILES-1:0][TILE_WIDTH-1:0][TILE_HEIGHT-1:0],
    output logic [DATA_WIDTH-1:0] tile_out[NUM_TILES-1:0][TILE_WIDTH-1:0][TILE_HEIGHT-1:0],
    output logic tile_valid[NUM_TILES-1:0]
);