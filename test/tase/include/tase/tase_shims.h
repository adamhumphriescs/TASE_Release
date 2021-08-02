#ifndef TASE_SHIMS_H_
#define TASE_SHIMS_H_

#ifdef __cplusplus
extern "C" {
#endif

  void * malloc_tase(long int size);
  void * realloc_tase(void * ptr, long int size);
  void * calloc_tase (long int num, long int size);
  void free_tase (void * ptr);
  void * memcpy_tase(void * dest, const void * src, unsigned long n);

  void * tase_make_symbolic(void * addr, unsigned long size, const char * name);
  
  int * getc_unlocked_tase (FILE * f);
  int puts_tase(const char * str);
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

  int a_ctz_64_tase(uint64_t x);
  int a_clz_64_tase(uint64_t x);
  void * __pthread_self_tase();
  
#ifdef __cplusplus
}
#endif

#endif
