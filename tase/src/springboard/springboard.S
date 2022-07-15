#include "tase_asm.h"

.extern target_ctx
.extern tase_eject
.extern exit_tase


/* Define these at the top of this file and hope that they get linked in within
 * 128 bytes or 2^15 bytes of our springboard below to allow for compact
 * load instructions.
 */

DEF_UINT64(tase_ztest0, 0x0001000100010001)
DEF_UINT64(tase_ztest1, 0x8000800080008000)
DEF_UINT64(tase_poison_reference, POISON_REFERENCE64)
/* Must either be sb_disabled, sb_reopen, or sb_reopen */
DEF_UINT64(tran_ctr, 0)
DEF_UINT64(tran_max, 16)	
DEF_UINT64(saved_rax, 0)
DEF_UINT64(tase_springboard, 0)
DEF_UINT64(tase_model, 0)
DEF_UINT64(tase_modeled_return, 0)


.macro sbm_compare_poison
  /* Flush and compare the data register to make control flow transfer easier
   * for the compiler. */
  pcmpeqw    XMM_REFERENCE, XMM_DATA
  por        XMM_DATA, XMM_ACCUMULATOR
  movq      %rax, saved_rax
  lahf	
  ptest      XMM_ACCUMULATOR, XMM_ACCUMULATOR
.endm

.macro sbm_init_tran

  pxor       XMM_DATA, XMM_DATA
  pxor       XMM_ACCUMULATOR, XMM_ACCUMULATOR

  /* Save rax around xbegin. */
  movq       %rax, GPR_TMP
.endm

/* Shim function called at the end of any modeled function.
 * The real return address is in tase_modeled_return,
 */
DEF_FUNC(sb_modeled_return)
  xorl       GPR_RETD, GPR_RETD
  xchgl      tase_modeled_return, GPR_RETD
  movl       $sb_open, tase_springboard
  jmp        *GPR_RET
END_FUNC(sb_modeled_return)

/* Shim function called at the beginning of any modeled function instead of tase_springboard. */
DEF_FUNC(sb_modeled)
#ifdef TASE_TSX
/* TODO: Pass useful flags on why we abort. */
  //xabort     IMM(0xff)
  //sbm_close_tran
  //Moved logic in for batching support
  sbm_compare_poison
  jnz        .Lsb_abort
  xend
  movq  $16, tran_max	
  //movq  $0, tran_ctr
		
  //r15 will point to the head of the cartidge body
  //Fake an xabort IMM(0xff)
  movl IMM(0xff000001) ,%eax
  jmp .Lsb_fallback	
#else
  movl       IMM(0x010000001), %eax

  pxor       XMM_DATA, XMM_DATA
  pxor       XMM_ACCUMULATOR, XMM_ACCUMULATOR

  jmp        .Lsb_fallback
#endif
  END_FUNC(sb_modeled)

/* If we are in the interpreter or we have springboarding
 * explicitly disabled, just go back.  Don't check or do anything.
 */
DEF_FUNC(sb_disabled)
  jmp        *GPR_RET
END_FUNC(sb_disabled)

/*
 * See tase_interp.h for overall contract.
 *
 * The preconditions for sb_reopen:
 * - Assumes that the only way to reach this code is from a cartridge
 *   header that performs a 'jmp' into it.
 * - Requires that GPR_RET contain the cartridge body address to return
 *   from the springboard.
 * - Assumes GPR_TMP is free to use.
 *** For SIMD instrumentation:
 *   - Assumes XMM_DATA contains all accessed memory.
 *   - Assumes XMM_ACCUMULATOR contains high bits in every word that may
 *     contain taint.
 *   - Assumes XMM_REFERENCE contains repeated poison words.
 * The postconditions:
 * - Clears GPR_ACC/XMM_DATA/XMM_ACCUMULATOR on the way out of the springboard.
 * + Tries really hard not to write to memory - we might have a transaction
 *   open on the way in.
 *
 *
 */

DEF_FUNC(sb_reopen)
  sbm_compare_poison
#ifdef TASE_TSX
  jnz        .Lsb_abort

  incq tran_ctr
  movq  tran_max, %r14	
  cmpq  %r14, tran_ctr
  jl    .Lno_close_tran
.Lclose_tran:
  xend
  movq   $16, tran_max	
  movq  $0, tran_ctr
  sahf
  movq        saved_rax , %rax

  sbm_init_tran
  xbegin     .Lsb_fallback
  jmp        *GPR_RET

.Lno_close_tran:
  sahf
  movq        saved_rax , %rax
  jmp        *GPR_RET

#endif
	
	
END_FUNC(sb_reopen)
DEF_FUNC(sb_open)
  sbm_init_tran
  /* About to begin a transaction - track this in tase_springboard. */
  movl       $sb_reopen, tase_springboard
#ifdef TASE_TSX
  xbegin     .Lsb_fallback
#endif
  jmp        *GPR_RET
END_FUNC(sb_open)


