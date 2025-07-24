`include "ascii_fill.sv"
`include "ascii_edge.sv"
`include "ascii_texture_sampler.sv"

module ascii_shader #(
    parameter WIDTH = 640,
    parameter HEIGHT = 480,

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
    input logic [DATA_WIDTH-1:0] tile_in[TILE_WIDTH-1:0][TILE_HEIGHT-1:0],
    output logic [TILE_WIDTH-1:0][TILE_HEIGHT-1:0] tile_out,
    output logic tile_valid
);

logic [$clog2(ASCII_LEVELS)-1:0] fill_ascii;
logic [$clog2(ASCII_LEVELS)-1:0] edge_ascii;
logic fill_ascii_ready;
logic edge_ascii_ready;
logic edge_exists;

logic [TILE_WIDTH-1:0][TILE_HEIGHT-1:0] fill_ascii_texture;
logic [TILE_WIDTH-1:0][TILE_HEIGHT-1:0] edge_ascii_texture;
logic fill_ascii_texture_valid;
logic edge_ascii_texture_valid;

ascii_fill #(
    .TILE_WIDTH(TILE_WIDTH),
    .TILE_HEIGHT(TILE_HEIGHT),
    .ASCII_LEVELS(ASCII_LEVELS),
    .COLORS(COLORS),
    .COLOR_DEPTH(COLOR_DEPTH),
    .DATA_WIDTH(DATA_WIDTH)
) ascii_fill_inst ( 
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .tile_in(tile_in),
    .ascii(fill_ascii),
    .ascii_ready(fill_ascii_ready)
);

ascii_texture_sampler #(
    .TILE_WIDTH(TILE_WIDTH),
    .TILE_HEIGHT(TILE_HEIGHT),
    .ASCII_LEVELS(ASCII_LEVELS),
) ascii_texture_sampler_inst (
    .clk(clk),
    .rst(rst),
    .enable(fill_ascii_ready),
    .edge_texture(0),
    .ascii_in(fill_ascii),
    .pixel_out(fill_ascii_texture),
    .pixel_valid(fill_ascii_texture_valid)
);

ascii_edge #(
    .TILE_WIDTH(TILE_WIDTH),
    .TILE_HEIGHT(TILE_HEIGHT),
    .ASCII_LEVELS(ASCII_LEVELS),
    .COLORS(COLORS),
    .COLOR_DEPTH(COLOR_DEPTH),
    .DATA_WIDTH(DATA_WIDTH)
) ascii_edge_inst ( 
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .tile_in(tile_in),
    .ascii(edge_ascii),
    .ascii_ready(edge_ascii_ready),
    .edge_exists(edge_exists)
);

ascii_texture_sampler #(
    .TILE_WIDTH(TILE_WIDTH),
    .TILE_HEIGHT(TILE_HEIGHT),
    .ASCII_LEVELS(ASCII_LEVELS)
) ascii_texture_sampler_inst (
    .clk(clk),
    .rst(rst),
    .enable(edge_ascii_ready),
    .edge_texture(1),
    .ascii_in(edge_ascii),
    .pixel_out(edge_ascii_texture),
    .pixel_valid(edge_ascii_texture_valid)
);

enum logic [1:0] {
    IDLE = 0,
    WAITING = 1,
    READY = 2
} state;

always_comb begin
    for (int i = 0; i < TILE_WIDTH; i++) begin
        for (int j = 0; j < TILE_HEIGHT; j++) begin
            tile_out[i][j] = tile_in[i][j] * (edge_exists ? edge_ascii_texture[i][j] : fill_ascii_texture[i][j]);
        end
    end
end
    
always @(posedge clk) begin
    if (rst) begin
        tile_out <= 0;
        tile_valid <= 0;
        state <= IDLE;
    end else begin
        if (enable) begin
            case (state)
                IDLE: begin
                    tile_out <= tile_in;
                    tile_valid <= 1;
                    state <= WAITING;
                end
                WAITING: begin
                    if (edge_ascii_texture_valid && fill_ascii_texture_valid) begin
                        tile_valid <= 1;
                        state <= READY;
                    end
                end
                READY: begin
                    tile_out <= tile_in * (edge_exists ? edge_ascii_texture : fill_ascii_texture);
                    tile_valid <= 1;
                    state <= IDLE;
                end
            endcase
        end else begin
            tile_valid <= 0;
            state <= IDLE;
        end
    end
end