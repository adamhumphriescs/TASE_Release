#ifndef TASE_SHIMS_H_
#define TASE_SHIMS_H_

#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

  void * malloc_tase(long int size);
  //  void * malloc_tase_shim(long int size);
  void * realloc_tase(void * ptr, long int size);
  //  void * realloc_tase_shim(void * ptr, long int size);
  void * calloc_tase (long int num, long int size);
  //  void * calloc_tase_shim (long int num, long int size);
  void free_tase (void * ptr);
  //  void free_tase_shim(void * ptr);
  void * memcpy_tase(void * dest, const void * src, unsigned long n);
  FILE *freopen_tase(const char *filename, const char *mode, FILE *stream);
  void * tase_make_symbolic(void * addr, unsigned long size, const char * name);
  
  int * getc_unlocked_tase (FILE * f);
  //  int * getc_unlocked_tase_shim (FILE * f);
  int puts_tase(const char * str);
  //  int puts_tase_shim(const char * str);
  int printf_tase(const char * format, ...);
  int sprintf_tase(char * str, const char * format, ...);
  
  double strtod_tase(const char *nptr, char **endptr);
  float strtof_tase(const char *nptr, char **endptr);
  double strtold_tase (const char *nptr, char **endptr);
  long strtol_tase(const char *nptr, char **endptr, int base);
  long long strtoll_tase(const char *nptr, char **endptr, int base);
  unsigned long strtoul_tase(const char *nptr, char **endptr, int base);
  unsigned long long strtoull_tase(const char *nptr, char **endptr, int base);
  intmax_t strtoimax_tase ( const char * nptr, char ** endptr, int base );
  uintmax_t strtoumax_tase (const char * nptr, char ** endptr, int base );
  
  double  wcstod_tase( const wchar_t* str, wchar_t** str_end );
  float wcstof_tase( const wchar_t* str, wchar_t** str_end );
  double  wcstold_tase( const wchar_t* str, wchar_t** str_end );
  long wcstol_tase ( const wchar_t *  str, wchar_t **  str_end, int base );
  long long wcstoll_tase ( const wchar_t *  str, wchar_t **  str_end, int base );
  unsigned long wcstoul_tase ( const wchar_t *  str, wchar_t **  str_end, int base );
  unsigned long long wcstoull_tase ( const wchar_t *  str, wchar_t **  str_end, int base );
  intmax_t wcstoimax_tase ( const wchar_t *  str, wchar_t **  str_end, int base );
  uintmax_t wcstoumax_tase ( const wchar_t *  str, wchar_t **  str_end, int base );
  int fflush_tase(FILE* stream);
  int fflush_tase_shim(FILE* stream);  
  FILE *fopen_tase(const char *filename, const char *mode);

  int fileno_tase(FILE *stream);
  size_t fread_tase(void *ptr, size_t size, size_t nmemb, FILE *stream);
  int ferror_tase(FILE *stream);
  int feof_tase(FILE *stream);
  int fclose_tase(FILE *stream);
  int posix_fadvise_tase(int fd, off_t offset, off_t len, int advice);
  int fseek_tase(FILE *stream, long int offset, int whence);
  void rewind_tase(FILE *stream);
  long int ftell_tase(FILE *stream);

  int isatty_tase(int fd);
  int fprintf_tase(FILE *stream, const char *format, ...);
  int vasprintf_tase(char **strp, const char *fmt, va_list ap);
  int vsnprintf_tase (char * s, size_t n, const char * format, va_list arg );
  size_t fwrite_tase(const void *ptr, size_t size, size_t nmemb, FILE *stream);
  int putchar_tase(int i, char c);
  ssize_t write_tase(int fd, const void *buf, size_t count);
  
  void * __pthread_self_tase();
  
#ifdef __cplusplus
}
#endif

#endif
