.global _start
.weak "st$main()"
.weak "st$main(usize,**u8)"
.weak "st$main(usize,*m:*m:u8)"
.text
_start:
	ld a0, 0(sp)
	addi a1, sp, 8

	andi sp, sp, -16

	la t0, "st$main(usize,*m:*m:u8)"
	bnez t0, .Lcall_main

	la t0, "st$main(usize,**u8)"
	bnez t0, .Lcall_main

	la t0, "st$main()"

.Lcall_main:
	jalr t0

	li a7, 94
	ecall
