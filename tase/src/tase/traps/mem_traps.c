//Update: 6/30/2020 -- Changing return value from "0" to "0LL" so that
//the compiler expects a potentially 64 bit value returned, rather than
//the default 32-bit "0".
#include "tasetraps.h"
#include <stdio.h>

void tase_make_symbolic(void * ptr, unsigned long size, const char * name) __attribute__ ((optnone)) {
  return;
}

void * malloc_tase(long int size) {
  return 0LL;
}

void * realloc_tase(void * ptr, long int size) {
  return 0LL;
}

void * calloc_tase (long int num, long int size) {
  return 0LL;
}

void free_tase (void * ptr) {
  return;
}

void * memcpy_tase(void * dest, const void * src, unsigned long n) {
  return 0LL;
}

int * getc_unlocked_tase (FILE * f) {
  return 0LL;
}
