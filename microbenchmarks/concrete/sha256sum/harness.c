
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef TASE_TEST
#include "tasetraps.h"
#endif 

#ifdef S2E_TEST
#include <time.h>
#include <s2e/s2e.h> 
#endif


extern uint64_t saved_rax;
char tase_progname[6] = "test\n";

#ifndef TASE_TEST
int main() {
  begin_target_inner();
}
#endif

int begin_target_inner (int argc, char** argv) {

#ifdef S2E_TEST
  struct timespec start;
  clock_gettime(CLOCK_REALTIME, &start);
#endif
  
  char * fname;
  
  if ( argc > 1 ) {
    fname = argv[1];
  } else {
    fname = "GutenburgDictionary.txt";
  }
  
  FILE * f = fopen( fname, "r" );
  if (f == NULL) {
    printf("Something went wrong with fopen \n");
#ifdef S2E_TEST
    s2e_printf("\n\n\nSomething went wrong with fopen \n\n\n");
#endif
    return 0;
  }

#ifdef S2E_TEST
  struct timespec timeAfterLoad;
  clock_gettime(CLOCK_REALTIME, &timeAfterLoad);
#endif
  
  
  fseek(f, 0, SEEK_END); //Seek to end...
  long size = ftell(f);  //Get index
  rewind(f);             //Go back to the start...

  char * tmp = malloc (size);
  fread(tmp, 1, size, f); 
  fclose(f);

  void * endRes = malloc(256);
  
  sha256_buffer(tmp, size, endRes);



  char res[65];
  res[64] = '\0';
  printf("Result is ... \n");
  for (int i = 0 ; i < 32; i++) {
    sprintf(&res[2*i], "%02x", *(((uint8_t *)(endRes)) + i));    
  }
  printf("%s\n", res);
  fflush(stdout);
  //For ASAN memory leak detection
  free(tmp);
  free(endRes);
  
#ifdef S2E_TEST
  struct timespec end;
  clock_gettime(CLOCK_REALTIME, &end);
  //Convert time

  uint64_t nanoSecondsAfterLoad = (end.tv_sec - timeAfterLoad.tv_sec) * 1000000000 + end.tv_nsec - timeAfterLoad.tv_nsec;
  double secondsAfterLoad = nanoSecondsAfterLoad/1000000000.;
  s2e_printf("AFTER LOAD, Elapsed time is %lu nanoseconds \n", nanoSecondsAfterLoad);
  s2e_printf("That's roughly %lf seconds \n", secondsAfterLoad);

  uint64_t nanoSecondsTotal = (end.tv_sec - start.tv_sec) * 1000000000 +  end.tv_nsec - start.tv_nsec;
  double secondsTotal = nanoSecondsTotal/1000000000.;

  s2e_printf("TOTAL Elapsed time WITH LOAD is %lu nanoseconds \n", nanoSecondsTotal);
  s2e_printf("That's roughly %lf seconds \n", secondsTotal);  
#endif 
}
