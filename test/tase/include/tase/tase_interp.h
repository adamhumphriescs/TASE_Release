/* TASE internal header for interpreter/native interface.
 *
 * We use the word "cartridge" here to mean something extremely close to an
 * LLVM machine basic block -- a sequence of non-terminating, non-barrier
 * instructions with a (usually) short tail of terminating instructions. The
 * important difference is that call instructions are considered terminating
 * instructions in a cartridge.
 *
 * a) Every cartridge begins with a "header" which is a sequence of instructions
 * that execute a properly identified springboard jump.  These instructions must
 * be idempotent - the interpreter and runtime should feel free to rerun these
 * instructions as many times as it needs to to begin cartridge execution.
 *
 * b) All cartridges may assume that any GPR or XMM register except the reserved
 * GPRs are preserved across control transfer boundaries.
 * Both native and interpreted instrumentation should comply with this.
 * EFLAGS is required to be dead at the entry of a cartridge.
 * LLVM MBBs should guarantee this and correctly spill EFLAGS across BBs unless
 * we run certain control flow modification passes. EFLAGS is already dead
 * across function calls as per the x64 ABI.
 *
 * c) Every cartridge has a "body" that trails the header. It contains all the
 * rest of the instructions in the cartridge (i.e. the useful ones).
 * The springboard will return to the start of the body if it was configured
 * correctly. Only TASE instrumentation may access the reserved GPRs
 * in the body but everything else would otherwise be *juuuuuust peachy!*
 *
 * d) Every cartridge body, should only contain one effective control transfer
 * instruction (i.e. a list of terminators or calls where only one of them
 * runs) and all out-bound control flow is assumed to be to another TASE
 * instrumented or TASE aware cartridge start address.  No other control flow
 * transfer is permitted. This includes calls to system libraries/uclibc
 * functions.  They should be modeled or compiled with TASE instrumentation.
 *
 * e) Any TASE cartridge has (must have) the ability to run *completely* in both
 * native hardware within TASE transactions or through the interpreter. The
 * practically implies that there must exist a cartridge IR function for each
 * cartridge. The flip side is that *only* TASE cartridges have any guarantee
 * of being interpretable (i.e have IR).
 *
 * f) Each cartridge should retain the ability to run with TASE/TSX
 * instrumentation disabled - i.e. it must retain the ability to be executed
 * outside a transaction if other code desires it. The caller code would
 * usually set the tase_springboard variable correct.
 *
 * See the structure definition of tase_record_t to see how the record register
 * is organized and why.
 */

#ifndef TASE_INTERP_H
#define TASE_INTERP_H

#include "tase.h"

/* Internal interpretation details of TASE */

/* Number of each register in the gregs array */
#define GREG_RAX                 0
#define GREG_RBX                 1
#define GREG_RCX                 2
#define GREG_RDX                 3
#define GREG_RSI                 4
#define GREG_RDI                 5
#define GREG_RBP                 6
#define GREG_RSP                 7
#define GREG_R8                  8
#define GREG_R9                  9
#define GREG_R10                10
#define GREG_R11                11
#define GREG_R12                12
#define GREG_R13                13
#define GREG_R14                14
#define GREG_R15                15
/* Alias to support legacy single-instruction interpreter. */
#define GREG_RIP                16
#define GREG_EFL                17
/* Number of general registers.  */
#define TASE_NGREG                   18
#define TASE_GREG_SIZE                8

#define NXMMREG                 16
#define XMMREG_SIZE             16

#define SB_FLAG_LOGABORT_BASIC         0x1
#define SB_FLAG_LOGABORT_STACK         0x2

