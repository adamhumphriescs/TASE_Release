//Shims provided to make trapping on certain modeled functions easier


//The actual model (e.g., "malloc_tase" just returns 0 because the function
//model doesn't get executed.  We trap at the call to the model, and fake a return.
//Return value is sometimes "0LL" so that
//the compiler expects a potentially 64 bit value returned, rather than
//the default 32-bit "0".
#include <stdio.h>
#include <stddef.h>
#include <stdint.h>

int isatty_tase(int fd){
  return 0;
}
int fprintf_tase(FILE *stream, const char *format, ...){
  return 0;
}
size_t fwrite_tase(const void *ptr, size_t size, size_t nmemb, FILE *stream){
  return 0;
}

FILE *freopen_tase(const char *filename, const char *mode, FILE *stream){
  return NULL;
}

int putchar_tase(int i, char c){
  return 0;
}
ssize_t write_tase(int fd, const void *buf, size_t count){
  return 0;
}
int vasprintf_tase(char **strp, const char *fmt, va_list ap){
  return 0;
}

int vsnprintf_tase (char * s, size_t n, const char * format, va_list arg ){
  return 0;
}

__attribute__ ((optnone)) void tase_make_symbolic(void * ptr, unsigned long size, const char * name)  {
  return;
}

void * malloc_tase(long int size) {
  return 0LL;
}
/*void * malloc_tase_shim(long int size) {
  return malloc_tase(size);
  }*/

void * realloc_tase(void * ptr, long int size) {
  return 0LL;
}
/*void * realloc_tase_shim(void * ptr, long int size) {
  return realloc_tase( ptr, size);
  }*/

void * calloc_tase(long int num, long int size) {
  return 0LL;
}
/*void * calloc_tase_shim(long int num, long int size) {
  return calloc_tase(num,size);
  }*/

void free_tase (void * ptr) {
  return;
}
/*void free_tase_shim(void * ptr) {
  free_tase(ptr);
  return;
  }*/

int fileno_tase(FILE *stream) {
  return 0;
}

size_t fread_tase(void *ptr, size_t size, size_t nmemb, FILE *stream) {
  return 0;
}

size_t fread_unlocked_tase(void *ptr, size_t size, size_t nmemb, FILE *stream) {
  return 0;
}

int ferror_tase(FILE *stream) {
  return 0;
}

int feof_tase(FILE *stream){
  return 0;
}
int fclose_tase(FILE *stream) {
  return 0;
}

int posix_fadvise_tase(int fd, off_t offset, off_t len, int advice){
  return 0;
}

int fseek_tase(FILE *stream, long int offset, int whence){
  return 0;
}

void rewind_tase(FILE *stream){
  return;
}
long int ftell_tase(FILE *stream){
  return 0L;
}

//void * memcpy_tase(void * dest, const void * src, unsigned long n) {
//  return 0LL;
//}
/*void * memcpy_tase_shim(void * dest, const void * src, unsigned long n) {
  return memcpy_tase(dest, src, n);
  }*/

int * getc_unlocked_tase (FILE * f) {
  return 0LL;
}
/*int * getc_unlocked_tase_shim (FILE * f) {
  return getc_unlocked_tase(f);
  }*/

int puts_tase (const char * str) {
  return 0;
}

int fflush_tase(FILE* stream) {
  return 0;
}

/*int fflush_tase_shim(FILE* stream){
  return fflush_tase(stream);
  }*/

/*int puts_tase_shim(const char * str) {
  return puts_tase(str);
  }*/

//It would be nice to provide a shim wrapper for printf_tase, but that's harder
//because of the use of varargs.  For now, we just change "printf" symbols in the
//target project directly into "tase_printf".
int printf_tase (const char * fmt, ...) {
  return 0;
}

//Similar to printf_tase, no wrapper here because of varargs.  We're not fully
//modeleing sprintf yet, just cherrypicking some of the specific calls that
//come from the portions of musl libc that we do support.
int sprintf_tase (char * str, const char * fmt, ...) {
  return 0;
}

FILE *fopen_tase(const char *filename, const char *mode) {
  return 0;
}

/////////Arithmetic

//Todo -- make sure this is OK for 32 bit returns in a 64 bit reg.
float __addsf3_tase(float x, float y) {
  return 0;
}
/*float __addsf3_tase_shim(float x, float y) {
  return __addsf3_tase(x,y);
  }*/

double __adddf3_tase(double x, double y) {
  return 0LL;
}
/*double __adddf3_tase_shim (double x, double y) {
  return __adddf3_tase(x,y);
  }*/

