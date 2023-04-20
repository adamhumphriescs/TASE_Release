#ifndef TASE_HACK_H
#define TASE_HACK_H
#include <stdio.h>

#define calloc calloc_tase
extern void * calloc_tase (unsigned long num, unsigned long size);

#define realloc realloc_tase
extern void * realloc_tase (void * ptr, unsigned long new_size);

#define malloc malloc_tase
extern void * malloc_tase(unsigned long s);

#define free free_tase
extern void free_tase(void * ptr);

#define getc_unlocked getc_unlocked_tase
extern int getc_unlocked_tase(FILE * f);


#define memcpy memcpy_tase
extern void * memcpy_tase(void * dest, const void * src, unsigned long n);
/*
#define memset memset_tase
extern void * memset_tase (void * dest, int val , unsigned long size);


#define memmove memmove_tase
extern void * memmove_tase (void * dest, const void * src, unsigned long n);
*/

/*
#define strcpy strcpy_tase
extern char * strcpy_tase (char * dest, const char * src);

#define strncpy strncpy_tase
extern char * strncpy_tase (char * dest, const char * src, unsigned long n);
*/


#endif 
