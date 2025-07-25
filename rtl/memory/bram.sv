module bram #(
    parameter int ADDR_WIDTH = 10,
    parameter int DATA_WIDTH = 32,
    parameter int DEPTH = 1024
) (
    input logic clk_a, clk_b,
    input logic en_a, en_b,
    input logic we_a, we_b,
    input logic [ADDR_WIDTH-1:0] addr_a, addr_b,
    input logic [DATA_WIDTH-1:0] din_a, din_b,
    output logic [DATA_WIDTH-1:0] dout_a, dout_b
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always_ff @(posedge clk_a) begin
        if(en_a) begin
            if (we_a) begin
                mem[addr_a] <= din_a;
            end
            dout_a <= mem[addr_a];
        end
    end

    always_ff @(posedge clk_b) begin
        if(en_b) begin
            if (we_b) begin
                mem[addr_b] <= din_b;
            end
            dout_b <= mem[addr_b];
        end
    end

endmodule

interface bram_port #(
    parameter int ADDR_WIDTH = 10,
    parameter int DATA_WIDTH = 32,
    parameter int DEPTH = 1024
);
    logic clk;
    logic en;
    logic we;
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] din;
    logic [DATA_WIDTH-1:0] dout;
    logic base_addr;

    modport port (
        input clk, en, we, addr, din,
        inout base_addr,
        output dout
    );

    task init();
        dout = 0;
    endtask
endinterface