#define CTX_OFFSET_STACK_TOP           (STACK_SIZE - 24)
#define CTX_OFFSET_TARGET_EXIT_ADDR    (STACK_SIZE - 24)
#define CTX_OFFSET_SENTINEL1           (STACK_SIZE - 16)
#define CTX_OFFSET_SENTINEL2           (STACK_SIZE - 8)
#define CTX_OFFSET_XMMREGS             (STACK_SIZE)
#define CTX_OFFSET_XMMREG(n)           (((n) * XMMREG_SIZE) + CTX_OFFSET_XMMREGS)
#define CTX_OFFSET_GREGS               CTX_OFFSET_XMMREG(NXMMREG)
#define CTX_OFFSET_GREG(n)             (((n) * TASE_GREG_SIZE) + CTX_OFFSET_GREGS)
#define CTX_OFFSET_INTERP_STACK        CTX_OFFSET_GREG(TASE_NGREG)
#define CTX_OFFSET_ABORT_STATUS        (8 + CTX_OFFSET_INTERP_STACK)
#define CTX_OFFSET_LAST_ABORT_STATUS   (4 + CTX_OFFSET_ABORT_STATUS)
#define CTX_OFFSET_STATUS              (8 + CTX_OFFSET_ABORT_STATUS)

/* If in GPR instrumentation - we use 12 and 13. */
#define REG_ACC0                12
#define REG_ACC1                13

/* All modes reserve 14 and 15 - whether they use it or not.  R15 will always be RIP. */
#define REG_TMP                 14
#define REG_RET                 15

/* If in SIMD instrumentation we use 3 XMM registers. */
#define REG_REFERENCE           13
#define REG_ACCUMULATOR         14
#define REG_DATA                15

#define TSX_XABORT               0
#define TSX_RETRY                1
#define TSX_CONFLICT             2
#define TSX_CAPACITY             3
#define TSX_DEBUG                4
#define TSX_NESTED               5
#define TSX_NUM_CODES            6
#define TSX_XABORT_MASK          0xFF000000

#ifndef IN_ASM

#ifdef __cplusplus
#include <cstdint>
#include <cstddef>
#include <csetjmp>

