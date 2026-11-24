mod std.arch.mem;

/// Allocates memory using Linux `mmap`.
pub fn alloc(size: usize) -> *mut u8 {
	let mut result: isize = 0;
	asm volatile {
		"svc #0"
		: "=x0" (result)
		: "{w8}" (222), "{x0}" (0), "{x1}" (size), "{x2}" (3),
		"{x3}" (34), "{x4}" (-1), "{x5}" (0)
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
		"svc #0"
		: "=x0" (ret)
		: "{w8}" (215), "{x0}" (ptr), "{x1}" (size)
		: "memory"
	};
}
