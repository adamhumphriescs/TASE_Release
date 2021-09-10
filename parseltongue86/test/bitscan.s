.global test_bsr
.global test_bsf	
.text
test_bsr:
	mov $-1,%rcx
	bsr %rdi,%rax
	cmoveq %rcx,%rax
	xor %rcx,%rcx
	ret
test_bsf:
	mov $-1,%rcx
	bsf %rdi,%rax
	cmoveq %rcx,%rax
	xor %rcx,%rcx
	ret
