#include <stdlib.h>
#include <stdint.h>
//#include <stdio.h>

#ifndef TASE_TEST
#include <stdlib.h>
#endif
#ifdef TASE_TEST
//Dummy function used for forcing malloc traps
extern void * malloc_tase(int size);
#endif

#ifdef KLEE_TEST
extern void klee_make_symbolic(void * addr, size_t s, const char * name);
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <stdio.h>
struct timespec start;
#endif

#ifdef S2E_TEST
#include "../../../../../../s2e_test2/source/s2e/s2e/guest/common/include/s2e/s2e.h"
#include <time.h>
struct timespec start;
#endif

#ifdef QSYM_TEST
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
struct timespec start;
#endif

#ifdef SYMCC_TEST
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
struct timespec start;
#endif


extern int symIndex;  //Totally arbitrary choice for now
extern int numEntries; //Number of bytes to add together.
extern int repetitions;  //Number of times to perform test
extern uint8_t * resultPtr;

extern void begin_target_inner();


#ifndef TASE_TEST
int main (int argc, char * argv[]) {

  symIndex =  atoi(argv[1]);
  numEntries = atoi(argv[2]);
  repetitions =  atoi(argv[3]);

  begin_target_inner();

#ifdef S2E_TEST
  s2e_create("FINISHED.txt");
  struct timespec end;
  clock_gettime(CLOCK_REALTIME, &end);
  //Convert time
  uint64_t nanoSecondsTotal = (end.tv_sec - start.tv_sec) * 1000000000 +  end.tv_nsec - start.tv_nsec;
  double secondsTotal = nanoSecondsTotal/1000000000.;

  s2e_printf("TOTAL Elapsed time is %lu nanoseconds \n", nanoSecondsTotal);
  s2e_printf("That's roughly %lf seconds \n", secondsTotal);
#endif

#ifdef QSYM_TEST
  struct timespec end;
  clock_gettime(CLOCK_REALTIME, &end);
  uint64_t nanoSecondsTotal = (end.tv_sec - start.tv_sec) * 1000000000 +  end.tv_nsec - start.tv_nsec;
  double secondsTotal = nanoSecondsTotal/1000000000.; 
  FILE * log = fopen("BigNumLog", "a");

  fprintf(log, "%d, %lf \n", symIndex, secondsTotal);
  fclose(log);

#endif

#ifdef KLEE_TEST
  struct timespec end;
  clock_gettime(CLOCK_REALTIME, &end);
  uint64_t nanoSecondsTotal = (end.tv_sec - start.tv_sec) * 1000000000 +  end.tv_nsec - start.tv_nsec;
  double secondsTotal = nanoSecondsTotal/1000000000.;
  FILE * log = fopen("BigNumLog", "a");
  fprintf(log, "%d, %lf \n", symIndex, secondsTotal);
  fclose(log);
#endif

  
}
#endif


void make_byte_symbolic (void * addr){
  //For tase test, we've already trapped and
  //don't execute any code.

#ifdef TASE_TEST
  //Should never reach in TASE!
  //However, something needs to be here so
  //that the compiler doesn't optimize function out.
  printf("Should never reach this line! Should've marked 0x%lx symbolic \n", (uint64_t) addr);
  
#endif

#ifdef KLEE_TEST
  uint8_t a;
  klee_make_symbolic(&a, 1, "SYM_VALUE");
  *(uint8_t *) addr = a;
#endif

#ifdef S2E_TEST
  uint8_t a;
  s2e_make_symbolic(&a, sizeof(uint8_t), "SYM_VALUE");
  *(uint8_t *) addr = a;
#endif

#if defined(QSYM_TEST) || defined(SYMCC_TEST)
//QSYM API for making a byte symbolic is a little tricky.
//The only way I see to do this is to read from a file descriptor
//marked by the QSYM command line as containing symbolic input.  The
//QSYM command line specifies what input file descriptors are symbolic;
//in this case, we choose to tell qsym to read from stdin at at runtime
//from a file we mark as symbolic and pipe in (indirectly) into the program.

//So the command at runtime is something like
// '../bin/run_qsym.py -i /fromHost/symFile -o outputDir bigNumTestQSym 0 50000 1
// when we're running the bignum test on 50000 entries once, with symIndex at 0.
//Note that this command is executed within a docker container so we have to
//share the files from the host to the docker image.


 char buf [2];
 int res2 = read(0, buf, 1);
 if (res2 != 1) {
   printf("ERROR reading from stdin! \n");
   exit(-1);
 } else {
   *(char *) addr = buf[0];
 }
 
#endif

 return;
}

//The purpose of this file is to provide a microbenchmark for TASE.
//In this microbenchmark, we add together two arrays of 8 bit values
// byte-by-byte and perform a carry when the result of each addition
//has an overflow.
//This should be the same arithmetically as adding two numbers together 
//of size "numEntries" bytes.

