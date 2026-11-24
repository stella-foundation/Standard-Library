.global _start
.weak "st$main()"
.weak "st$main(usize,**u8)"
.weak "st$main(usize,*m:*m:u8)"
.text
_start:
	ldr x0, [sp]
	add x1, sp, #8

	mov x2, sp
	and x2, x2, #-16
	mov sp, x2

	adrp x2, "st$main(usize,*m:*m:u8)"
	add x2, x2, :lo12:"st$main(usize,*m:*m:u8)"
	cbnz x2, .Lcall_main

	adrp x2, "st$main(usize,**u8)"
	add x2, x2, :lo12:"st$main(usize,**u8)"
	cbnz x2, .Lcall_main

	adrp x2, "st$main()"
	add x2, x2, :lo12:"st$main()"

.Lcall_main:
	blr x2

	mov x8, #94
	svc #0
