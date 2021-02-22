/* Public interface - if you are attempting to use TASE, you
 * will need these values.
 */
#ifndef TASE_H
#define TASE_H

#define PAGE_SIZE     4096
#define BUFFER_SIZE   256
#define STACK_PAGES   8192
#define STACK_SIZE    (PAGE_SIZE * STACK_PAGES)

#define STDIN_FD 0
/* Need to determine a valid val or make it a static global. */
#define SOCKET_FD -1

/* Debugging support:
 * Set to 0 to disable.
 * Set to some number to terminate execution after encountering
 * that many aborted transactions.
 */
#define MAX_ABORT_COUNT 0
/* Sentinel value on stack - should there be a stack smash in the target. */
#define CTX_STACK_SENTINEL      0x1BADF00D4DADB0D1
#define CTX_STACK_SENTINEL      0x1BADF00D4DADB0D1
/* Poison values during instrumented execution that you need to minimize
 * using in the target application
 */
#define POISON_SIZE             2
#define POISON_REFERENCE16      0xDEAD
#define POISON_REFERENCE32      0xDEADDEAD
#define POISON_REFERENCE64      0xDEADDEADDEADDEAD

#if !defined(TASE_INSTRUMENTATION_GPR) && !defined(TASE_INSTRUMENTATION_SIMD) && !defined(TASE_INSTRUMENTATION_NONE)
#define TASE_INSTRUMENTATION_SIMD
#endif

#ifndef IN_ASM

#ifdef __cplusplus
extern "C" {
  #endif

typedef void (*target_fun_t)(void);

/* Returns if a transaction fails to complete or if a modeled function forces
 * an ejection from TASE mode.
 */
extern void enter_tase(target_fun_t fun, int enable_tase);
/* A "modeled" function -- i.e. it just a way for us to stop interpretation.
 * It should never return.  The sentinels on the call stack are to enforce
 * the fact that this function should never read arguments (it has none of them)
 * and should never attempt to return normally. All paths must go through
 * exit.
 */
extern void exit_tase() __attribute__((noreturn));

extern void debug_marker();

#ifdef __cplusplus
}
#endif
  
#endif

#endif
