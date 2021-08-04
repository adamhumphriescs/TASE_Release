#include <stdint.h>
#include <stdlib.h>

#ifdef KLEE_TEST
#include "klee.h"
#endif

#ifdef TASE_TEST
#include "tase.h"
#endif


#ifdef S2E_TEST
#include <s2e/s2e.h>
#endif

void make_byte_symbolic (void * addr){
  //For tase test, we've already trapped
  
  uint8_t a;
  
#ifdef KLEE_TEST
  klee_make_symbolic(&a, 1, NULL);
  *(uint8_t *) addr = a;
#endif

#ifdef S2E_TEST
  s2e_make_symbolic(&a, sizeof(uint8_t), "tmp");
  *(uint8_t *) addr = a;
#endif
  
  return;
}
