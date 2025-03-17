`timescale 1ns/1ps

module dma_controller #(
  parameter
    AXI_ADDR_WIDTH     = 32  ,
    AXI_DATA_WIDTH     = 32  ,
    AXIS_USER_WIDTH    = 65  ,
    AXI_LEN_WIDTH      = 32  ,
    AXI_TAG_WIDTH      = 8   ,
  
  localparam 
    DESC_WIDTH = AXI_ADDR_WIDTH + AXI_LEN_WIDTH
)(
  input  logic clk,
  input  logic rstn,

  // SRAM port
  // (* mark_debug = "true" *) 
  input  logic reg_wr_en, reg_rd_en,
  input  logic [AXI_ADDR_WIDTH-1:0] reg_wr_addr, reg_rd_addr,
  input  logic [AXI_DATA_WIDTH-1:0] reg_wr_data,
  output logic [AXI_DATA_WIDTH-1:0] reg_rd_data,

  // S2MM descriptor
  output logic [DESC_WIDTH    -1:0]  s2mm_desc ,
  output logic [AXI_TAG_WIDTH -1:0]  s2mm_tag  ,
  output logic                       s2mm_valid,
  input  logic                       s2mm_ready,
  input  logic  [3:0]                s2mm_status_error,
  input  logic                       s2mm_status_valid,

  // MM2S descriptor
  output logic [DESC_WIDTH     -1:0] mm2s_desc,
  output logic [AXIS_USER_WIDTH-1:0] mm2s_user ,
  output logic                       mm2s_valid,
  input  logic                       mm2s_ready,
  input  logic  [3:0]                mm2s_status_error,
  input  logic                       mm2s_status_valid
);

  // Register 

  localparam 
    A_START     = 'h0,

    A_MM2S_DONE = 'h1,
    A_MM2S_ADDR = 'h2,
    A_MM2S_BYTES= 'h3,
    A_MM2S_TUSER= 'h4,

    A_S2MM_DONE = 'h5,
    A_S2MM_ADDR = 'h6,
    A_S2MM_BYTES= 'h7
    ;
  logic [7:0][AXI_DATA_WIDTH-1:0] cfg ;

  always_ff @(posedge clk)  // PS READ (1 clock latency)
    if (!rstn)          reg_rd_data <= '0;
    else if (reg_rd_en) reg_rd_data <= cfg[reg_rd_addr];
  
  // MM2S Controller
  logic mm2s_done;
  logic [AXI_ADDR_WIDTH-1:0] mm2s_addr;
  logic [AXI_LEN_WIDTH -1:0] mm2s_len ;

  always_comb begin 
    mm2s_addr  = cfg[A_MM2S_ADDR];
    mm2s_user  = AXIS_USER_WIDTH'(cfg[A_MM2S_TUSER]);
    mm2s_len   = cfg[A_MM2S_BYTES];
    mm2s_valid = 1'(cfg[A_START]) && s2mm_ready;
    mm2s_done  = mm2s_status_valid && (mm2s_status_error == 4'b0);
    {mm2s_len, mm2s_addr} = mm2s_desc;
  end

  // S2MM Controller
  logic s2mm_done;
  logic [AXI_ADDR_WIDTH-1:0] s2mm_addr;
  logic [AXI_LEN_WIDTH -1:0] s2mm_len ;

  always_comb begin 
    s2mm_addr  = cfg[A_S2MM_ADDR];
    s2mm_len   = cfg[A_S2MM_BYTES];
    s2mm_valid = 1'(cfg[A_START]) && mm2s_ready;
    s2mm_done  = s2mm_status_valid && (s2mm_status_error == 4'b0);
    {s2mm_len, s2mm_addr} = s2mm_desc;
  end

  always_ff @(posedge clk) // All cfg written in this always block
    if (!rstn) cfg <= '0;
    else begin
      if (mm2s_done)
        cfg[A_MM2S_DONE] <= 1;
      if (s2mm_done)
        cfg[A_S2MM_DONE] <= 1;
      if (cfg[A_START][0]) 
        cfg[A_START] <= 0; // written by PS after all config, stays high for only 1 clock

      if (reg_wr_en) // PS has priority in writing to registers
        cfg[reg_wr_addr] <= reg_wr_data;
    end
endmodule
