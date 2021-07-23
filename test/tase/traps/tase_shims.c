//Shims provided to make trapping on certain modeled functions easier


//The actual model (e.g., "malloc_tase" just returns 0 because the function
//model doesn't get executed.  We trap at the call to the model, and fake a return.
//Return value is sometimes "0LL" so that
//the compiler expects a potentially 64 bit value returned, rather than
//the default 32-bit "0".
#include <stdio.h>

void tase_make_symbolic (void * ptr, unsigned long size, const char * name) __attribute__ ((optnone)) {
  return;
}

void * malloc_tase(long int size) {
  return 0LL;
}
void * malloc_tase_shim(long int size) {
  return malloc_tase(size);
}

void * realloc_tase(void * ptr, long int size) {
  return 0LL;
}
void * realloc_tase_shim(void * ptr, long int size) {
  return realloc_tase( ptr, size);
}

void * calloc_tase (long int num, long int size) {
  return 0LL;
}
void * calloc_tase_shim (long int num, long int size) {
  return calloc_tase(num,size);
}

void free_tase (void * ptr) {
  return;
}
void free_tase_shim(void * ptr) {
  free_tase(ptr);
  return;
}

void * memcpy_tase(void * dest, const void * src, unsigned long n) {
  return 0LL;
}
void * memcpy_tase_shim(void * dest, const void * src, unsigned long n) {
  return memcpy_tase(dest,src,n);
}

int * getc_unlocked_tase (FILE * f) {
  return 0LL;
}
int * getc_unlocked_tase_shim (FILE * f) {
  return getc_unlocked_tase(f);
}

/////////Arithmetic

//Todo -- make sure this is OK for 32 bit returns in a 64 bit reg.
float __addsf3_tase(float x, float y) {
  return 0;
}
float __addsf3_tase_shim(float x, float y) {
  return __addsf3_tase(x,y);
}

double __adddf3_tase(double x, double y) {
  return 0LL;
}
double __adddf3_tase_shim (double x, double y) {
  return __adddf3_tase(x,y);
}

float __subsf3_tase(float x, float y) {
  return 0;
}
float __subsf3_tase_shim(float x, float y) {
  return __subsf3_tase(x,y);
}

double __subdf3_tase(double x, double y) {
  return 0LL;
}
double __subdf3_tase_shim(double x, double y) {
  return __subdf3_tase(x,y);
}

float __mulsf3_tase (float x, float y) {
  return 0;
}
float __mulsf3_tase_shim(float x, float y) {
  return __mulsf3_tase(x,y);
}

double __muldf3_tase (double x, double y) {
  return 0LL;
}
double __muldf3_tase_shim(double x, double y) {
  return __muldf3_tase(x,y);
}

float __divsf3_tase (float x, float y) {
  return 0;
}
float __divsf3_tase_shim(float x, float y) {
  return __divsf3_tase(x,y);
}

double __divdf3_tase(double x, double y) {
  return 0LL;
}
double __divdf3_tase_shim(double x, double y) {
  return __divdf3_tase(x,y);
}

float __negsf2_tase(float x) {
  return 0;
}
float __negsf2_tase_shim(float x) {
  return __negsf2_tase(x);
}

double __negdf2_tase(double x) {
  return 0LL;
}
double __negdf2_tase_shim(double x) {
  return __negdf2_tase(x);
}

///////////Conversion

double __extendsfdf2_tase (float x) {
  return 0LL;
}
double __extendsfdf2_tase_shim(float x) {
  return __extendsfdf2_tase(x);
}

float __truncdfsf2_tase (double x) {
  return 0;
}
float __truncdfsf2_tase_shim(double x) {
  return __truncdfsf2_tase(x);
}

int __fixsfsi_tase (float x) {
  return 0;
}
int __fixsfsi_tase_shim(float x) {
  return __fixsfsi_tase(x);
}

int __fixdfsi_tase(double x) {
  return 0;
}
int __fixdfsi_tase_shim(double x) {
  return __fixdfsi_tase(x);
}

long __fixsfdi_tase (float x) {
  return 0;
}
long __fixsfdi_tase_shim (float x) {
  return __fixsfdi_tase(x);
}

long __fixdfdi_tase (double x) {
  return 0;
}
long __fixdfdi_tase_shim (double x) {
  return __fixdfdi_tase(x);
}

long long __fixsfti_tase (float x) {
  return 0LL;
}
long long __fixsfti_tase_shim (float x) {
  return __fixsfti_tase(x);
}

long long __fixdfti_tase (double x) {
  return 0LL;
}
long long __fixdfti_tase_shim( double x) {
  return __fixdfti_tase(x);
}

unsigned int __fixunssfsi_tase (float x) {
  return 0;
}
unsigned int __fixunssfsi_tase_shim (float x) {
  return __fixunssfsi_tase(x);
}

unsigned int __fixunsdfsi_tase (double x) {
  return 0;
}
unsigned int __fixunsdfsi_tase_shim (double x) {
  return __fixunsdfsi_tase(x);
}

unsigned long __fixunssfdi_tase (float x) {
  return 0;
}
unsigned long __fixunssfdi_tase_shim (float x) {
  return __fixunssfdi_tase(x);
}

unsigned long __fixunsdfdi_tase (double x) {
  return 0;
}
unsigned long __fixunsdfdi_tase_shim (double x) {
  return __fixunsdfdi_tase(x);
}

