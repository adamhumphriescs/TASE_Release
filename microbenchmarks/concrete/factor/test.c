#include "config.h"
//#include <getopt.h>
#include <stdio.h>
//#include <gmp.h> //We use mini-gmp.c instead
#include <assert.h>

//#include "system.h"
//#include "die.h"
//#include "error.h"
//#include "full-write.h"
//#include "quote.h"
#include "readtokens.h"
#include "xstrtol.h"

# if UINTMAX_MAX == UINT32_MAX
#  define W_TYPE_SIZE 32
# elif UINTMAX_MAX == UINT64_MAX
#  define W_TYPE_SIZE 64
# elif UINTMAX_MAX == UINT128_MAX
#  define W_TYPE_SIZE 128
# endif

# define __ll_B ((uintmax_t) 1 << (W_TYPE_SIZE / 2))
# define __ll_lowpart(t)  ((uintmax_t) (t) & (__ll_B - 1))
# define __ll_highpart(t) ((uintmax_t) (t) >> (W_TYPE_SIZE / 2))

#define MAX_NFACTS 26

#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "intprops.h"

# define LIKELY(cond)    (cond)
# define UNLIKELY(cond)  (cond)
#define ISDIGIT(c) ((unsigned int) (c) - '0' <= 9)

struct factors
{
  uintmax_t     plarge[2]; /* Can have a single large factor */
  uintmax_t     p[MAX_NFACTS];
  unsigned char e[MAX_NFACTS];
  unsigned char nfactors;
};

#define P(a,b,c,d) a,
static const unsigned char primes_diff[] = {
#include "primes.h"
0,0,0,0,0,0,0                           /* 7 sentinels for 8-way loop */
};
#undef P

#define PRIMES_PTAB_ENTRIES \
  (sizeof (primes_diff) / sizeof (primes_diff[0]) - 8 + 1)

#define P(a,b,c,d) b,
static const unsigned char primes_diff8[] = {
#include "primes.h"
0,0,0,0,0,0,0                           /* 7 sentinels for 8-way loop */
};
#undef P

struct primes_dtab
{
  uintmax_t binv, lim;
};

#define P(a,b,c,d) {c,d},
static const struct primes_dtab primes_dtab[] = {
#include "primes.h"
{1,0},{1,0},{1,0},{1,0},{1,0},{1,0},{1,0} /* 7 sentinels for 8-way loop */
};
#undef P


static strtol_error
strto2uintmax (uintmax_t *hip, uintmax_t *lop, const char *s)
{
  unsigned int lo_carry;
  uintmax_t hi = 0, lo = 0;

  strtol_error err = LONGINT_INVALID;

  /* Initial scan for invalid digits.  */
  const char *p = s;
  for (;;)
    {
      unsigned int c = *p++;
      if (c == 0)
        break;

      if (UNLIKELY (!ISDIGIT (c)))
        {
          err = LONGINT_INVALID;
          break;
        }

      err = LONGINT_OK;           /* we've seen at least one valid digit */
    }

  while (err == LONGINT_OK)
    {
      unsigned int c = *s++;
      if (c == 0)
        break;

      c -= '0';

      if (UNLIKELY (hi > ~(uintmax_t)0 / 10))
        {
          err = LONGINT_OVERFLOW;
          break;
        }
      hi = 10 * hi;

      lo_carry = (lo >> (W_TYPE_SIZE - 3)) + (lo >> (W_TYPE_SIZE - 1));
      lo_carry += 10 * lo < 2 * lo;

      lo = 10 * lo;
      lo += c;

      lo_carry += lo < c;
      hi += lo_carry;
      if (UNLIKELY (hi < lo_carry))
        {
          err = LONGINT_OVERFLOW;
          break;
        }
    }

  *hip = hi;
  *lop = lo;

  return err;
}


#ifndef count_trailing_zeros
# define count_trailing_zeros(count, x) do {                            \
    uintmax_t __ctz_x = (x);                                            \
    unsigned int __ctz_c = 0;                                           \
    while ((__ctz_x & 1) == 0)                                          \
      {                                                                 \
        __ctz_x >>= 1;                                                  \
        __ctz_c++;                                                      \
      }                                                                 \
    (count) = __ctz_c;                                                  \
  } while (0)
#endif

#define rsh2(rh, rl, ah, al, cnt)                                       \
  do {                                                                  \
    (rl) = ((ah) << (W_TYPE_SIZE - (cnt))) | ((al) >> (cnt));           \
    (rh) = (ah) >> (cnt);                                               \
  } while (0)

