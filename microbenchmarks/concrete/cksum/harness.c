#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#ifdef S2E_TEST
#include <time.h>
#include <s2e/s2e.h>
#endif

extern bool cksum (const char *file, bool print_name);

char tase_progname[6] = "test\n";
extern uint64_t saved_rax;

void begin_target_inner (int argc, char** argv) {

#ifdef S2E_TEST
  struct timespec start;
  clock_gettime(CLOCK_REALTIME, &start);
#endif
  
  if ( argc > 1 ) {
    cksum(argv[1], 1);
  } else {
    cksum("../GutenburgDictionary.txt", 1);
  }

#ifdef S2E_TEST
  struct timespec end;
  clock_gettime(CLOCK_REALTIME, &end);
  //Convert time

  uint64_t nanoSecondsTotal = (end.tv_sec - start.tv_sec) * 1000000000 +  end.tv_nsec - start.tv_nsec;
  double secondsTotal = nanoSecondsTotal/1000000000.;
  s2e_printf("TOTAL Elapsed time is %lu nanoseconds \n", nanoSecondsTotal);
  s2e_printf("That's roughly %lf seconds \n", secondsTotal);
#endif
  
}

  
