mod std.arch.mem;

/// Allocates memory using Linux `mmap`.
pub fn alloc(size: usize) -> *mut u8 {
	let mut result: isize = 0;
	asm volatile {
		"ecall"
		: "=a0" (result)
		: "{a7}" (222), "{a0}" (0), "{a1}" (size), "{a2}" (3),
		"{a3}" (34), "{a4}" (-1), "{a5}" (0)
		: "memory"
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
		"ecall"
		: "=a0" (ret)
		: "{a7}" (215), "{a0}" (ptr), "{a1}" (size)
		: "memory"
	};
}