unsigned long long __fixunssfti_tase (float x) {
  return 0LL;
}
unsigned long long __fixunssfti_tase_shim (float x) {
  return __fixunssfti_tase(x);
}

unsigned long long __fixunsdfti_tase (double x) {
  return 0LL;
}
unsigned long long __fixunsdfti_tase_shim (double x) {
  return __fixunsdfti_tase(x);
}

float __floatsisf_tase (int x) {
  return 0;
}
float __floatsisf_tase_shim (int x) {
  return __floatsisf_tase(x);
}

double __floatsidf_tase (int x) {
  return 0LL;
}
double __floatsidf_tase_shim (int x) {
  return __floatsidf_tase(x);
}

float __floatdisf_tase (long x) {
  return 0;
}
float __floatdisf_tase_shim (long x) {
  return __floatdisf_tase(x);
}

double __floatdidf_tase (long x) {
  return 0LL;
}
double __floatdidf_tase_shim (long x) {
  return __floatdidf_tase(x);
}

float __floattisf_tase (long long x ) {
  return 0;
}
float __floattisf_tase_shim (long long x) {
  return __floattisf_tase(x);
}

double __floattidf_tase (long long x) {
  return 0LL;
}
double __floattidf_tase_shim (long long x) {
  return __floattidf_tase(x);
}

float __floatunsisf_tase (unsigned int x) {
  return 0;
}
float __floatunsisf_tase_shim (unsigned int x) {
  return __floatunsisf_tase(x);
}

double __floatunsidf_tase (unsigned int x) {
  return 0LL;
}
double __floatunsidf_tase_shim (unsigned int x) {
  return __floatunsidf_tase(x);
}

float __floatundisf_tase (unsigned long x) {
  return 0;
}
float __floatundisf_tase_shim (unsigned long x) {
  return __floatundisf_tase (x);
}

double __floatundidf_tase (unsigned long x) {
  return 0LL;
}
double __floatundidf_tase_shim (unsigned long x) {
  return __floatundidf_tase (x);
}

float __floatuntisf_tase (unsigned long long x) {
  return 0;
}
float __floatuntisf_tase_shim (unsigned long long x) {
  return __floatuntisf_tase(x);
}

double __floatuntidf_tase (unsigned long long x) {
  return 0LL;
}
double __floatuntidf_tase_shim (unsigned long long x) {
  return __floatuntidf_tase(x);
}

//Comparison

int __cmpsf2_tase (float x, float y) {
  return 0;
}
int __cmpsf2_tase_shim( float x, float y) {
  return __cmpsf2_tase(x,y);
}

int __cmpdf2_tase (double x, double y) {
  return 0;
}
int __cmpdf2_tase_shim (double x, double y) {
  return __cmpdf2_tase(x,y);
}

int __unordsf2_tase (float x, float y) {
  return 0;
}
int __unordsf2_tase_shim (float x, float y) {
  return __unordsf2_tase(x, y);
}

int __unorddf2_tase (double x, double y) {
  return 0;
}
int __unorddf2_tase_shim (double x , double y) {
  return __unorddf2_tase(x,y);
}

int __eqsf2_tase (float x, float y) {
  return 0;
}
int __eqsf2_tase_shim (float x, float y) {
  return __eqsf2_tase(x,y);
}

int __eqdf2_tase (double x, double y) {
  return 0;
}
int __eqdf2_tase_shim (double x, double y) {
  return __eqdf2_tase(x,y);
}

int __nesf2_tase (float x, float y) {
  return 0;
}
int __nesf2_tase_shim (float x, float y) {
  return __nesf2_tase(x,y);
}

int __nedf2_tase (double x, double y) {
  return 0;
}
int __nedf2_tase_shim (double x, double y) {
  return __nedf2_tase(x,y);
}

int __gesf2_tase (float x, float y) {
  return 0;
}
int __gesf2_tase_shim (float x, float y) {
  return __gesf2_tase(x,y);
}

int __gedf2_tase (double x, double y) {
  return 0;
}
int __gedf2_tase_shim (double x, double y) {
  return __gedf2_tase(x,y);
}

int __ltsf2_tase (float x, float y) {
  return 0;
}
int __ltsf2_tase_shim (float x, float y) {
  return __ltsf2_tase(x,y);
}

int __ltdf2_tase (double x, double y) {
  return 0;
}
int __ltdf2_tase_shim (double x, double y) {
  return __ltdf2_tase(x,y);
}

int __lesf2_tase (float x, float y) {
  return 0;
}
int __lesf2_tase_shim (float x, float y) {
  return __lesf2_tase(x,y);
}

int __ledf2_tase (double x, double y) {
  return 0;
}
int __ledf2_tase_shim (double x, double y) {
  return __ledf2_tase(x,y);
}

int __gtsf2_tase (float x, float y) {
  return 0;
}
int __gtsf2_tase_shim (float x, float y) {
  return __gtsf2_tase(x,y);
}

int __gtdf2_tase (double x, double y) {
  return 0;
}
int __gtdf2_tase_shim (double x, double y) {
  return __gtdf2_tase(x,y);
}

//Other

float __powisf2_tase (float x, int y) {
  return 0;
}
float __powisf2_tase_shim (float x, int y) {
  return __powisf2_tase(x,y);
}

double __powidf2_tase (double x, int y) {
  return 0LL;
}
double __powidf2_tase_shim (double x, int y) {
  return __powidf2_tase(x,y);
}
