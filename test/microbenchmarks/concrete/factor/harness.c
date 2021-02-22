#include <stdbool.h>
#include <stdlib.h>

#ifdef S2E_TEST
#include <time.h>
#include <s2e/s2e.h>
#endif

extern void
factorEntryShim (const char *input) ;
void begin_target_inner();

#ifndef TASE_TEST
int main (int argc, char **argv) {
  begin_target_inner();

}
#endif

const char * numString = "16895424309675413218152718641574491217";
void begin_target_inner () {
  #ifdef S2E_TEST
  struct timespec start;
  clock_gettime(CLOCK_REALTIME, &start);
  #endif
  
  factorEntryShim(numString);

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

