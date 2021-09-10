#include <stdio.h>
#include <inttypes.h>

int64_t test_bsr(uint64_t);
int64_t test_bsf(uint64_t);


void print(uint64_t x){
  int64_t a = test_bsr(x);
  int64_t b = test_bsf(x);

  printf("\n");
  printf("Value: 0x%" PRIx64 "\n", x);
  printf("index of highest set bit: %d (%d)\n", (int32_t)a, a >= 0 ? (int32_t)(63-a) : -1);
  printf("index of Lowest set bit: %d\n", (int32_t)b);
}
	   

int main(int argc, char *argv[]){
  uint64_t x = 0x0100000000000100;
  uint64_t y = 0x8000000000000001;
  uint64_t z = 0;
  print(x);
  print(y);
  print(z);
}
