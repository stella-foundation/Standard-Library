mod std.arch.mem;

/// Allocates memory using Linux `mmap`.
pub fn alloc(size: usize) -> *mut u8 {
	let mut result: isize = 0;
	asm volatile {
		"syscall"
		: "=rax" (result)
		: "{rax}" (9), "{rdi}" (0), "{rsi}" (size), "{rdx}" (3),
		"{r10}" (34), "{r8}" (-1), "{r9}" (0)
		: "rcx", "r11", "memory"
	};
	if result < 0 {
		return null;
	}
	return result cast *mut u8;
}

/// Releases memory using Linux `munmap`.
pub fn free(ptr: *u8, size: usize) -> void {
	let mut ret: isize = 0;
	asm volatile {
		"syscall"
		: "=rax" (ret)
		: "{rax}" (11), "{rdi}" (ptr), "{rsi}" (size)
		: "rcx", "r11", "memory"
	};
}
