/* TASE springboard assembly macros. */

#ifndef TASE_ASM_H
#define TASE_ASM_H

#ifndef IN_ASM
#define IN_ASM
#endif

#include "tase.h"
#include "tase_interp.h"

/* Useful names */
#define EXPAND(x) x
#define GPR_ACC0    %r12
#define GPR_ACC1    %r13
#define GPR_TMP     %r14
#define GPR_RET     %r15

#define GPR_ACC0D   %r12d
#define GPR_ACC1D   %r13d
#define GPR_TMPD    %r14d
#define GPR_RETD    %r15d

#define XMM_REFERENCE    %xmm13
#define XMM_ACCUMULATOR  %xmm14
#define XMM_DATA         %xmm15

#define GREG_Rax     GREG_RAX
#define GREG_Rbx     GREG_RBX
#define GREG_Rcx     GREG_RCX
#define GREG_Rdx     GREG_RDX
#define GREG_Rsi     GREG_RSI
#define GREG_Rdi     GREG_RDI
#define GREG_Rbp     GREG_RBP
#define GREG_Rsp     GREG_RSP

/* Don't switch to the data section in case we are doing some dense
 * encoding.
 */
#define DEF_UINT64(name, value) .data ; .globl name; .align 8; .type name,@object; name ## : ; .quad value; .size name, 8
#define DEF_UINT64_CONST(name, value) .rodata ; .globl name; .align 8; .type name,@object; name ## : ; .quad value; .size name, 8

/* Reference to any target context value - see if absolute offsets give us a smaller encoding. */
#define CTX(off)                       target_ctx+EXPAND(off)
/* Reference to registers in the shared context. */
#define CTX_REG(reg_idx)               CTX(CTX_OFFSET_GREG(reg_idx))
#define CTX_XMMREG(reg_idx)            CTX(CTX_OFFSET_XMMREG(reg_idx))
#define _IMM_IMPL(name)                $ ## name
#define IMM(name)                      _IMM_IMPL(name)
#define _LABEL_IMPL(fname,label)       fname ## _ ## label
#define LABEL(fname,label)             _LABEL_IMPL(fname, label)

/* Function prologue/epilogue */
#define DEF_FUNC(name) .text ; .globl name ; .align  16, 0x90 ; .type name,@function; name ## : ; .cfi_startproc
#define END_FUNC(name) LABEL(name,func_end): ; .size name, LABEL(name,func_end)-name ; .cfi_endproc

/* Store a general purpose register into shared context.
 * CTX_STORE/CTX_LOAD expects to see a number (8-15) or a lower case
 * register name like ax, bx, si etc.
 */
#define _CTX_STORE_REG_IMPL(reg, reg_name)  movq %r ## reg_name, CTX_REG(reg)
#define CTX_STORE_REG(reg, reg_name)        _CTX_STORE_REG_IMPL(reg, reg_name)
#define _CTX_STORE_IMPL(reg_name)           CTX_STORE_REG(GREG_R ## reg_name, reg_name)
#define CTX_STORE(reg_name)                 _CTX_STORE_IMPL(reg_name)

#define _CTX_LOAD_REG_IMPL(reg, reg_name)   movq CTX_REG(reg), %r ## reg_name
#define CTX_LOAD_REG(reg, reg_name)         _CTX_LOAD_REG_IMPL(reg, reg_name)
#define _CTX_LOAD_IMPL(reg_name)            CTX_LOAD_REG(GREG_R ## reg_name, reg_name)
#define CTX_LOAD(reg_name)                  _CTX_LOAD_IMPL(reg_name)

#define _CTX_XMMSTORE_IMPL(n)               vmovdqa %xmm ## n, CTX_XMMREG(n)
#define CTX_XMMSTORE(n)                     _CTX_XMMSTORE_IMPL(n)

#define _CTX_XMMLOAD_IMPL(n)                vmovdqa CTX_XMMREG(n), %xmm ## n
#define CTX_XMMLOAD(n)                      _CTX_XMMLOAD_IMPL(n)

#endif /* TASE_ASM_H */