#ifndef umul_ppmm
# define umul_ppmm(w1, w0, u, v)                                        \
  do {                                                                  \
    uintmax_t __x0, __x1, __x2, __x3;                                   \
    unsigned long int __ul, __vl, __uh, __vh;                           \
    uintmax_t __u = (u), __v = (v);                                     \
                                                                        \
    __ul = __ll_lowpart (__u);                                          \
    __uh = __ll_highpart (__u);                                         \
    __vl = __ll_lowpart (__v);                                          \
    __vh = __ll_highpart (__v);                                         \
                                                                        \
    __x0 = (uintmax_t) __ul * __vl;                                     \
    __x1 = (uintmax_t) __ul * __vh;                                     \
    __x2 = (uintmax_t) __uh * __vl;                                     \
    __x3 = (uintmax_t) __uh * __vh;                                     \
                                                                        \
    __x1 += __ll_highpart (__x0);/* this can't give carry */            \
    __x1 += __x2;               /* but this indeed can */               \
    if (__x1 < __x2)            /* did we get it? */                    \
      __x3 += __ll_B;           /* yes, add it in the proper pos. */    \
                                                                        \
    (w1) = __x3 + __ll_highpart (__x1);                                 \
    (w0) = (__x1 << W_TYPE_SIZE / 2) + __ll_lowpart (__x0);             \
  } while (0)
#endif

static void
factor_insert_multiplicity (struct factors *factors,
                            uintmax_t prime, unsigned int m)
{
  unsigned int nfactors = factors->nfactors;
  uintmax_t *p = factors->p;
  unsigned char *e = factors->e;

  /* Locate position for insert new or increment e.  */
  int i;
  for (i = nfactors - 1; i >= 0; i--)
    {
      if (p[i] <= prime)
        break;
    }

  if (i < 0 || p[i] != prime)
    {
      for (int j = nfactors - 1; j > i; j--)
        {
          p[j + 1] = p[j];
          e[j + 1] = e[j];
        }
      p[i + 1] = prime;
      e[i + 1] = m;
      factors->nfactors = nfactors + 1;
    }
  else
    {
      e[i] += m;
    }
}

#define factor_insert(f, p) factor_insert_multiplicity (f, p, 1)

static void
factor_insert_refind (struct factors *factors, uintmax_t p, unsigned int i,
                      unsigned int off)
{
  for (unsigned int j = 0; j < off; j++)
    p += primes_diff[i + j];
  factor_insert (factors, p);
}


static uintmax_t
factor_using_division (uintmax_t *t1p, uintmax_t t1, uintmax_t t0,
                       struct factors *factors)
{
  printf("Division with: %lx, %lx, %ld\n", t1, t0, t0 % 2);
  if (t0 % 2 == 0)
    {
      unsigned int cnt;

      if (t0 == 0)
        {
          count_trailing_zeros (cnt, t1);
          t0 = t1 >> cnt;
          t1 = 0;
          cnt += W_TYPE_SIZE;
	  printf("cnt: %d\n", cnt);
        }
      else
        {
          count_trailing_zeros (cnt, t0);
	  printf("ctz: %d\n", cnt);
          rsh2 (t1, t0, t1, t0, cnt);
	  printf("rsh2: %lx, %lx, %d\n", t1, t0, cnt);
        }

      factor_insert_multiplicity (factors, 2, cnt);
    }
  
  printf("partial: %lx, %lx\n", t1, t0);
  uintmax_t p = 3;
  unsigned int i;
  for (i = 0; t1 > 0 && i < PRIMES_PTAB_ENTRIES; i++)
    {
      for (;;)
        {
          uintmax_t q1, q0, hi, lo _GL_UNUSED;

          q0 = t0 * primes_dtab[i].binv;
          umul_ppmm (hi, lo, q0, p);
          if (hi > t1)
            break;
          hi = t1 - hi;
          q1 = hi * primes_dtab[i].binv;
          if (LIKELY (q1 > primes_dtab[i].lim))
            break;
          t1 = q1; t0 = q0;
          factor_insert (factors, p);
        }
      p += primes_diff[i + 1];
    }
  if (t1p)
    *t1p = t1;

  printf("middle: %lx, %lx\n", t1, t0);
  fflush(stdout);  
#define DIVBLOCK(I)                                                     \
  do {                                                                  \
    for (;;)                                                            \
      {                                                                 \
        q = t0 * pd[I].binv;                                            \
        if (LIKELY (q > pd[I].lim))                                     \
          break;                                                        \
        t0 = q;                                                         \
        factor_insert_refind (factors, p, i + 1, I);                    \
      }                                                                 \
  } while (0)

  for (; i < PRIMES_PTAB_ENTRIES; i += 8)
    {
      uintmax_t q;
      const struct primes_dtab *pd = &primes_dtab[i];
      DIVBLOCK (0);
      DIVBLOCK (1);
      DIVBLOCK (2);
      DIVBLOCK (3);
      DIVBLOCK (4);
      DIVBLOCK (5);
      DIVBLOCK (6);
      DIVBLOCK (7);

      p += primes_diff8[i];
      if (p * p > t0)
        break;
    }

  return t0;
}



int main(int argv, char **argc){
  uintmax_t a, b;
  strto2uintmax(&b, &a, "16895424309675413218152718641574491217");
  printf("%lx, %lx\n", a, b);

  struct factors factors;
  factors.nfactors = 0;
  factors.plarge[1] = 0;
  uintmax_t x = factor_using_division(&b, b, a, &factors);
  printf("%lx, %lx, %lx\n", b, a, x);
}
