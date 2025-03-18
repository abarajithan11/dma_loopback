#define MEM_BASEADDR    0x20000000
#define CONFIG_BASEADDR 0x30000000

#define A_START        0x0
#define A_MM2S_DONE    0x1
#define A_MM2S_ADDR    0x2
#define A_MM2S_BYTES   0x3
#define A_MM2S_TUSER   0x4
#define A_S2MM_DONE    0x5
#define A_S2MM_ADDR    0x6
#define A_S2MM_BYTES   0x7

#include <assert.h>
#include <stdlib.h>
#include <limits.h>
#include <stdint.h>

typedef int8_t   i8 ;
typedef int16_t  i16;
typedef int32_t  i32;
typedef int64_t  i64;
typedef uint8_t  u8 ;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef float    f32;
typedef double   f64;

typedef struct {
  i8 inp_arr [BYTES];
  i8 out_arr [BYTES];
} Memory_st;

#ifdef __cplusplus
  #define EXT_C "C"
  #define restrict __restrict__ 
#else
  #define EXT_C
#endif

#ifdef SIM
  #define XDEBUG
  #include <stdio.h>
  #define sim_fprintf fprintf
  #include <stdbool.h>
  #define STRINGIFY(x) #x
  #define TO_STRING(x) STRINGIFY(x)

  Memory_st mem_phy;
	extern EXT_C u32 get_config(void*, u32);
	extern EXT_C void set_config(void*, u32, u32);
  static inline void flush_cache(void *addr, uint32_t bytes) {} // Do nothing

#else
  #define sim_fprintf(...)
  #define mem_phy (*(Memory_st* restrict)MEM_BASEADDR)

  inline volatile u32 get_config(void *config_base, u32 offset){
    return *(volatile u32 *)(config_base + offset*4);
  }

  inline void set_config(void *config_base, u32 offset, u32 data){	
    *(volatile u32 *restrict)(config_base + offset*4) = data;
  }
#endif

#ifdef XDEBUG
  #define debug_printf printf
  #define assert_printf(v1, op, v2, optional_debug_info,...) ((v1  op v2) || (debug_printf("ASSERT FAILED: \n CONDITION: "), debug_printf("( " #v1 " " #op " " #v2 " )"), debug_printf(", VALUES: ( %d %s %d ), ", v1, #op, v2), debug_printf("DEBUG_INFO: " optional_debug_info), debug_printf(" " __VA_ARGS__), debug_printf("\n\n"), assert(v1 op v2), 0))
#else
  #define assert_printf(...)
  #define debug_printf(...)
#endif

// Rest of the helper functions used in simulation.
#ifdef SIM

extern EXT_C u32 addr_64to32(void* restrict addr){
  u64 offset = (u64)addr - (u64)&mem_phy;
  return (u32)offset + 0x20000000;
}

extern EXT_C u64 sim_addr_32to64(u32 addr){
  return (u64)addr - (u64)0x20000000 + (u64)&mem_phy;
}

extern EXT_C u8 get_byte_a32 (u32 addr_32){
  u64 addr = sim_addr_32to64(addr_32);
  u8 val = *(u8*restrict)addr;
  //debug_printf("get_byte_a32: addr32:0x%x, addr64:0x%lx, val:0x%x\n", addr_32, addr, val);
  return val;
}

extern EXT_C void set_byte_a32 (u32 addr_32, u8 data){
  u64 addr = sim_addr_32to64(addr_32);
  *(u8*restrict)addr = data;
}

extern EXT_C void *get_mp(){
  return &mem_phy;
}
#else

u32 addr_64to32 (void* addr){
  return (u32)addr;
}

#endif

extern EXT_C u8 dma_loopback(Memory_st *restrict mp, void *p_config) {
 
#ifdef SIM
  FILE *fp;
  char f_path [1000];
  int bytes;
#endif 

#ifdef SIM
  static char is_first_call = 1;
  if (is_first_call)  is_first_call = 0;
  else                goto DMA_WAIT;
#endif

#ifdef SIM
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
  
  set_config(p_config, A_S2MM_ADDR, addr_64to32(mem_phy.out_arr));
  set_config(p_config, A_S2MM_BYTES, sizeof(mem_phy.out_arr));
  set_config(p_config, A_START, 1);  // Start


#ifdef SIM
  DMA_WAIT:
                // if sim return, so SV can pass time, and call again, which will jump to DMA_WAIT again
                if (!(get_config(p_config, A_S2MM_DONE) && get_config(p_config, A_MM2S_DONE))) 
                  return 1; 
#else
                flush_cache(mp->inp_arr, BYTES);  // force transfer to DDR, starting addr & length
                while (!(get_config(p_config, A_S2MM_DONE) && get_config(p_config, A_MM2S_DONE))) {
                  // in FPGA, wait for write done
                }
                usleep(0);
#endif

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
