
`timescale 1ns/1ps

module top_ram #(
    // Parameters for DNN engine
    parameter   AXI_WIDTH         = 128,
                AXI_ID_WIDTH      = 6,
                AXI_STRB_WIDTH    = AXI_WIDTH/8,
                AXI_MAX_BURST_LEN = 32,
                AXI_ADDR_WIDTH    = 32,
                AXIL_WIDTH        = 32,
                AXIL_ADDR_WIDTH   = 40,
                STRB_WIDTH        = 4,
                AXIL_BASE_ADDR    = 32'hA0000000,
                OPT_LOCK          = 1'b0,
                OPT_LOCKID        = 1'b1,
                OPT_LOWPOWER      = 1'b0,
    // Randomizer for AXI4 requests
                VALID_PROB        = 10,
                READY_PROB        = 10,

    localparam  LSB = $clog2(AXI_WIDTH)-3
)(
    // axilite interface for configuration
    input  wire                   clk,
    input  wire                   rstn,

    //AXI-Lite slave interface
    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]                  s_axil_awprot,
    input  wire                        s_axil_awvalid,
    output wire                        s_axil_awready,
    input  wire [AXIL_WIDTH-1:0]       s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]       s_axil_wstrb,
    input  wire                        s_axil_wvalid,
    output wire                        s_axil_wready,
    output wire [1:0]                  s_axil_bresp,
    output wire                        s_axil_bvalid,
    input  wire                        s_axil_bready,
    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]                  s_axil_arprot,
    input  wire                        s_axil_arvalid,
    output wire                        s_axil_arready,
    output wire [AXIL_WIDTH-1:0]       s_axil_rdata,
    output wire [1:0]                  s_axil_rresp,
    output wire                        s_axil_rvalid,
    input  wire                        s_axil_rready,
    
    // ram rw interface for interacting with DDR in sim
    output wire                            mm2s_ren,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  mm2s_addr,
    input  wire  [AXI_WIDTH-1:0]           mm2s_data,

    output wire                            s2mm_wen,
    output wire  [AXI_ADDR_WIDTH-LSB-1:0]  s2mm_addr,
    output wire  [AXI_WIDTH-1:0]           s2mm_data,
    output wire  [AXI_WIDTH/8-1:0]         s2mm_strb
);

// AXI ports from top on-chip module

    wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_arid;
    wire [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_araddr;
    wire [7:0]                 m_axi_mm2s_arlen;
    wire [2:0]                 m_axi_mm2s_arsize;
    wire [1:0]                 m_axi_mm2s_arburst;
    wire                       m_axi_mm2s_arlock;
    wire [3:0]                 m_axi_mm2s_arcache;
    wire [2:0]                 m_axi_mm2s_arprot;
    wire                       m_axi_mm2s_arvalid;
    wire                       m_axi_mm2s_arvalid_zipcpu;
    wire                       m_axi_mm2s_arready;
    wire                       m_axi_mm2s_arready_zipcpu;
    wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_rid;
    wire [AXI_WIDTH-1:0]       m_axi_mm2s_rdata;
    wire [1:0]                 m_axi_mm2s_rresp;
    wire                       m_axi_mm2s_rlast;
    wire                       m_axi_mm2s_rvalid;
    wire                       m_axi_mm2s_rvalid_zipcpu;
    wire                       m_axi_mm2s_rready;
    wire                       m_axi_mm2s_rready_zipcpu;

    wire [AXI_ID_WIDTH-1:0]    m_axi_s2mm_awid;
    wire [AXI_ADDR_WIDTH-1:0]  m_axi_s2mm_awaddr;
    wire [7:0]                 m_axi_s2mm_awlen;
    wire [2:0]                 m_axi_s2mm_awsize;
    wire [1:0]                 m_axi_s2mm_awburst;
    wire                       m_axi_s2mm_awlock;
    wire [3:0]                 m_axi_s2mm_awcache;
    wire [2:0]                 m_axi_s2mm_awprot;
    wire                       m_axi_s2mm_awvalid;
    wire                       m_axi_s2mm_awvalid_zipcpu;
    wire                       m_axi_s2mm_awready;
    wire                       m_axi_s2mm_awready_zipcpu;
    wire [AXI_WIDTH-1:0]       m_axi_s2mm_wdata;
    wire [AXI_STRB_WIDTH-1:0]  m_axi_s2mm_wstrb;
    wire                       m_axi_s2mm_wlast;
    wire                       m_axi_s2mm_wvalid;
    wire                       m_axi_s2mm_wvalid_zipcpu;
    wire                       m_axi_s2mm_wready;
    wire                       m_axi_s2mm_wready_zipcpu;
    wire [AXI_ID_WIDTH-1:0]    m_axi_s2mm_bid;
    wire [1:0]                 m_axi_s2mm_bresp;
    wire                       m_axi_s2mm_bvalid;
    wire                       m_axi_s2mm_bvalid_zipcpu;
    wire                       m_axi_s2mm_bready;
    wire                       m_axi_s2mm_bready_zipcpu;

    logic rand_mm2s_ar;
    logic rand_mm2s_r;
    logic rand_s2mm_aw;
    logic rand_s2mm_w;
    logic rand_s2mm_b;

    // Randomizer for AXI4 requests
    always_ff @( posedge clk ) begin
        rand_mm2s_r   <= $urandom_range(0, 1000) < VALID_PROB;
        rand_mm2s_ar  <= $urandom_range(0, 1000) < VALID_PROB;
        rand_s2mm_aw  <= $urandom_range(0, 1000) < READY_PROB;
        rand_s2mm_w   <= $urandom_range(0, 1000) < READY_PROB;
        rand_s2mm_b   <= $urandom_range(0, 1000) < READY_PROB;
    end

    assign m_axi_mm2s_arvalid_zipcpu = rand_mm2s_ar & m_axi_mm2s_arvalid;
    assign m_axi_mm2s_arready        = rand_mm2s_ar & m_axi_mm2s_arready_zipcpu;
    assign m_axi_mm2s_rvalid         = rand_mm2s_r  & m_axi_mm2s_rvalid_zipcpu;
    assign m_axi_mm2s_rready_zipcpu  = rand_mm2s_r  & m_axi_mm2s_rready;

    assign m_axi_s2mm_awvalid_zipcpu = rand_s2mm_aw & m_axi_s2mm_awvalid;
    assign m_axi_s2mm_awready        = rand_s2mm_aw & m_axi_s2mm_awready_zipcpu;
    assign m_axi_s2mm_wvalid_zipcpu  = rand_s2mm_w  & m_axi_s2mm_wvalid;
    assign m_axi_s2mm_wready         = rand_s2mm_w  & m_axi_s2mm_wready_zipcpu;
    assign m_axi_s2mm_bvalid         = rand_s2mm_b  & m_axi_s2mm_bvalid_zipcpu;
    assign m_axi_s2mm_bready_zipcpu  = rand_s2mm_b  & m_axi_s2mm_bready;


zipcpu_axi2ram #(
    .C_S_AXI_ID_WIDTH(AXI_ID_WIDTH),
    .C_S_AXI_DATA_WIDTH(AXI_WIDTH),
    .C_S_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .OPT_LOCK(OPT_LOCK),
    .OPT_LOCKID(OPT_LOCKID),
    .OPT_LOWPOWER(OPT_LOWPOWER)
) ZIP_mm2s (
    .o_we(),
    .o_waddr(),
    .o_wdata(),
    .o_wstrb(),
    .o_rd(mm2s_ren),
    .o_raddr(mm2s_addr),
    .i_rdata(mm2s_data),
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(rstn),
    .S_AXI_AWID(),
    .S_AXI_AWADDR(),
    .S_AXI_AWLEN(),
    .S_AXI_AWSIZE(),
    .S_AXI_AWBURST(),
    .S_AXI_AWLOCK(),
    .S_AXI_AWCACHE(),
    .S_AXI_AWPROT(),
    .S_AXI_AWQOS(),
    .S_AXI_AWVALID('0),
    .S_AXI_AWREADY(),
    .S_AXI_WDATA(),
    .S_AXI_WSTRB(),
    .S_AXI_WLAST(),
    .S_AXI_WVALID(1'b0),
    .S_AXI_WREADY(),
    .S_AXI_BID(),
    .S_AXI_BRESP(),
    .S_AXI_BVALID(),
    .S_AXI_BREADY(),
    .S_AXI_ARID(m_axi_mm2s_arid),
    .S_AXI_ARADDR(m_axi_mm2s_araddr),
    .S_AXI_ARLEN(m_axi_mm2s_arlen),
    .S_AXI_ARSIZE(m_axi_mm2s_arsize),
    .S_AXI_ARBURST(m_axi_mm2s_arburst),
    .S_AXI_ARLOCK(m_axi_mm2s_arlock),
    .S_AXI_ARCACHE(m_axi_mm2s_arcache),
    .S_AXI_ARPROT(m_axi_mm2s_arprot),
    .S_AXI_ARQOS(),
    .S_AXI_ARVALID(m_axi_mm2s_arvalid_zipcpu),
    .S_AXI_ARREADY(m_axi_mm2s_arready_zipcpu),
    .S_AXI_RID(m_axi_mm2s_rid),
    .S_AXI_RDATA(m_axi_mm2s_rdata),
    .S_AXI_RRESP(m_axi_mm2s_rresp),
    .S_AXI_RLAST(m_axi_mm2s_rlast),
    .S_AXI_RVALID(m_axi_mm2s_rvalid_zipcpu),
    .S_AXI_RREADY(m_axi_mm2s_rready_zipcpu)
);

zipcpu_axi2ram #(
    .C_S_AXI_ID_WIDTH(AXI_ID_WIDTH),
    .C_S_AXI_DATA_WIDTH(AXI_WIDTH),
    .C_S_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .OPT_LOCK(OPT_LOCK),
    .OPT_LOCKID(OPT_LOCKID),
    .OPT_LOWPOWER(OPT_LOWPOWER)
) ZIP_s2mm (
    .o_we(s2mm_wen),
    .o_waddr(s2mm_addr),
    .o_wdata(s2mm_data),
    .o_wstrb(s2mm_strb),
    .o_rd(),
    .o_raddr(),
    .i_rdata(),
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(rstn),
    .S_AXI_AWID(m_axi_s2mm_awid),
    .S_AXI_AWADDR(m_axi_s2mm_awaddr),
    .S_AXI_AWLEN(m_axi_s2mm_awlen),
    .S_AXI_AWSIZE(m_axi_s2mm_awsize),
    .S_AXI_AWBURST(m_axi_s2mm_awburst),
    .S_AXI_AWLOCK(m_axi_s2mm_awlock),
    .S_AXI_AWCACHE(m_axi_s2mm_awcache),
    .S_AXI_AWPROT(m_axi_s2mm_awprot),
    .S_AXI_AWQOS(),
    .S_AXI_AWVALID(m_axi_s2mm_awvalid_zipcpu),
    .S_AXI_AWREADY(m_axi_s2mm_awready_zipcpu),
    .S_AXI_WDATA(m_axi_s2mm_wdata),
    .S_AXI_WSTRB(m_axi_s2mm_wstrb),
    .S_AXI_WLAST(m_axi_s2mm_wlast),
    .S_AXI_WVALID(m_axi_s2mm_wvalid_zipcpu),
    .S_AXI_WREADY(m_axi_s2mm_wready_zipcpu),
    .S_AXI_BID(m_axi_s2mm_bid),
    .S_AXI_BRESP(m_axi_s2mm_bresp),
    .S_AXI_BVALID(m_axi_s2mm_bvalid_zipcpu),
    .S_AXI_BREADY(m_axi_s2mm_bready_zipcpu),
    .S_AXI_ARID(),
    .S_AXI_ARADDR(),
    .S_AXI_ARLEN(),
    .S_AXI_ARSIZE(),
    .S_AXI_ARBURST(),
    .S_AXI_ARLOCK(),
    .S_AXI_ARCACHE(),
    .S_AXI_ARPROT(),
    .S_AXI_ARQOS(),
    .S_AXI_ARVALID(1'b0),
    .S_AXI_ARREADY(),
    .S_AXI_RID(),
    .S_AXI_RDATA(),
    .S_AXI_RRESP(),
    .S_AXI_RLAST(),
    .S_AXI_RVALID(),
    .S_AXI_RREADY(1'b0)
);

top #(
    .AXI_WIDTH        (AXI_WIDTH        ),
    .AXI_ID_WIDTH     (AXI_ID_WIDTH     ),
    .AXI_STRB_WIDTH   (AXI_STRB_WIDTH   ),
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .AXI_ADDR_WIDTH   (AXI_ADDR_WIDTH   ),
    .AXIL_WIDTH       (AXIL_WIDTH       ),
    .AXIL_ADDR_WIDTH  (AXIL_ADDR_WIDTH  ),
    .STRB_WIDTH       (STRB_WIDTH       ),
    .AXIL_BASE_ADDR   (AXIL_BASE_ADDR   )
) TOP (
    .*
);

endmodule