float __subsf3_tase(float x, float y) {
  return 0;
}
/*float __subsf3_tase_shim(float x, float y) {
  return __subsf3_tase(x,y);
  }*/

double __subdf3_tase(double x, double y) {
  return 0LL;
}
/*double __subdf3_tase_shim(double x, double y) {
  return __subdf3_tase(x,y);
  }*/

float __mulsf3_tase (float x, float y) {
  return 0;
}
/*float __mulsf3_tase_shim(float x, float y) {
  return __mulsf3_tase(x,y);
  }*/

double __muldf3_tase (double x, double y) {
  return 0LL;
}
/*double __muldf3_tase_shim(double x, double y) {
  return __muldf3_tase(x,y);
  }*/

float __divsf3_tase (float x, float y) {
  return 0;
}
/*float __divsf3_tase_shim(float x, float y) {
  return __divsf3_tase(x,y);
  }*/

double __divdf3_tase(double x, double y) {
  return 0LL;
}
/*double __divdf3_tase_shim(double x, double y) {
  return __divdf3_tase(x,y);
  }*/

float __negsf2_tase(float x) {
  return 0;
}
/*float __negsf2_tase_shim(float x) {
  return __negsf2_tase(x);
  }*/

double __negdf2_tase(double x) {
  return 0LL;
}
/*double __negdf2_tase_shim(double x) {
  return __negdf2_tase(x);
  }*/

///////////Conversion

double __extendsfdf2_tase (float x) {
  return 0LL;
}
/*double __extendsfdf2_tase_shim(float x) {
  return __extendsfdf2_tase(x);
  }*/

float __truncdfsf2_tase (double x) {
  return 0;
}
/*float __truncdfsf2_tase_shim(double x) {
  return __truncdfsf2_tase(x);
  }*/

int __fixsfsi_tase (float x) {
  return 0;
}
/*int __fixsfsi_tase_shim(float x) {
  return __fixsfsi_tase(x);
  }*/

int __fixdfsi_tase(double x) {
  return 0;
}
/*int __fixdfsi_tase_shim(double x) {
  return __fixdfsi_tase(x);
  }*/

long __fixsfdi_tase (float x) {
  return 0;
}
/*long __fixsfdi_tase_shim (float x) {
  return __fixsfdi_tase(x);
  }*/

long __fixdfdi_tase (double x) {
  return 0;
}
/*long __fixdfdi_tase_shim (double x) {
  return __fixdfdi_tase(x);
  }*/

long long __fixsfti_tase (float x) {
  return 0LL;
}
/*long long __fixsfti_tase_shim (float x) {
  return __fixsfti_tase(x);
  }*/

long long __fixdfti_tase (double x) {
  return 0LL;
}
/*long long __fixdfti_tase_shim( double x) {
  return __fixdfti_tase(x);
  }*/

unsigned int __fixunssfsi_tase (float x) {
  return 0;
}
/*unsigned int __fixunssfsi_tase_shim (float x) {
  return __fixunssfsi_tase(x);
  }*/

unsigned int __fixunsdfsi_tase (double x) {
  return 0;
}
/*unsigned int __fixunsdfsi_tase_shim (double x) {
  return __fixunsdfsi_tase(x);
  }*/

unsigned long __fixunssfdi_tase (float x) {
  return 0;
}
/*unsigned long __fixunssfdi_tase_shim (float x) {
  return __fixunssfdi_tase(x);
  }*/

unsigned long __fixunsdfdi_tase (double x) {
  return 0;
}
/*unsigned long __fixunsdfdi_tase_shim (double x) {
  return __fixunsdfdi_tase(x);
  }*/

unsigned long long __fixunssfti_tase (float x) {
  return 0LL;
}
/*unsigned long long __fixunssfti_tase_shim (float x) {
  return __fixunssfti_tase(x);
  }*/

unsigned long long __fixunsdfti_tase (double x) {
  return 0LL;
}
/*unsigned long long __fixunsdfti_tase_shim (double x) {
  return __fixunsdfti_tase(x);
  }*/

float __floatsisf_tase (int x) {
  return 0;
}
/*float __floatsisf_tase_shim (int x) {
  return __floatsisf_tase(x);
  }*/

double __floatsidf_tase (int x) {
  return 0LL;
}
/*double __floatsidf_tase_shim (int x) {
  return __floatsidf_tase(x);
  }*/

float __floatdisf_tase (long x) {
  return 0;
}
/*float __floatdisf_tase_shim (long x) {
  return __floatdisf_tase(x);
  }*/

double __floatdidf_tase (long x) {
  return 0LL;
}
/*double __floatdidf_tase_shim (long x) {
  return __floatdidf_tase(x);
  }*/