DEF_FUNC(sb_eject)
.Lsb_abort:
#ifdef TASE_TSX
/* Pass number of attempted basic blocks in the XABORT */
/* It's OK to clobber flags and registers because the XABORT
will roll us back to an earlier state anyway */
  movq tran_ctr, %rax

  cmpq $0, %rax
  je .LABORT0
  cmpq $1, %rax
  je .LABORT1
  cmpq $2, %rax
  je .LABORT2
  cmpq $3, %rax
  je .LABORT3
  cmpq $4, %rax
  je .LABORT4
  cmpq $5, %rax
  je .LABORT5
  cmpq $6, %rax
  je .LABORT6
  cmpq $7, %rax
  je .LABORT7
  cmpq $8, %rax
  je .LABORT8

	//Fallthrough -- should be unreachable
  xabort IMM(9)

.LABORT0:
  xabort IMM(0)
.LABORT1:
  xabort IMM(1)
.LABORT2:
  xabort IMM(2)
.LABORT3:
  xabort IMM(3)
.LABORT4:	
  xabort IMM(4)
.LABORT5:
  xabort IMM(5)
.LABORT6:
  xabort IMM(6)
.LABORT7:
  xabort IMM(7)
.LABORT8:
  xabort IMM(8)

#else
  /* Deliberately crash */
  movl       0, %eax
#endif
.Lsb_fallback:
  /* TODO: Do that store counting cool stuff to prolong our transactions.
   * But we should always be able to eject. Stash the abort status and restore
   * %rax to its value before xbegin.
   */
  movl       %eax, CTX(CTX_OFFSET_ABORT_STATUS)
  movq       GPR_TMP, %rax

  //Batching: Reset the tran counter
  //movq $0, tran_ctr
/* Transfer control to the interpreting co-routine.
 * We assume we are not in a transaction and none of the target registers
 * (except reserved ones) have been modified.  We expect reserved registers
 * to maintain their invariants.
 */
.Lsb_eject:
  /* Dump that junk in our context... */
  CTX_STORE(ax)
  CTX_STORE(bx)
  CTX_STORE(cx)
  CTX_STORE(dx)
  CTX_STORE(si)
  CTX_STORE(di)
  CTX_STORE(bp)
  CTX_STORE(sp)
  CTX_STORE(8)
  CTX_STORE(9)
  CTX_STORE(10)
  CTX_STORE(11)
  CTX_STORE(12)
  CTX_STORE(13)
  CTX_STORE(14)
  CTX_STORE(15)
  movq $0, %rax
  lahf
  movb %ah, CTX_REG(GREG_EFL)	
  /* The vector junk too... */
  //Let's try to only load and store XMM0. We will see what the
  //minimum number of XMM registers is for abi compatability
  CTX_XMMSTORE(0)

  CTX_XMMSTORE(12)
  CTX_XMMSTORE(13)
  CTX_XMMSTORE(14)
  CTX_XMMSTORE(15)
  
  
  /* Use R13/GPR_RET to compute the cartridge address to begin interpretation.
   * Let's switch stacks, disable transactions and peace out of here.
   * The actual springboard pointer needs to be changed now because otherwise
   * any library calls (even debugging/profiling) will attempt to use
   * transactions.
   */
  movl       $sb_disabled, tase_springboard
  movq       CTX(CTX_OFFSET_INTERP_STACK), %rsp
  jmp        tase_eject
END_FUNC(sb_eject)

/* Do that same dance in reverse now. */
//GPR_RET must point to cartridge body
DEF_FUNC(sb_inject)
//Reset tran ctr
movq $0, tran_ctr	
	
  /* To be paranoid, give ourself an extra 256 bytes for lulz. */
  subq       $256, %rsp
  orq        $8, %rsp
  movq       %rsp, CTX(CTX_OFFSET_INTERP_STACK)	
  CTX_XMMLOAD(0)

  CTX_XMMLOAD(12)
  CTX_XMMLOAD(13)
  CTX_XMMLOAD(14)
  CTX_XMMLOAD(15)

  movq $0, %rax	
  movb CTX_REG(GREG_EFL), %ah
  sahf	
  CTX_LOAD(ax)
  CTX_LOAD(bx)
  CTX_LOAD(cx)
  CTX_LOAD(dx)
  CTX_LOAD(si)
  CTX_LOAD(di)
  CTX_LOAD(bp)
  CTX_LOAD(sp)
  CTX_LOAD(8)
  CTX_LOAD(9)
  CTX_LOAD(10)
  CTX_LOAD(11)
  CTX_LOAD(12)
  CTX_LOAD(13)
  CTX_LOAD(14)
  CTX_LOAD(15)
  /* Do vzeroupper if we need to. */
  //Code for what used to be "sb_open" goes here:
  sbm_init_tran
#ifdef TASE_TSX
  xbegin     .Lsb_fallback
#endif	
  jmpq      *GPR_RET

END_FUNC(sb_inject)


DEF_FUNC(exit_tase_shim)
  /* Re-align the stack on the way into exit_tase */
  call      exit_tase
END_FUNC(exit_tase_shim)


  .section  ".note.GNU-stack","",@progbits
