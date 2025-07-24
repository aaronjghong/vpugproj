`include "luminance.sv"

module ascii_fill #(
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
    output logic ascii_ready
);

localparam MAX_LUMINANCE = 2**(DATA_WIDTH-1);
logic [DATA_WIDTH-1:0] luminance_sum;

initial begin
    ascii = 0;
    luminance_sum = 0;
    ascii_ready = 0;
end

always @(posedge clk) begin
    if (rst) begin
        ascii <= 0;
        luminance_sum <= 0;
        ascii_ready <= 0;
    end else if (enable) begin
        // Normalize luminance to 0-ASCII_LEVELS
        ascii <= (luminance_sum >> $clog2(TILE_WIDTH * TILE_HEIGHT)) / (MAX_LUMINANCE / ASCII_LEVELS);
        ascii_ready <= 1;
    end else begin
        ascii_ready <= 0;
    end
end

always_comb begin
    luminance_sum = 0;
    for (int i = 0; i < TILE_WIDTH; i++) begin
        for (int j = 0; j < TILE_HEIGHT; j++) begin
            luminance_sum = luminance_sum + luminance(tile_data[i][j]);
        end
    end
end


endmodule