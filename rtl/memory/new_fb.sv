`include "bram.sv"

module fb #(
    parameter ADDR_WIDTH = 32, 
    parameter DISPLAY_WIDTH = 640, 
    parameter DISPLAY_HEIGHT = 480, 
    parameter COLORS = 3, 
    parameter COLOR_DEPTH = 8 ,
    parameter DATA_WIDTH = COLORS * COLOR_DEPTH
) (
    input logic clk,
    input logic rst,
    input logic en,
    input logic we,
    input logic current_bram,
    input bram_port.port bram_port,
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic data_out_valid
);
// Assume BRAM buffer is already connected to the bram_port and is of depth 2 * DISPLAY_WIDTH
logic [ADDR_WIDTH-1:0] curr_addr = addr + (current_bram ? DISPLAY_WIDTH : 0);
logic [DATA_WIDTH-1:0] curr_data;

always_ff @(posedge clk) begin
    if(rst) begin
        curr_addr <= 0;
        curr_data <= 0;
        data_out_valid <= 0;
    end else begin
        curr_addr <= addr;
        curr_data <= data;
        data_out_valid <= 1;
    end
end

assign bram_port.port.clk = clk;
assign bram_port.port.en = en;
assign bram_port.port.we = we;
assign bram_port.port.addr = curr_addr;
assign bram_port.port.din = curr_data;
assign data_out = bram_port.port.dout;
endmodule