interface axi_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 128,
    parameter MAX_BURSTS = 256
) (
    input logic clk,
    input logic rst
);

  // Write address channel
  logic [ADDR_WIDTH-1:0] AWADDR;
  logic                  AWVALID;
  logic                  AWREADY;
  logic [7:0]            AWLEN;
  logic [2:0]            AWSIZE;
  logic [1:0]            AWBURST;

  // Write data channel
  logic [DATA_WIDTH-1:0] WDATA;
  logic                  WVALID;
  logic                  WREADY;
  logic                  WLAST;
  logic [(DATA_WIDTH/8)-1:0] WSTRB;

  // Write response channel
  logic                  BVALID;
  logic                  BREADY;
  logic [1:0]            BRESP;

  // Read address channel
  logic [ADDR_WIDTH-1:0] ARADDR;
  logic                  ARVALID;
  logic                  ARREADY;
  logic [7:0]            ARLEN;
  logic [2:0]            ARSIZE;
  logic [1:0]            ARBURST;

  // Read data channel
  logic [DATA_WIDTH-1:0] RDATA;
  logic                  RVALID;
  logic                  RREADY;
  logic                  RLAST;
  logic [1:0]            RRESP;

  modport master (
    output AWADDR, AWVALID, AWLEN, AWSIZE, AWBURST,
    input  AWREADY,

    output WDATA, WVALID, WLAST, WSTRB,
    input  WREADY,

    input  BVALID, BRESP,
    output BREADY,

    output ARADDR, ARVALID, ARLEN, ARSIZE, ARBURST,
    input  ARREADY,

    input  RDATA, RVALID, RLAST, RRESP,
    output RREADY
  );

  modport slave (
    input  AWADDR, AWVALID, AWLEN, AWSIZE, AWBURST,
    output AWREADY,

    input  WDATA, WVALID, WLAST, WSTRB,
    output WREADY,

    output BVALID, BRESP,
    input  BREADY,

    input  ARADDR, ARVALID, ARLEN, ARSIZE, ARBURST,
    output ARREADY,

    output RDATA, RVALID, RLAST, RRESP,
    input  RREADY
  );

  task master_read(input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data[MAX_BURSTS-1:0]);
    @(posedge clk);
    ARADDR <= addr;
    ARVALID <= 1;
    while(!ARREADY) @(posedge clk);
    ARVALID <= 0;
    RREADY <= 1;
    while(!RVALID) @(posedge clk);
    data[0] <= RDATA;
    int i = 1;
    while(!RLAST && i<MAX_BURSTS) begin
        @(posedge clk);
        data[i++] <= RDATA;
    end
    @(posedge clk);
    RREADY <= 0;
  endtask
  task master_write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
    @(posedge clk);
  endtask
  
  

endinterface