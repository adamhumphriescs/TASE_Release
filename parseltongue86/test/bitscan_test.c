#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>

void test_fxn(uint64_t v72){
  uint16_t efl_tmp = 0;
  uint16_t efl71 = 0;
  uint64_t rax_tmp = 0;
  //  uint64_t v72 = (uint64_t) rdi_tmp;
  if(!v72) {
    efl71 &= ~(1<<6);
  efl_tmp = (efl_tmp & ~(0x8c5)) | (efl71);
    return;
  }
  uint32_t y73 = 0;
  int32_t r74 = 0;
  if(v72>>32) y73=v72>>32, r74=0; else y73=v72, r74=32;
  if(y73>>16) y73=y73>>16; else r74 |= 16;
  if(y73>>8) y73=y73>>8; else r74 |= 8;
  if(y73>>4) y73=y73>>4; else r74 |= 4;
  if(y73>>2) y73=y73>>2; else r74 |= 2;
  uint64_t final75 = 63 - (r74 | !(y73>>1));
  efl71 |= (1<<6);
  rax_tmp = final75;
  efl_tmp = (efl_tmp & ~(0x8c5)) | (efl71);
  printf("Highest set bit: %d\n", (uint32_t) rax_tmp);
}

void test_fxn2(uint64_t v86){
  uint16_t efl_tmp = 0;
  uint16_t efl85 = 0;
  uint64_t rax_tmp = 0;
  static const int DeBruijnPos[64] = {0, 1, 48,  2, 57, 49, 28,  3,          61, 58, 50, 42, 38, 29, 17,  4,          62, 55, 59, 36, 53, 51, 43, 22,          45, 39, 33, 30, 24, 18, 12,  5,          63, 47, 56, 27, 60, 41, 37, 16,          54, 35, 52, 21, 44, 32, 23, 11,          46, 26, 40, 15, 34, 20, 31, 10,          25, 14, 19,  9, 13,  8,  7,  6};
  if (v86 == 0) {
    efl85 &= ~(1<<6);
  efl_tmp = (efl_tmp & ~(0x8c5)) | (efl85);
  } else { 
  int64_t final87 = DeBruijnPos[(uint64_t)((v86&-v86) * 0x03f79d71b4cb0a89)>>58];
  rax_tmp = final87;
  efl85 &= 1<<6;
  efl_tmp = (efl_tmp & ~(0x8c5)) | (efl85);
  }

  printf("Lowest set bit: %d\n", (uint32_t) rax_tmp);
}


int main(){
  uint64_t x = 0x8000000000000001;
  test_fxn(x);
  test_fxn2(x);
}
