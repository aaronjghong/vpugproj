module vga_memory (
    parameter ADDR_WIDTH = 19,
    parameter DATA_WIDTH = 24,
    input logic clk,
    input logic rst,
    input logic r_en,
    input logic [ADDR_WIDTH-1:0] r_addr,
    input logic w_en,
    input logic [ADDR_WIDTH-1:0] w_addr,
    input logic [DATA_WIDTH-1:0] w_data,
    output logic [DATA_WIDTH-1:0] r_data,
    output logic r_valid
);

logic [DATA_WIDTH-1:0] mem [0:1023999];

always @(posedge clk) begin
    if (rst) begin
        r_data <= {DATA_WIDTH{1'b0}};
        r_valid <= 0;
    end else if (w_en) begin
        mem[w_addr] <= w_data;
        r_valid <= 0;
    end else if (r_en) begin
        r_data <= mem[r_addr];
        r_valid <= 1;
    end else begin
        r_valid <= 0;
    end
end
endmodule