float __floattisf_tase (long long x ) {
  return 0;
}
/*float __floattisf_tase_shim (long long x) {
  return __floattisf_tase(x);
  }*/

double __floattidf_tase (long long x) {
  return 0LL;
}
/*double __floattidf_tase_shim (long long x) {
  return __floattidf_tase(x);
  }*/

float __floatunsisf_tase (unsigned int x) {
  return 0;
}
/*float __floatunsisf_tase_shim (unsigned int x) {
  return __floatunsisf_tase(x);
  }*/

double __floatunsidf_tase (unsigned int x) {
  return 0LL;
}
/*double __floatunsidf_tase_shim (unsigned int x) {
  return __floatunsidf_tase(x);
  }*/

float __floatundisf_tase (unsigned long x) {
  return 0;
}
/*float __floatundisf_tase_shim (unsigned long x) {
  return __floatundisf_tase (x);
  }*/

double __floatundidf_tase (unsigned long x) {
  return 0LL;
}
/*double __floatundidf_tase_shim (unsigned long x) {
  return __floatundidf_tase (x);
  }*/

float __floatuntisf_tase (unsigned long long x) {
  return 0;
}
/*float __floatuntisf_tase_shim (unsigned long long x) {
  return __floatuntisf_tase(x);
  }*/

double __floatuntidf_tase (unsigned long long x) {
  return 0LL;
}
/*double __floatuntidf_tase_shim (unsigned long long x) {
  return __floatuntidf_tase(x);
  }*/

//Comparison

int __cmpsf2_tase (float x, float y) {
  return 0;
}
/*int __cmpsf2_tase_shim( float x, float y) {
  return __cmpsf2_tase(x,y);
  }*/

int __cmpdf2_tase (double x, double y) {
  return 0;
}
/*int __cmpdf2_tase_shim (double x, double y) {
  return __cmpdf2_tase(x,y);
  }*/

int __unordsf2_tase (float x, float y) {
  return 0;
}
/*int __unordsf2_tase_shim (float x, float y) {
  return __unordsf2_tase(x, y);
  }*/

int __unorddf2_tase (double x, double y) {
  return 0;
}
/*int __unorddf2_tase_shim (double x , double y) {
  return __unorddf2_tase(x,y);
  }*/

int __eqsf2_tase (float x, float y) {
  return 0;
}
/*int __eqsf2_tase_shim (float x, float y) {
  return __eqsf2_tase(x,y);
  }*/

int __eqdf2_tase (double x, double y) {
  return 0;
}
/*int __eqdf2_tase_shim (double x, double y) {
  return __eqdf2_tase(x,y);
  }*/

int __nesf2_tase (float x, float y) {
  return 0;
}
/*int __nesf2_tase_shim (float x, float y) {
  return __nesf2_tase(x,y);
  }*/

int __nedf2_tase (double x, double y) {
  return 0;
}
/*int __nedf2_tase_shim (double x, double y) {
  return __nedf2_tase(x,y);
  }*/

int __gesf2_tase (float x, float y) {
  return 0;
}
/*int __gesf2_tase_shim (float x, float y) {
  return __gesf2_tase(x,y);
  }*/

int __gedf2_tase (double x, double y) {
  return 0;
}
/*int __gedf2_tase_shim (double x, double y) {
  return __gedf2_tase(x,y);
  }*/

int __ltsf2_tase (float x, float y) {
  return 0;
}
/*int __ltsf2_tase_shim (float x, float y) {
  return __ltsf2_tase(x,y);
  }*/

int __ltdf2_tase (double x, double y) {
  return 0;
}
/*int __ltdf2_tase_shim (double x, double y) {
  return __ltdf2_tase(x,y);
  }*/

int __lesf2_tase (float x, float y) {
  return 0;
}
/*int __lesf2_tase_shim (float x, float y) {
  return __lesf2_tase(x,y);
  }*/

int __ledf2_tase (double x, double y) {
  return 0;
}
/*int __ledf2_tase_shim (double x, double y) {
  return __ledf2_tase(x,y);
  }*/

int __gtsf2_tase (float x, float y) {
  return 0;
}
/*int __gtsf2_tase_shim (float x, float y) {
  return __gtsf2_tase(x,y);
  }*/

int __gtdf2_tase (double x, double y) {
  return 0;
}
/*int __gtdf2_tase_shim (double x, double y) {
  return __gtdf2_tase(x,y);
  }*/

//Other

float __powisf2_tase (float x, int y) {
  return 0;
}
/*float __powisf2_tase_shim (float x, int y) {
  return __powisf2_tase(x,y);
  }*/

