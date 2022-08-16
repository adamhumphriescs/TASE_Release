#include "tase_asm.h"

.extern target_ctx
.extern tase_eject
.extern exit_tase

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


DEF_FUNC(sb_modeled_return)
  xorl       GPR_RETD, GPR_RETD
  xchgl      tase_modeled_return, GPR_RETD
  movl       $sb_open, tase_springboard
  jmp        *GPR_RET
END_FUNC(sb_modeled_return)

DEF_FUNC(sb_modeled)
  movl IMM(0x010000001), %eax
  jmp .Lsb_fallback
END_FUNC(sb_modeled)

DEF_FUNC(sb_disabled)
  jmp *GPR_RET
END_FUNC(sb_disabled)
	

DEF_FUNC(sb_open)
  movl $sb_reopen, tase_springboard
  jmp *GPR_RET	
END_FUNC(sb_open)

DEF_FUNC(sb_reopen)
  jmp *GPR_RET
END_FUNC(sb_reopen)	

	

DEF_FUNC(sb_eject)
.Lsb_fallback:
  movl       %eax, CTX(CTX_OFFSET_ABORT_STATUS)
  movq       GPR_TMP, %rax
.Lsb_eject:
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
	
  movl       $sb_disabled, tase_springboard
  movq       CTX(CTX_OFFSET_INTERP_STACK), %rsp
  jmp        tase_eject	
END_FUNC(sb_eject)


DEF_FUNC(sb_inject)
  movq $0, tran_ctr

  /* To be paranoid, give ourself an extra 256 bytes for lulz. */
  subq       $256, %rsp
  orq        $8, %rsp
  movq       %rsp, CTX(CTX_OFFSET_INTERP_STACK)
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
  jmpq *GPR_RET
END_FUNC(sb_inject)


DEF_FUNC(exit_tase_shim)
  call exit_tase
END_FUNC(exit_tase_shim)

  .section ".note.GNU-stack","",@progbits	