extern "C" {
#else
#include <stdint.h>
#include <stddef.h>
#include <setjmp.h>
#include <stdalign.h>
#endif  // _cplusplus


#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpedantic"
#elif defined __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
#endif

/* Type for general register.  */
typedef union {
  uint64_t   u64;
  int64_t    i64;
  uint32_t   u32;
  int32_t    i32;
  uint16_t   u16;
  int16_t    i16;
  struct {
    uint8_t  u8;
    uint8_t  hu8;
  };
  struct {
    int8_t   i8;
    int8_t   hi8;
  };
  void       *ptr;
  char       bytes[TASE_GREG_SIZE];
} tase_greg_t;

typedef struct {
  alignas(16) uint64_t qword[2];
} xmmreg_t;
typedef struct {
  alignas(32) uint64_t qword[4];
} ymmreg_t;

/* Target context used during context switches and interpretation. */
/* Note - generally we assume that KLEE interpretation will use much
 * more stack space than the target program itself.
 * Hence, leave KLEE's stack as the process auto-stack.
 * Put the entire target code's stack here.
 */
typedef struct {
  // The 3 qwords at the top are for a return address, and 2 sentinels.
  alignas(PAGE_SIZE) uint8_t    target_stack[STACK_SIZE - 3 * 8];
  uintptr_t  target_exit_addr;
  // We need to guard 16 bytes of stack here because X64 return expects
  // the return address to to 16 byte aligned between function calls.
  uint64_t   sentinel[2];
  // Should already be 16 byte aligned here for XMMs.
  union {
    xmmreg_t xmmregs[NXMMREG];
    struct {
      xmmreg_t xmm0;
      xmmreg_t xmm1;
      xmmreg_t xmm2;
      xmmreg_t xmm3;
      xmmreg_t xmm4;
      xmmreg_t xmm5;
      xmmreg_t xmm6;
      xmmreg_t xmm7;
      xmmreg_t xmm8;
      xmmreg_t xmm9;
      xmmreg_t xmm10;
      xmmreg_t xmm11;
      xmmreg_t xmm12;
      union {
        xmmreg_t xmm13;
        xmmreg_t reference;
      };
      union {
        xmmreg_t xmm14;
        xmmreg_t accumulator;
      };
      union {
        xmmreg_t xmm15;
        xmmreg_t data;
      };
    };
  };
  union {
    tase_greg_t   gregs[TASE_NGREG];
    struct {
      tase_greg_t rax;
      tase_greg_t rbx;
      tase_greg_t rcx;
      tase_greg_t rdx;
      tase_greg_t rsi;
      tase_greg_t rdi;
      tase_greg_t rbp;
      tase_greg_t rsp;
      tase_greg_t r8;
      tase_greg_t r9;
      tase_greg_t r10;
      tase_greg_t r11;
      union {
        tase_greg_t r12;
        uint64_t acc0;
      };
      union {
        tase_greg_t r13;
        uint64_t acc1;
      };
      union {
        tase_greg_t r14;
        uint64_t tmp;
      };
      tase_greg_t r15;
      tase_greg_t rip;
      tase_greg_t efl;
    };
  };
  // Everything below this address in the auto-stack is safe for use.
  // Set by the injector for the ejector.
  uintptr_t interpreter_stack;
  // Saved Intel RTM TSX abort status.  Only valid if we did abort and eject.
  uint32_t  abort_status;
  uint32_t  last_abort_status;

  uint64_t  status;
  jmp_buf   interpreter_jump_buffer;
  uint32_t  abort_counts[TSX_NUM_CODES];
  uint32_t  abort_count_modeled;
  uint32_t  abort_count_poison;
  uint32_t  abort_count_unknown;
  uint32_t  abort_count_total;
} target_ctx_t;

#ifdef __clang__
#pragma clang diagnostic pop
#elif defined __GNUC__
#pragma GCC diagnostic pop
#endif

// These contain the bottom 32-bits of the header location of a TASE cartridge.
// Also holds the offsets to the body from the header and to the end from the
// body.  We are building with a "small" code-model i.e. we are guaranteed that
// all code is < 2GB to simplify jump calculations. This lets us get away with
// only storing the bottom 32-bits.
typedef struct {
  uint32_t head;
  uint16_t head_size;
  uint16_t body_size;
} tase_record_t;

extern target_ctx_t target_ctx;
// Imported from the linker - it gives us the section boundaries of
// .rodata.tase_records.
extern const tase_record_t tase_global_records[];
extern const size_t tase_num_global_records;
  
extern const tase_record_t tase_live_flags_block_records[];
extern const size_t tase_num_live_flags_block_records;
  
// Anything prefixed with tase_ is run on the interpreter stack and in the
// interpreter "no-transactions" context.
// Anything prefixed with sb_ is...  well it's assembly code that jumps around.
// It jumps jumps jumps and jumps up to get down to target code.

// Setup functions.
extern void tase_tranlog();
extern void tase_walk_pages();

// Sets up the interpreter jump buffer and calls sb_inject - the call is
// important.  It gives sb_inject a clean stack top.
// This function returns when target code has decided to eject back to the
// simulator.
extern void tase_inject(int tase_enable);
// Is called by sb_eject.  Does any context fixups and then jumps up.
// This function "returns" through tase_inject back into the interpreter.
extern void tase_eject() __attribute__((noreturn));

// Assembly routines - only the injection/ejection methods can reference them.
extern void sb_inject();
extern void exit_tase_shim();
extern void sb_open();
extern void sb_reopen();
extern void sb_disabled();
extern void sb_modeled();
extern void sb_modeled_return();

extern uint64_t tran_ctr;
extern uint64_t tran_max;
extern void *tase_springboard;
extern void *tase_model;  //Similar to tase_springboard.  Will typically just point to sb_modeled
extern void *tase_modeled_return;
extern const uint64_t tase_poison_reference;

#ifdef __cplusplus
}
#endif

#endif /* IN_ASM */
#endif /* TASE_INTERP_H */
