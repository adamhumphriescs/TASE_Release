#include <stdlib.h>
#include <stdint.h>
#include "tasetraps.h"

void make_byte_symbolic(void* addr) {
  printf("Should never reach this line! Should've marked 0x%lx symbolic \n", (uint64_t) addr);
  return;
}

char tase_progname[6] = "test\n";


int symIndex;
int numEntries;
int repetitions = 1;
uint8_t *resultPtr;
enum initType  {ones, garbage};//Type of initialization for our two arrays                                                 
enum initType testType = garbage;
uint8_t garbageCtr = 1;// Seed for "garbage" test type where we
//just add a value over and over to make garbage                                                                           
//values.  Someday we may replace this with a call to a rng but                                                            
//probably is OK as is for now.                                                                                            

void run();

void begin_target_inner( int argc, char** argv ) {
  symIndex =  atoi(argv[1]);
  numEntries = atoi(argv[2]);
  repetitions =  atoi(argv[3]);

  printf("Running test with index %d, entries %d\n", symIndex, numEntries);
  run();
}

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

void runTest (uint8_t * firstArray, uint8_t * secondArray, uint8_t * resultArray) {
  resultPtr = resultArray;

  uint16_t carry = 0; //This should only ever be just 0 or 1.                                                                        

  for (int i = 0; i < numEntries;  i++) {

    uint16_t result = (uint16_t) firstArray[i] + (uint16_t) secondArray[i] + carry; //Add arrays with carry from last round          
    //carry = (result & 256) >> 8 ;  //Get carry bit if there was overflow.                                                          
    carry = result/256;
    resultArray[i] = (uint8_t) result &255; //Get bottom 8 bits from result
    
  }
  resultArray[numEntries] = carry;//This is just in case last addition has an overflow.
}


void run() {
  uint8_t * firstArray = (uint8_t *) malloc_tase(numEntries);
  uint8_t * secondArray = (uint8_t *) malloc_tase(numEntries) ;
  uint8_t *  resultArray = (uint8_t *) malloc_tase(numEntries+1) ; //Extra entry for overflow on last byte addition.
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
  for (int i = 0; i < repetitions; i++)
    runTest(firstArray, secondArray, resultArray);
}
