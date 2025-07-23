// Need axi first

module fb #(
    parameter ADDR_WIDTH = 32, 
    DATA_WIDTH = 128, 
    MAX_BURSTS = 256, 
    DISPLAY_WIDTH = 1024, 
    DISPLAY_HEIGHT = 768, 
    COLORS = 3, 
    COLOR_DEPTH = 8 
) (
    input logic clk,
    input logic rst,
    axi_if.master axi_if_inst
);

// Assume clock and reset are already connected by whoever is instantiating this module
localparam DATA_BYTES = DATA_WIDTH/8;
localparam AXI_SIZE = $clog2(DATA_BYTES);
localparam AXI_BURST = 2'b01; // INCR
localparam ALIGNED_DATA_WIDTH = 2 ** $clog2(DATA_WIDTH);
localparam NUM_BANKS = DATA_WIDTH / ALIGNED_DATA_WIDTH; // number of pixels retrieved per axi beat
localparam ALIGNED_DISPLAY_WIDTH = (DISPLAY_WIDTH + NUM_BANKS - 1) / NUM_BANKS * NUM_BANKS; // number of pixels retrieved per axi burst
localparam AXI_LEN = ALIGNED_DISPLAY_WIDTH / NUM_BANKS; // number of axi beats per axi burst

logic [ADDR_WIDTH-1:0] addr;
logic [DATA_WIDTH-1:0] data[AXI_LEN-1:0];
logic we;
logic re;
logic [DATA_WIDTH-1:0] data_out;


always @(posedge clk) begin
    if(rst) begin
        addr <= 0;
        we <= 0;
        re <= 0;
    end else begin
        if(we) begin
            axi_if_inst.master_write(addr, data);
        end
        if(re) begin
            // Set LEN, SIZE, BURST
            axi_if_inst.ARLEN <= AXI_LEN;
            axi_if_inst.ARSIZE <= AXI_SIZE;
            axi_if_inst.ARBURST <= AXI_BURST;
            axi_if_inst.master_read(addr, data);
        end
    end
end

endmodule