//The purpose of the benchmark is to provide a sliding scale of "symIndex"
//which represents the entry for a single symbolic byte in firstArray.
//So our expectations are the following: 
//1. We hopefully execute the concrete byte-by-byte addition
//quickly and natively until the symbolic byte is encountered at symIndex.
//A larger value of symIndex should have more native execution and less
//interpretation.
//2. We hopefully don't have any forks ever in this microbenchmark, even
//after the symbolic byte is encountered and we start interpreting.  Ideally
//this microbenchmark will not have any forking so we only examine
// the relative speeds of native execution vs interpretation.  ABH 09/12/2018


int symIndex;  //Index of first symbolic byte.  Negative 1 for no taint.
int numEntries; //Number of bytes to add together.
int repetitions =1;  //Number of times to perform test 
uint8_t * resultPtr; //Used for debugging
#ifdef DEBUG
int loopCtr = 1; //Used for debugging
#endif


enum initType  {ones, garbage};//Type of initialization for our two arrays
enum initType testType = garbage;
uint8_t garbageCtr = 1;// Seed for "garbage" test type where we
//just add a value over and over to make garbage
//values.  Someday we may replace this with a call to a rng but
//probably is OK as is for now.

//Hack to manually kill flags
/*
int dummyPrint = 0;
int  __attribute__((noinline)) dummyFn () {

  if (dummyPrint == 1) {
    printf("In dummyFn \n");
  }

  //Manually kill flags
  asm("mov $0, %rax; sahf;");

  return 0;
}
*/

//Initialize the arrays we're adding based on testType
void initializeNums(uint8_t * numArray) {
  for (int i = 0; i < numEntries; i++) {
    if (testType == ones) {
      numArray[i] =1;
    }else if (testType == garbage) {
      garbageCtr = garbageCtr * garbageCtr + 7;
      numArray[i] = garbageCtr; //Definitely not random, just don't want
      //to have to worry about importing rand func in TASE yet.
    } 
  }
}


void initializeAllOnes(uint8_t * numArray) {
  for (int i = 0; i < numEntries; i++) {
      numArray[i] = 255;
  }
}

void initializeAllZeros(uint8_t * numArray) {
  for (int i = 0; i < numEntries; i++) {
    numArray[i] = 0;
  }
}


void runTest(uint8_t * firstArray, uint8_t * secondArray, uint8_t * resultArray);

void begin_target_inner() {

#ifdef S2E_TEST
  clock_gettime(CLOCK_REALTIME, &start);
  s2e_create("STARTED.txt");
#endif
  
  #ifdef TASE_TEST
  uint8_t * firstArray = (uint8_t *) malloc_tase(numEntries);
  uint8_t * secondArray = (uint8_t *) malloc_tase(numEntries) ;
  uint8_t *  resultArray = (uint8_t *) malloc_tase(numEntries+1) ; //Extra entry for overflow on last byte addition.
  #else
  uint8_t * firstArray = (uint8_t *) malloc(numEntries);
  uint8_t * secondArray = (uint8_t *) malloc(numEntries) ;
  uint8_t *  resultArray = (uint8_t *) malloc(numEntries+1) ; //Extra entry for overflow on last byte addition. 
  #endif
  initializeNums(&firstArray[0]);
  initializeNums(&secondArray[0]); //Redundant, but somehow prevents compiler from realizing that
  //setting the second array to all ones will later simplify the arithmetic for the carry in our ripple adder.

  initializeAllZeros(firstArray);
  initializeAllOnes(secondArray);


  //Trap and make symIndex symbolic
  if (symIndex >= 0 && symIndex < numEntries) {
    void * symAddr = (void *) &firstArray[symIndex];
    make_byte_symbolic(symAddr);
  }
  //Edit -- moved S2E_TEST start time up to fix purely concrete case

#ifdef QSYM_TEST
  clock_gettime(CLOCK_REALTIME, &start);
#endif

#ifdef KLEE_TEST
  clock_gettime(CLOCK_REALTIME, &start);
#endif
  
  for (int i = 0; i < repetitions; i++)
    runTest(firstArray, secondArray, resultArray);
}


void runTest (uint8_t * firstArray, uint8_t * secondArray, uint8_t * resultArray) {


#ifdef DEBUG
  loopCtr++;
#endif

  resultPtr = resultArray;
  
  uint16_t carry = 0; //This should only ever be just 0 or 1.
  
  for (int i = 0; i < numEntries;  i++) {

    uint16_t result = (uint16_t) firstArray[i] + (uint16_t) secondArray[i] + carry; //Add arrays with carry from last round
    //carry = (result & 256) >> 8 ;  //Get carry bit if there was overflow.
    carry = result/256;
    resultArray[i] = (uint8_t) result &255; //Get bottom 8 bits from result
#ifdef DEBUG
    loopCtr++;
#endif

  }
  resultArray[numEntries] = carry;//This is just in case last addition has an overflow.

#ifdef DEBUG
  loopCtr++;
#endif
  
#ifdef DEBUG
  for (int i = 0; i < numEntries+1; i++){
    printf("%d \n ", resultArray[i]);
  }
#endif
  
}
