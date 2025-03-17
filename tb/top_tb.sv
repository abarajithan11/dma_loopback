`timescale 1ns/1ps

module top_tb;
  localparam  AXIL_ADDR_WIDTH     = 40,
              DATA_WR_WIDTH       = 32,
              STRB_WIDTH          = 4,
              DATA_RD_WIDTH       = 32,
              AXI_WIDTH	          = 128,
              AXI_ADDR_WIDTH	  = 32,
              CLK_PERIOD          = 10,
              LSB                 = $clog2(AXI_WIDTH)-3;             


  // SIGNALS
  logic rstn = 0;
  logic [AXIL_ADDR_WIDTH-1:0]s_axil_awaddr;
  logic [2:0]                s_axil_awprot;
  logic                      s_axil_awvalid;
  logic                      s_axil_awready;
  logic [DATA_WR_WIDTH-1:0]  s_axil_wdata;
  logic [STRB_WIDTH-1:0]     s_axil_wstrb;
  logic                      s_axil_wvalid;
  logic                      s_axil_wready;
  logic [1:0]                s_axil_bresp;
  logic                      s_axil_bvalid;
  logic                      s_axil_bready;
  logic [AXIL_ADDR_WIDTH-1:0]s_axil_araddr;
  logic [2:0]                s_axil_arprot;
  logic                      s_axil_arvalid;
  logic                      s_axil_arready;
  logic [DATA_RD_WIDTH-1:0]  s_axil_rdata;
  logic [1:0]                s_axil_rresp;
  logic                      s_axil_rvalid;
  logic                      s_axil_rready;

  logic                          mm2s_ren;
  logic [AXI_ADDR_WIDTH-LSB-1:0] mm2s_addr;
  logic [AXI_WIDTH    -1:0]      mm2s_data;
  logic                          s2mm_wen;
  logic [AXI_ADDR_WIDTH-LSB-1:0] s2mm_addr;
  logic [AXI_WIDTH    -1:0]      s2mm_data;
  logic [AXI_WIDTH/8  -1:0]      s2mm_strb;

  top_ram dut(.*);

  logic clk = 0;
  initial forever #(CLK_PERIOD/2) clk = ~clk;

  export "DPI-C" function get_config;
  export "DPI-C" function set_config;
  import "DPI-C" context function byte get_byte_a32 (int unsigned addr);
  import "DPI-C" context function void set_byte_a32 (int unsigned addr, byte data);
  import "DPI-C" context function chandle get_mp ();
  // import "DPI-C" context function void print_output (chandle mpv);
  import "DPI-C" context function void dma_loopback(chandle mpv, chandle p_config);


  function automatic int get_config(chandle config_base, input int offset);
    return dut.TOP.CONTROLLER.cfg [offset];
  endfunction


  function automatic set_config(chandle config_base, input int offset, input int data);
    dut.TOP.CONTROLLER.cfg [offset] <= data;
  endfunction


  always_ff @(posedge clk) begin : Axi_rw

    if (mm2s_ren) 
      for (int i = 0; i < AXI_WIDTH/8; i++)
        mm2s_data[i*8 +: 8] <= get_byte_a32((32'(mm2s_addr) << LSB) + i);

    if (s2mm_wen) 
      for (int i = 0; i < AXI_WIDTH/8; i++) 
        if (s2mm_strb[i]) 
          set_byte_a32((32'(s2mm_addr) << LSB) + i, s2mm_data[i*8 +: 8]);
  end
  
  // initial begin
  //   $dumpfile("axi_tb_sys.vcd");
  //   $dumpvars();
  //   #2000us;
  //   $finish;
  // end

  chandle mpv, cp;
  initial begin
    rstn = 0;
    repeat(2) @(posedge clk) #10ps;
    rstn = 1;
    mpv = get_mp();
    
    dma_loopback(mpv, cp);

    $finish;
  end

endmodule


