// BYTES and DIR are macros defined through compiler options, or outside

typedef struct {
  unsigned char inp_arr [BYTES];
  unsigned char out_arr [BYTES];
} Memory_st;

#define MEM_BASEADDR    0x20000000
#define CONFIG_BASEADDR 0xA0000000
#define A_START         0x0
#define A_MM2S_DONE     0x1
#define A_MM2S_ADDR     0x2
#define A_MM2S_BYTES    0x3
#define A_MM2S_TUSER    0x4
#define A_S2MM_DONE     0x5
#define A_S2MM_ADDR     0x6
#define A_S2MM_BYTES    0x7

#include "wrapper.h"


extern EXT_C u8 dma_loopback(Memory_st *restrict mp, void *p_config) {
 
  #ifdef SIM // only read/write files in simulation
    FILE *fp;
    char f_path [1000];
    int bytes;

    printf("DIR:%s", TO_STRING(DIR));

    WAIT_INIT(DMA_WAIT);

    sprintf(f_path, "%sinput.bin", TO_STRING(DIR));
    fp = fopen(f_path, "rb");
    debug_printf("DEBUG: Reading from file %s \n", f_path);
    if(!fp) debug_printf("ERROR! File not found: %s \n", f_path);
    bytes = fread(mp->inp_arr, 1, BYTES, fp);
    fclose(fp);
  #endif

  flush_cache(mp->inp_arr, BYTES);  // force transfer to DDR, starting addr & length
  
  // Start DMA
  set_config(p_config, A_MM2S_ADDR , addr_64to32(mem_phy.inp_arr));
  set_config(p_config, A_MM2S_BYTES, sizeof(mem_phy.inp_arr));
  set_config(p_config, A_S2MM_ADDR , addr_64to32(mem_phy.out_arr));
  set_config(p_config, A_S2MM_BYTES, sizeof(mem_phy.out_arr));
  set_config(p_config, A_START     , 1);  // Start


  WAIT(!(get_config(p_config, A_S2MM_DONE) && get_config(p_config, A_MM2S_DONE)), DMA_WAIT);

  #ifdef SIM
    sprintf(f_path, "%soutput.bin", TO_STRING(DIR));
    fp = fopen(f_path, "wb");
    debug_printf("DEBUG: Writing to file %s \n", f_path);
    if(!fp) debug_printf("ERROR! File not found: %s \n", f_path);
    bytes = fwrite(mp->out_arr, 1, BYTES, fp);
    fclose(fp);
  #endif
  return 0;
}
