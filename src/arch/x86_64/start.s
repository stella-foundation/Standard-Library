.global _start
.weak "st$main()"
.weak "st$main(usize,**u8)"
.weak "st$main(usize,*m:*m:u8)"
.text
_start:
	# pop argc off the stack into %rdi
	pop %rdi

	# %rsp now points directly to argv[0], so set %rsi. keep this pointer
	# before aligning the stack: the kernel's initial stack alignment is not
	# the call-site alignment required by the SysV x86-64 ABI.
	mov %rsp, %rsi

	# a function call pushes an 8-byte return address. align %rsp to 16
	# bytes before the call so Stella functions
	and $-16, %rsp

	# a void main has no return value, so start with the success status.
	# a value-returning main may overwrite %eax before returning.
	xor %eax, %eax

	# Prefer argc/argv entry when present. Probe before falling back to a
	# zero-argument function.
	lea "st$main(usize,*m:*m:u8)"(%rip), %rcx
	test %rcx, %rcx
	jnz .Lcall_main

	lea "st$main(usize,**u8)"(%rip), %rcx
	test %rcx, %rcx
	jnz .Lcall_main

	lea "st$main()"(%rip), %rcx

.Lcall_main:
	call *%rcx

	# zero-extend the process status from %al into %edi for exit
	movzbl %al, %edi

	# exit_group syscall (231)
	mov $231, %eax
	syscall
