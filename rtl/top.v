`timescale 1ns/1ps

module top #(
    parameter   // Full AXI
                AXI_WIDTH               = 128,
                AXI_ID_WIDTH            = 6,
                AXI_STRB_WIDTH          = (AXI_WIDTH/8),
                AXI_MAX_BURST_LEN       = 32,
                AXI_ADDR_WIDTH          = 32,
                AXIS_USER_WIDTH         = 8,         
                // AXI-Lite
                AXIL_WIDTH              = 32,
                AXIL_ADDR_WIDTH         = 40,
                STRB_WIDTH              = 4,
                AXIL_BASE_ADDR          = 32'hA0000000

) (
    // axilite interface for configuration
    input  wire                   clk,
    input  wire                   rstn,

    /*
     * AXI-Lite slave interface
     */
    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]             s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,
    input  wire [AXIL_WIDTH-1:0]  s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,
    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,
    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [AXIL_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,
    /*
        * AXI 4 Master interface
    */
    // Weights
    output wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_arid,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_mm2s_araddr,
    output wire [7:0]                 m_axi_mm2s_arlen,
    output wire [2:0]                 m_axi_mm2s_arsize,
    output wire [1:0]                 m_axi_mm2s_arburst,
    output wire                       m_axi_mm2s_arlock,
    output wire [3:0]                 m_axi_mm2s_arcache,
    output wire [2:0]                 m_axi_mm2s_arprot,
    output wire                       m_axi_mm2s_arvalid,
    input  wire                       m_axi_mm2s_arready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_mm2s_rid,
    input  wire [AXI_WIDTH   -1:0]    m_axi_mm2s_rdata,
    input  wire [1:0]                 m_axi_mm2s_rresp,
    input  wire                       m_axi_mm2s_rlast,
    input  wire                       m_axi_mm2s_rvalid,
    output wire                       m_axi_mm2s_rready,

    // Output
    // (* mark_debug = "true" *) 
    output wire [AXI_ID_WIDTH-1:0]    m_axi_s2mm_awid,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_s2mm_awaddr,
    output wire [7:0]                 m_axi_s2mm_awlen,
    output wire [2:0]                 m_axi_s2mm_awsize,
    output wire [1:0]                 m_axi_s2mm_awburst,
    output wire                       m_axi_s2mm_awlock,
    output wire [3:0]                 m_axi_s2mm_awcache,
    output wire [2:0]                 m_axi_s2mm_awprot,
    output wire                       m_axi_s2mm_awvalid,
    input  wire                       m_axi_s2mm_awready,
    output wire [AXI_WIDTH   -1:0]    m_axi_s2mm_wdata,
    output wire [AXI_STRB_WIDTH-1:0]  m_axi_s2mm_wstrb,
    output wire                       m_axi_s2mm_wlast,
    output wire                       m_axi_s2mm_wvalid,
    input  wire                       m_axi_s2mm_wready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_s2mm_bid,
    input  wire [1:0]                 m_axi_s2mm_bresp,
    input  wire                       m_axi_s2mm_bvalid,
    output wire                       m_axi_s2mm_bready
);

// Loopback

wire s_axis_mm2s_tready;
wire s_axis_mm2s_tvalid;
wire s_axis_mm2s_tlast ;
wire [AXI_WIDTH      -1:0] s_axis_mm2s_tdata;
wire [AXI_WIDTH/8    -1:0] s_axis_mm2s_tkeep;
wire [AXIS_USER_WIDTH-1:0] s_axis_mm2s_tuser;
wire m_axis_s2mm_tready;
wire m_axis_s2mm_tvalid;
wire m_axis_s2mm_tlast ;
wire [AXI_WIDTH   -1:0] m_axis_s2mm_tdata;
wire [AXI_WIDTH/8 -1:0] m_axis_s2mm_tkeep;

assign s_axis_mm2s_tready = m_axis_s2mm_tready;
assign m_axis_s2mm_tvalid = s_axis_mm2s_tvalid;
assign m_axis_s2mm_tlast  = s_axis_mm2s_tlast;
assign m_axis_s2mm_tdata  = s_axis_mm2s_tdata;
assign m_axis_s2mm_tkeep  = s_axis_mm2s_tkeep;



localparam      AXI_LEN_WIDTH           = 32,
                TIMEOUT                 = 2, // since 0 gives error

    // Alex AXI DMA RD                
                AXIS_ID_WIDTH           = 6,
                AXIS_KEEP_ENABLE        = 1,//(AXI_WIDTH>8),
                AXIS_KEEP_WIDTH         = (AXI_WIDTH/8),//(AXI_WIDTH/8),
                AXIS_LAST_ENABLE        = 1,
                AXIS_ID_ENABLE          = 0,
                AXIS_DEST_ENABLE        = 0,
                AXIS_DEST_WIDTH         = 8,
                LEN_WIDTH               = 32,
                TAG_WIDTH               = 8,
                ENABLE_SG               = 0,
                ENABLE_UNALIGNED        = 1;
    

// Wires connecting AXIL2RAM to CONTROLLER
wire [AXIL_ADDR_WIDTH-1:0] reg_wr_addr;
wire [AXIL_WIDTH-1:0] reg_wr_data;
wire [STRB_WIDTH-1:0] reg_wr_strb;
wire reg_wr_en;
wire [AXIL_ADDR_WIDTH-1:0] reg_rd_addr;
wire reg_rd_en;
wire [AXIL_WIDTH-1:0] reg_rd_data;

// Controller with Alex DMAs: desc signals (including od tag) and status signals
wire [AXI_ADDR_WIDTH+AXI_LEN_WIDTH-1:0] s2mm_desc_tdata;
wire [TAG_WIDTH-1:0]                    s2mm_desc_tag;
wire                                    s2mm_desc_tvalid;
wire                                    s2mm_desc_tready;
wire [TAG_WIDTH-1:0]                    s2mm_status_tag;
wire [3:0]                              s2mm_status_error;
wire                                    s2mm_status_valid;

wire [AXI_ADDR_WIDTH+AXI_LEN_WIDTH-1:0] mm2s_desc_tdata;
wire [AXIS_USER_WIDTH-1:0]              mm2s_desc_tuser;
wire                                    mm2s_desc_tvalid;
wire                                    mm2s_desc_tready;
wire [3:0]                              mm2s_status_error;
wire                                    mm2s_status_valid;

wire [AXIL_ADDR_WIDTH-1:0] AXIL_BASE_ADDR_lw = AXIL_BASE_ADDR;
wire [AXIL_ADDR_WIDTH-1:0] reg_wr_addr_ctrl = (reg_wr_addr-AXIL_BASE_ADDR_lw) >> 2;
wire [AXIL_ADDR_WIDTH-1:0] reg_rd_addr_ctrl = (reg_rd_addr-AXIL_BASE_ADDR_lw) >> 2;



alex_axilite_ram #(
    .DATA_WR_WIDTH(AXIL_WIDTH),
    .DATA_RD_WIDTH(AXIL_WIDTH),
    .ADDR_WIDTH(AXIL_ADDR_WIDTH),
    .STRB_WIDTH(STRB_WIDTH),
    .TIMEOUT(TIMEOUT)
) AXIL2RAM (
    .clk(clk),
    .rstn(rstn),
    .s_axil_awaddr(s_axil_awaddr),
    .s_axil_awprot(s_axil_awprot),
    .s_axil_awvalid(s_axil_awvalid),
    .s_axil_awready(s_axil_awready),
    .s_axil_wdata(s_axil_wdata),
    .s_axil_wstrb(s_axil_wstrb),
    .s_axil_wvalid(s_axil_wvalid),
    .s_axil_wready(s_axil_wready),
    .s_axil_bresp(s_axil_bresp),
    .s_axil_bvalid(s_axil_bvalid),
    .s_axil_bready(s_axil_bready),
    .s_axil_araddr(s_axil_araddr),
    .s_axil_arprot(s_axil_arprot),
    .s_axil_arvalid(s_axil_arvalid),
    .s_axil_arready(s_axil_arready),
    .s_axil_rdata(s_axil_rdata),
    .s_axil_rresp(s_axil_rresp),
    .s_axil_rvalid(s_axil_rvalid),
    .s_axil_rready(s_axil_rready),
    .reg_wr_addr(reg_wr_addr),
    .reg_wr_data(reg_wr_data),
    .reg_wr_strb(reg_wr_strb),
    .reg_wr_en(reg_wr_en),
    .reg_wr_wait(1'b0),
    .reg_wr_ack(1'b1),
    .reg_rd_addr(reg_rd_addr),
    .reg_rd_en(reg_rd_en),
    .reg_rd_data(reg_rd_data),
    .reg_rd_wait(1'b0),
    .reg_rd_ack(1'b1)
);

dma_controller #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
    .AXI_DATA_WIDTH(AXIL_WIDTH),
    .AXI_LEN_WIDTH(AXI_LEN_WIDTH),
    .AXI_TAG_WIDTH(TAG_WIDTH)
) CONTROLLER (
    .clk(clk),
    .rstn(rstn),

    .reg_wr_en  (reg_wr_en),
    .reg_wr_addr(reg_wr_addr_ctrl[AXI_ADDR_WIDTH-1:0]),
    .reg_wr_data(reg_wr_data),
    .reg_rd_en  (reg_rd_en),
    .reg_rd_addr(reg_rd_addr_ctrl[AXI_ADDR_WIDTH-1:0]),
    .reg_rd_data(reg_rd_data),

    .s2mm_desc (s2mm_desc_tdata  ),
    .s2mm_tag  (s2mm_desc_tag    ),
    .s2mm_valid(s2mm_desc_tvalid ),
    .s2mm_ready(s2mm_desc_tready ),
    .s2mm_status_error(s2mm_status_error),
    .s2mm_status_valid(s2mm_status_valid),

    .mm2s_desc (mm2s_desc_tdata ),
    .mm2s_user (mm2s_desc_tuser ),
    .mm2s_valid(mm2s_desc_tvalid),
    .mm2s_ready(mm2s_desc_tready),
    .mm2s_status_error(mm2s_status_error),
    .mm2s_status_valid(mm2s_status_valid)
);

alex_axi_dma_rd #(
    .AXI_DATA_WIDTH(AXI_WIDTH   ),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .AXIS_DATA_WIDTH(AXI_WIDTH),
    .AXIS_KEEP_ENABLE(AXIS_KEEP_ENABLE),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_LAST_ENABLE(AXIS_LAST_ENABLE),
    .AXIS_ID_ENABLE(AXIS_ID_ENABLE),
    .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
    .AXIS_DEST_ENABLE(AXIS_DEST_ENABLE),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
    .AXIS_USER_ENABLE(1),
    .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
    .LEN_WIDTH(LEN_WIDTH),
    .TAG_WIDTH(TAG_WIDTH),
    .ENABLE_SG(ENABLE_SG),
    .ENABLE_UNALIGNED(ENABLE_UNALIGNED)
) MM2S_DMA (
    .clk(clk),
    .rstn(rstn),
    .s_axis_read_desc_tdata(mm2s_desc_tdata),
    .s_axis_read_desc_tag({TAG_WIDTH{1'b0}}),
    .s_axis_read_desc_tid({AXI_ID_WIDTH{1'b0}}),
    .s_axis_read_desc_tdest({AXIS_DEST_WIDTH{1'b0}}),
    .s_axis_read_desc_tuser(mm2s_desc_tuser),
    .s_axis_read_desc_tvalid(mm2s_desc_tvalid),
    .s_axis_read_desc_tready(mm2s_desc_tready),
    .m_axis_read_desc_status_tag(),
    .m_axis_read_desc_status_error(mm2s_status_error),
    .m_axis_read_desc_status_valid(mm2s_status_valid),

    // External Stream
    .m_axis_read_data_tdata(s_axis_mm2s_tdata),
    .m_axis_read_data_tkeep(s_axis_mm2s_tkeep),
    .m_axis_read_data_tvalid(s_axis_mm2s_tvalid),
    .m_axis_read_data_tready(s_axis_mm2s_tready),
    .m_axis_read_data_tlast(s_axis_mm2s_tlast),
    .m_axis_read_data_tid(),
    .m_axis_read_data_tdest(),
    .m_axis_read_data_tuser(s_axis_mm2s_tuser),
    // External AXI
    .m_axi_arid(m_axi_mm2s_arid),
    .m_axi_araddr(m_axi_mm2s_araddr),
    .m_axi_arlen(m_axi_mm2s_arlen),
    .m_axi_arsize(m_axi_mm2s_arsize),
    .m_axi_arburst(m_axi_mm2s_arburst),
    .m_axi_arlock(m_axi_mm2s_arlock),
    .m_axi_arcache(m_axi_mm2s_arcache),
    .m_axi_arprot(m_axi_mm2s_arprot),
    .m_axi_arvalid(m_axi_mm2s_arvalid),
    .m_axi_arready(m_axi_mm2s_arready),
    .m_axi_rid(m_axi_mm2s_rid),
    .m_axi_rdata(m_axi_mm2s_rdata),
    .m_axi_rresp(m_axi_mm2s_rresp),
    .m_axi_rlast(m_axi_mm2s_rlast),
    .m_axi_rvalid(m_axi_mm2s_rvalid),
    .m_axi_rready(m_axi_mm2s_rready),
    .enable(1'b1)
);

alex_axi_dma_wr #(
    .AXI_DATA_WIDTH(AXI_WIDTH   ),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .AXIS_DATA_WIDTH(AXI_WIDTH),
    .AXIS_KEEP_ENABLE(AXIS_KEEP_ENABLE),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_LAST_ENABLE(AXIS_LAST_ENABLE),
    .AXIS_ID_ENABLE(AXIS_ID_ENABLE),
    .AXIS_ID_WIDTH(AXIS_ID_WIDTH),
    .AXIS_DEST_ENABLE(AXIS_DEST_ENABLE),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),
    .AXIS_USER_ENABLE(0),
    .AXIS_USER_WIDTH(AXIS_USER_WIDTH),
    .LEN_WIDTH(LEN_WIDTH),
    .TAG_WIDTH(TAG_WIDTH),
    .ENABLE_SG(ENABLE_SG),
    .ENABLE_UNALIGNED(ENABLE_UNALIGNED)
) S2MM_DMA (
    .clk(clk),
    .rstn(rstn),
    .s_axis_write_desc_tdata       (s2mm_desc_tdata  ),
    .s_axis_write_desc_tag         (s2mm_desc_tag    ),
    .s_axis_write_desc_tvalid      (s2mm_desc_tvalid ),
    .s_axis_write_desc_tready      (s2mm_desc_tready ),
    .m_axis_write_desc_status_len  (                 ),
    .m_axis_write_desc_status_tag  (s2mm_status_tag  ),
    .m_axis_write_desc_status_id   (                 ),
    .m_axis_write_desc_status_dest (                 ),
    .m_axis_write_desc_status_user (                 ),
    .m_axis_write_desc_status_error(s2mm_status_error),
    .m_axis_write_desc_status_valid(s2mm_status_valid),

    // External Stream
    .s_axis_write_data_tdata (m_axis_s2mm_tdata),
    .s_axis_write_data_tkeep (m_axis_s2mm_tkeep),
    .s_axis_write_data_tvalid(m_axis_s2mm_tvalid),
    .s_axis_write_data_tready(m_axis_s2mm_tready),
    .s_axis_write_data_tlast (m_axis_s2mm_tlast),
    .s_axis_write_data_tid   (),
    .s_axis_write_data_tdest (),
    .s_axis_write_data_tuser (),
    // External AXI
    .m_axi_awid(m_axi_s2mm_awid),
    .m_axi_awaddr(m_axi_s2mm_awaddr),
    .m_axi_awlen(m_axi_s2mm_awlen),
    .m_axi_awsize(m_axi_s2mm_awsize),
    .m_axi_awburst(m_axi_s2mm_awburst),
    .m_axi_awlock(m_axi_s2mm_awlock),
    .m_axi_awcache(m_axi_s2mm_awcache),
    .m_axi_awprot(m_axi_s2mm_awprot),
    .m_axi_awvalid(m_axi_s2mm_awvalid),
    .m_axi_awready(m_axi_s2mm_awready),
    .m_axi_wdata(m_axi_s2mm_wdata),
    .m_axi_wstrb(m_axi_s2mm_wstrb),
    .m_axi_wlast(m_axi_s2mm_wlast),
    .m_axi_wvalid(m_axi_s2mm_wvalid),
    .m_axi_wready(m_axi_s2mm_wready),
    .m_axi_bid(m_axi_s2mm_bid),
    .m_axi_bresp(m_axi_s2mm_bresp),
    .m_axi_bvalid(m_axi_s2mm_bvalid),
    .m_axi_bready(m_axi_s2mm_bready),
    .enable(1'b1),
    .abort(1'b0)
);

endmodule
