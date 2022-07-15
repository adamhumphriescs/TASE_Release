#include <stdio.h>
#include <stdlib.h>
#include "tase.h"
#include "tase_interp.h"

#ifndef TASE_INTERP

#ifndef TASE_ENABLE
#define TASE_ENABLE 0
#endif

extern void begin_target_inner();

static void run_target(target_fun_t f) {
  memset(&target_ctx, 0, sizeof(target_ctx));
  enter_tase(f, TASE_ENABLE);
  // TODO: This is a stupid hack - actually extract the range of exit_tase
  // from our cartridge table.
  uint64_t exit_tase_bottom = (uint64_t) &exit_tase;
  uint64_t exit_tase_top = exit_tase_bottom + 64;

  while (target_ctx.rip.u64 < exit_tase_bottom || target_ctx.rip.u64 > exit_tase_top) {
    printf("Returned to interpreter/harness from %lx\n", target_ctx.rip.u64);
    // TODO: Do some simple modeling if needed.
    // TODO: Verify that ejection was due to modeled call.
    if (target_ctx.abort_status >> 24 != 1 && target_ctx.abort_status & 0xff != 1) {
      printf("Bad return - not from modeled function ejection with status: %x\n", target_ctx.abort_status);
      exit(0);
    }
    target_ctx.rip.u64 = *(uint64_t *)target_ctx.rsp.ptr;
    target_ctx.rsp.u64 += 8;
    tase_inject(TASE_ENABLE);
  }
  printf("Inferred a call to exit_tase - exiting %lx\n", target_ctx.rip.u64);
}

int main () {

  tase_walk_pages();
  printf("Start run:\n");
  run_target(&begin_target_inner);
  printf("End run:\n");
  return 0;
}

#endif
