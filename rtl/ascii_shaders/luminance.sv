module luminance #(
    parameter COLORS = 3,
    parameter COLOR_DEPTH = 8,
    parameter DATA_WIDTH = COLORS * COLOR_DEPTH
) (
    input logic [DATA_WIDTH-1:0] pixel_data,
    output logic [DATA_WIDTH-1:0] luminance
);

logic [COLOR_DEPTH-1:0] r = pixel_data[COLOR_DEPTH*3-1:COLOR_DEPTH*2];
logic [COLOR_DEPTH-1:0] g = pixel_data[COLOR_DEPTH*2-1:COLOR_DEPTH];
logic [COLOR_DEPTH-1:0] b = pixel_data[COLOR_DEPTH-1:0];

assign luminance = (r+r+r+b+g+g+g+g)>>3;

endmodule