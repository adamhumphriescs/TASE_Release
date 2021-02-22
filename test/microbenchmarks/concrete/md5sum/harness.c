
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef TASE_TEST
#include "../../../../test/other/tasetraps.h"
#endif 

#ifdef S2E_TEST
#include <time.h>
#include <s2e/s2e.h> 
#endif


typedef long value;
extern value md5sum(value input);

#ifndef TASE_TEST
int main() {
  begin_target_inner();
}
#endif

int begin_target_inner () {

#ifdef S2E_TEST
  struct timespec start;
  clock_gettime(CLOCK_REALTIME, &start);
#endif
  
  FILE * f = fopen( "GutenburgDictionary.txt", "r");
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

  char * tmp = malloc (size+1);
  fread(tmp, 1, size, f); 
  tmp[size] = '\0';
  long res = md5sum((long) tmp);

  //Necessary?
  free(tmp);
  
  char * endRes = malloc(22);
  dec64(endRes, res, 22);

  printf("Result is ... \n");
  for (int i = 0 ; i < 16; i++) {
    printf("%02x", *(((uint8_t *)(endRes)) + i));    
  }
  printf("\n");

  //Necessary?
  free((char *) res);
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
