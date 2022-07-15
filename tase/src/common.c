#include "tase.h"
#include "tase_interp.h"
#include "tase_modeled.h"
#include <setjmp.h>
#include <stdnoreturn.h>
#include <string.h>

// Zeroed - enter_tase will initialize/
target_ctx_t target_ctx;

void enter_tase(target_fun_t fun, int enable_tase) {
  tase_model = sb_modeled;
  
  target_ctx.target_exit_addr = (uintptr_t)&exit_tase_shim;
  target_ctx.sentinel[0] = CTX_STACK_SENTINEL;
  target_ctx.sentinel[1] = CTX_STACK_SENTINEL;
  target_ctx.rip.ptr = (void *)fun;
  // We pretend like we have pushed a return address as part of call.
  target_ctx.rsp.u64 = (uint64_t)(&target_ctx.target_exit_addr);
  // Just to be careful.  rbp should not be necessary but debuggers like it.
  target_ctx.rbp.u64 = target_ctx.rsp.u64 + sizeof(uintptr_t);
  // EFLAGS is 0 by default.
  // TODO: Enable logging.
  // target_ctx.status = SB_FLAG_LOGABORT_BASIC | SB_FLAG_LOGABORT_STACK;
  target_ctx.status = 0;
  target_ctx.reference.qword[0] = POISON_REFERENCE64;
  target_ctx.reference.qword[1] = POISON_REFERENCE64;

  tase_inject(enable_tase);
}

/* Needs to set up register state needed to context switch into target
 * code. The actual GPRs should already be accurate.  Just set up
 * control state, perhaps log some stuff and inject into the target
 * context.
 */
void tase_inject(int enable_tase) {
  // Yes we want to start the magic - but we are entering from outside
  // transactions.
  tase_springboard = enable_tase && !tase_modeled_return ? &sb_open : &sb_disabled;
  target_ctx.last_abort_status = target_ctx.abort_status;
  target_ctx.abort_status = 0;
  target_ctx.r15.ptr = target_ctx.rip.ptr;
  // TODO: Verify the sentinel and log?
  // TODO: Double check we don't have taint?
  // TODO: Double check RIP is not a modeled function.
  int ret = setjmp(target_ctx.interpreter_jump_buffer);
  if (ret == 0) {
    // We are on our way in!  This path does not return.
    sb_inject();
  }
  // We are returning from tase_eject.  Return normally.
}

/* This function starts with a bare-bones stack with no return address.
 * It *must* not return and needs to exit explicitly to a prior return context.
 */
void noreturn tase_eject() {
  // Oh hey a triumphant return from target execution. Maybe analyze some
  // things?
  // TODO: In the interpreter, ensure that whoever calls enter_tase
  // does the right thing with respect to multi-pass stuff.
  target_ctx.rip.ptr = target_ctx.r15.ptr;
  uint32_t abort_status = target_ctx.abort_status;
  target_ctx.abort_count_total++;
  if ((abort_status & 0xff) == 0) {
    target_ctx.abort_count_unknown++;
  } else if (abort_status & (1 << TSX_XABORT)) {
    if (abort_status & TSX_XABORT_MASK) {
      target_ctx.abort_count_modeled++;
    } else {
      target_ctx.abort_count_poison++;
    }
  }
  for (int i = 0; i < TSX_NUM_CODES; i++) {
    target_ctx.abort_counts[i] += abort_status & 0x1;
    abort_status >>= 1;
  }
  if (target_ctx.status & (SB_FLAG_LOGABORT_BASIC | SB_FLAG_LOGABORT_STACK)) {
    tase_tranlog();
  }

  longjmp(target_ctx.interpreter_jump_buffer, 1);
}


void tase_walk_pages() {
  int i;
  volatile uint32_t buffer[STACK_SIZE / sizeof(uint32_t)];
  for (i = (STACK_SIZE - 4096) / sizeof(uint32_t);
      i >= 0;
      i -= 4096 / sizeof(uint32_t)) {
    buffer[i] = 0xdeadbeef;
  }

}

void debug_marker() {
  static int debug_marker_count = 0;
  debug_marker_count++;
}
