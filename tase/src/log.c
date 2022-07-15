#include "tase.h"
#include "tase_interp.h"
#include <stdio.h>
#include <stdlib.h>

unsigned int abort_count = 0;

const char * const GREG_NAMES[] = {
  "RAX", "RBX", "RCX", "RDX", "RSI", "RDI", "RBP", "RSP",
  "R8", "R9", "R10", "R11", "R12", "R13", "R14", "R15", "RIP", "EFL"
};

const char * const XMM_NAMES[] = {
  "XMM0", "XMM1", "XMM2", "XMM3", "XMM4", "XMM5", "XMM6", "XMM7",
  "XMM8", "XMM9", "XMM10", "XMM11", "XMM12", "XMM13", "XMM14", "XMM15"
};

void tase_tranlog() {
  puts("Ejecting: ");
  int i;
  for (i = 0; i < TASE_NGREG; i++) {
    printf("%-6s : 0x%016lx%s",
        GREG_NAMES[i],
        target_ctx.gregs[i].u64, i % 4 == 3 ? "\n" : "  " );
  }

  for (i = 0; i < NXMMREG; i++) {
    printf("%-12s :-> 0x%016lx%016lx\n",
        XMM_NAMES[i],
        target_ctx.xmmregs[i].qword[1],
        target_ctx.xmmregs[i].qword[0]);
  }

  puts("\n\n");
  abort_count++;
  if ((MAX_ABORT_COUNT != 0 && abort_count > MAX_ABORT_COUNT) ||
      (target_ctx.status & SB_FLAG_LOGABORT_STACK)) {
    uintptr_t stack_current = target_ctx.rsp.u64 & ~(0x7);
    for (uintptr_t stack_ptr = (uintptr_t)(target_ctx.target_stack + STACK_SIZE - 4 * 8);
        stack_ptr >= stack_current;
        stack_ptr -= 32) {
      uint64_t *stack_cell = (uint64_t *)stack_ptr;
      printf("0x%016lx: 0x%016lx 0x%016lx 0x%016lx 0x%016lx\n",
          stack_ptr, stack_cell[0], stack_cell[1], stack_cell[2], stack_cell[3]);
    }
    exit(0);
  }
}
