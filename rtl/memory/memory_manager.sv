`include "bram.sv"
`include "axi_if.sv"

module memory_manager #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 128,
    parameter MAX_BURSTS = 256,
    parameter FB_ROW_BUFFER_SIZE = 1024,

    parameter NUM_WARPS = 1024,
    parameter WARP_ID_WIDTH = 8,
    parameter WARP_WIDTH = 8,
    parameter WARP_HEIGHT = 8,
    parameter TILE_WIDTH = 8,
    parameter TILE_HEIGHT = 8,
    parameter FB_BASE_ADDR = 0,
    parameter WARP_BASE_ADDR = 0,
    parameter NUM_TILES = WARP_WIDTH * WARP_HEIGHT
) (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic is_warp,
    input logic [WARP_ID_WIDTH-1:0] warp_id,
    input logic warp_data_valid,
    input logic fb_data_valid,

    input memory_manager_connection.mm_slave warp_connection,
    input memory_manager_connection.mm_slave fb_connection,

    output logic warp_data_ready,
    output logic fb_data_ready,
    axi_if.master ext_mem_axi_if
);

logic [WARP_ID_WIDTH-1:0] warp_id_reg;
logic warp_data_valid_reg;
logic fb_data_valid_reg;
logic [ADDR_WIDTH-1:0] num_bursts; // Way too big in size but it's ok for now

enum logic [1:0] {
    IDLE,
    WRITING,
    FETCHING,
    DONE
} state;

initial begin
    warp_id_reg = 0;
    warp_data_valid_reg = 0;
    fb_data_valid_reg = 0;
    state = IDLE;
end

always (@posedge clk) begin
    if(rst) begin
        warp_data_ready <= 0;
        warp_id_reg <= 0;
        fb_data_ready <= 0;
        ext_mem_axi_if.master_init();
        state <= IDLE;
    end else if (enable) begin
        case(state)
            IDLE: begin
                
                num_bursts <= (BRAM_DEPTH + (MAX_BURSTS - 1)) / MAX_BURSTS;
            end
            WRITING: begin
                if(warp_connection.memory_manager_finished) begin
                    state <= FETCHING;
                end
            end

            FETCHING: begin
                if(warp_connection.read_done) begin
                    state <= DONE;
                end
            end
            DONE: begin
                state <= IDLE;
            end
        end
    end
end



// Takes 
// AXI interface logic


// Data ready signals
assign warp_data_ready = 1'b1;
assign fb_data_ready = 1'b1;

endmodule

interface memory_manager_connection #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 128,
    parameter MAX_BURSTS = 256,
    parameter BRAM_DEPTH = 1024
);

    bram_port.port bram;
    logic clk;
    logic rst;
    logic enable;
    logic dirty;
    logic done;
    logic memory_manager_finished;
    logic request_read;
    logic read_done;
    logic [ADDR_WIDTH-1:0] num_bursts;
    logic [ADDR_WIDTH-1:0] addr;

    modport mm_slave (
        input clk,
        input rst,
        input read_done,
        input memory_manager_finished,
        output bram,
        output enable,
        output dirty,
        output done,
        output addr,
        output request_read,
    );

    modport mm_master (
        input clk,
        input rst,
        input bram,
        input enable,
        input dirty,
        input done,
        input addr,
        input request_read,
        output memory_manager_finished,
        output read_done
    );


    task init();
        bram.init();
        dirty <= 0;
        done <= 0;
        memory_manager_finished <= 0;
        num_bursts <= (BRAM_DEPTH + (MAX_BURSTS - 1)) / MAX_BURSTS; // round up
        addr <= 0;
        request_read <= 0;
        read_done <= 0;
    endtask

    task fetch(input logic [ADDR_WIDTH-1:0] addr);
        @(posedge clk);
        if(dirty) begin
            write(bram.base_addr);
        end
        bram.we <= 0;
        bram.addr <= addr;
        request_read <= 1;
        while(!read_done) @(posedge clk);
        int i = 1;
        while(i < num_bursts) begin
            bram.addr <= addr + i * MAX_BURSTS;
            request_read <= 1;
            while(!read_done) @(posedge clk);
            i++;
        end
        request_read <= 0;
        done <= 1;
        memory_manager_finished <= 1;
    endtask

    task write(input logic [ADDR_WIDTH-1:0] addr);
        bram.addr <= addr;
        bram.we <= 1;
        bram.din <= data;
        done <= 1;
    endtask

    assign bram.en = enable;
    assign bram.clk = clk;

endinterface