double __powidf2_tase (double x, int y) {
  return 0LL;
}
/*double __powidf2_tase_shim (double x, int y) {
  return __powidf2_tase(x,y);
  }*/

//Some string to float and int fns that we include
//as a workaround until we compile all of libc:
double strtod_tase(const char *nptr, char **endptr) {
  return 0LL;
}
/*double strtod_tase_shim(const char *nptr, char **endptr) {
  return strtod_tase(nptr, endptr);
  }*/

float strtof_tase(const char *nptr, char **endptr) {
  return 0;
}
/*float strtof_tase_shim (const char *nptr, char **endptr) {
  return strtof_tase(nptr, endptr);
  }*/

double strtold_tase (const char *nptr, char **endptr) {
  return 0LL;
}
/*double strtold_tase_shim (const char *nptr, char **endptr) {
  return strtold_tase(nptr,endptr);
  }*/


long strtol_tase(const char *nptr, char **endptr, int base) {
  return 0LL;
}

/*long strtol_tase_shim(const char *nptr, char **endptr, int base) {
  return strtol_tase( nptr, endptr, base);
  }*/

long long strtoll_tase(const char *nptr, char **endptr, int base) {
  return 0LL;
}

/*long long strtoll_tase_shim(const char *nptr, char **endptr, int base) {
  return strtoll_tase(nptr, endptr,  base);
  }*/

unsigned long strtoul_tase(const char *nptr, char **endptr, int base) {
  return 0LL;
}

/*unsigned long strtoul_tase_shim(const char *nptr, char **endptr, int base) {
  return strtoul_tase(nptr, endptr,  base);
  }*/

unsigned long long strtoull_tase(const char *nptr, char **endptr, int base) {
  return 0LL;
}

/*unsigned long long strtoull_tase_shim(const char *nptr, char **endptr, int base) {
  return strtoull_tase(nptr, endptr, base);
  }*/

intmax_t strtoimax_tase ( const char *restrict nptr, char **restrict endptr, int base ) {
  return 0LL;
}

/*intmax_t strtoimax_tase_shim ( const char *restrict nptr, char **restrict endptr, int base ) {
  return strtoimax_tase ( nptr,  endptr,  base );
  }*/

uintmax_t strtoumax_tase (const char *restrict nptr, char **restrict endptr, int base ) {
  return 0LL;
}

/*uintmax_t strtoumax_tase_shim (const char *restrict nptr, char **restrict endptr, int base ) {
  return strtoumax_tase ( nptr,  endptr,  base );
  }*/


float  wcstof_tase( const wchar_t* str, wchar_t** str_end ) {
  return 0;
}
/*float  wcstof_tase_shim( const wchar_t* str, wchar_t** str_end ) {
  return wcstof_tase( str, str_end );
  }*/

double  wcstod_tase( const wchar_t* str, wchar_t** str_end ) {
  return 0LL;
}
/*double  wcstod_tase_shim( const wchar_t* str, wchar_t** str_end ) {
  return wcstod_tase( str,  str_end );
  }*/

double  wcstold_tase( const wchar_t* str, wchar_t** str_end ) {
  return 0LL;
}
/*double  wcstold_tase_shim( const wchar_t* str, wchar_t** str_end ) {
  return wcstold_tase( str, str_end );
  }*/

long wcstol_tase ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return 0LL;
}
/*long wcstol_tase_shim ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return wcstol_tase (  str,  str_end,  base );
  }*/
long long wcstoll_tase ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return 0LL;
}
/*long long wcstoll_tase_shim ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return wcstoll_tase (  str, str_end,  base );
  }*/

unsigned long wcstoul_tase ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return 0LL;
}
/*unsigned long wcstoul_tase_shim ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return wcstoul_tase (  str,  str_end,  base );
  }*/
unsigned long long wcstoull_tase ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return 0LL;
}
/*unsigned long long wcstoull_tase_shim ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return wcstoull_tase (  str, str_end, base );
  }*/

intmax_t wcstoimax_tase ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return 0LL;
}
/*intmax_t wcstoimax_tase_shim ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return wcstoimax_tase (  str,  str_end,  base );
  }*/
uintmax_t wcstoumax_tase ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return 0LL;
}
/*uintmax_t wcstoumax_tase_shim ( const wchar_t * restrict str, wchar_t ** restrict str_end, int base ) {
  return wcstoumax_tase (  str,  str_end,  base );
  }*/

void * __pthread_self_tase() {
  return 0LL;
}

/*void * __pthread_self_tase_shim() {
  return __pthread_self_tase();
  }*/
