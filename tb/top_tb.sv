`timescale 1ns/1ps
`define STRINGIFY(x) `"x`"
`define TO_STRING(x) `STRINGIFY(x)

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
  logic [AXIL_ADDR_WIDTH-1:0]s_axil_awaddr =0;
  logic [2:0]                s_axil_awprot =0;
  logic                      s_axil_awvalid=0;
  logic                      s_axil_awready;
  logic [DATA_WR_WIDTH-1:0]  s_axil_wdata =0;
  logic [STRB_WIDTH-1:0]     s_axil_wstrb =0;
  logic                      s_axil_wvalid=0;
  logic                      s_axil_wready;
  logic [1:0]                s_axil_bresp;
  logic                      s_axil_bvalid;
  logic                      s_axil_bready =0;
  logic [AXIL_ADDR_WIDTH-1:0]s_axil_araddr =0;
  logic [2:0]                s_axil_arprot =0;
  logic                      s_axil_arvalid=0;
  logic                      s_axil_arready;
  logic [DATA_RD_WIDTH-1:0]  s_axil_rdata;
  logic [1:0]                s_axil_rresp;
  logic                      s_axil_rvalid;
  logic                      s_axil_rready=0;

  logic                          mm2s_ren;
  logic [AXI_ADDR_WIDTH-LSB-1:0] mm2s_addr;
  logic [AXI_WIDTH    -1:0]      mm2s_data=0;
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
  // import "DPI-C" context function void print_output (chandle mem_ptr_virtual);
  import "DPI-C" context function bit dma_loopback(chandle mem_ptr_virtual, chandle p_config);


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
  
  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars();
    #1000us;
    $finish;
  end


  // Generate random data and write to input.bin
  int file_inp;
  bit [7:0] arr_inp [`BYTES];
  initial begin
    file_inp = $fopen({`TO_STRING(`DIR), "input.bin"}, "wb");
    if (file_inp==0) $fatal(0, "Error: Failed to open file.");
    for (int i = 0; i < `BYTES; i++)
      $fwrite(file_inp, "%c", 8'($urandom_range(0, 255)));
    $fclose(file_inp);
  end

  int file_out, file_exp, status, error=0;
  byte out_byte, exp_byte;
  chandle mem_ptr_virtual, cfg_ptr_virtual;
  initial begin
    rstn = 0;
    repeat(2) @(posedge clk) #10ps;
    rstn = 1;
    mem_ptr_virtual = get_mp();
    
    while (dma_loopback(mem_ptr_virtual, cfg_ptr_virtual)) @(posedge clk) #10ps;


    // Read from output & expected and compare
    file_out = $fopen({`TO_STRING(`DIR), "output.bin"}, "rb");
    file_exp = $fopen({`TO_STRING(`DIR), "input.bin" }, "rb");
    if (file_out==0 || file_exp==0) $fatal(0, "Error: Failed to open output/expected file(s).");

    for (int i = 0; i < `BYTES; i++) begin
      if ($feof(file_out)==0 || $feof(file_exp)==0) begin
        out_byte = $fgetc(file_out);
        exp_byte = $fgetc(file_exp);
        // Compare
        if (exp_byte != out_byte) begin
          $display("Mismatch at index %0d: Expected %h, Found %h", i, exp_byte, out_byte);
          error += 1;
        end else begin
          $display("Output match at index %0d: Expected %h, Found %h", i, exp_byte, out_byte);
        end

      end else $fatal(0, "Error: output/expected files are less than given bytes.");
    end
    $fclose(file_exp);
    $fclose(file_out);
    
    if (error==0) $display("Verification successful: Output matches Expected data.");
    else          $fatal (0, "Error: Output data does not match Expected data.");
    $finish;
  end

endmodule


