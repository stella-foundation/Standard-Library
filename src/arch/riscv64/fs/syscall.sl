mod std.arch.fs;

/// Contains Linux syscall numbers for filesystem operations.
pub mod number {
	/// Linux syscall number for opening a path relative to a directory.
	pub const OPENAT: u64 = 56;
	/// Linux syscall number for changing a file offset.
	pub const LSEEK: u64 = 62;
	/// Linux syscall number for synchronizing file data and metadata.
	pub const FSYNC: u64 = 82;
	/// Linux syscall number for retrieving metadata from an open file.
	pub const FSTAT: u64 = 80;
	/// Linux syscall number for retrieving metadata from a path.
	pub const NEWFSTATAT: u64 = 79;
	/// Linux syscall number for creating a directory relative to a handle.
	pub const MKDIRAT: u64 = 34;
	/// Linux syscall number for removing a path relative to a handle.
	pub const UNLINKAT: u64 = 35;
	/// Linux syscall number for renaming a path relative to directory handles.
	pub const RENAMEAT2: u64 = 276;
	/// Linux syscall number for reading directory entries.
	pub const GETDENTS64: u64 = 61;
	/// Linux syscall number for retrieving the current directory.
	pub const GETCWD: u64 = 17;
}

/// Provides raw Linux system call wrappers for filesystem operations.
pub mod syscall {
	const AT_FDCWD: i32 = (0 cast i32) - (100 cast i32);

	/// Opens a path with the requested flags and permissions.
	pub fn open(path: *u8, flags: u32, permissions: u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.fs.number.OPENAT),
			"{a0}" (AT_FDCWD cast isize), "{a1}" (path),
			"{a2}" (flags cast usize),
			"{a3}" (permissions cast usize)
			: "memory"
		};
		return result;
	}

	/// Changes a descriptor’s file offset and returns the raw syscall result.
	pub fn seek(handle: isize, offset: i64, whence: u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.fs.number.LSEEK),
			"{a0}" (handle), "{a1}" (offset),
			"{a2}" (whence cast usize)
			: "memory"
		};
		return result;
	}

	/// Synchronizes a descriptor and returns the raw syscall result.
	pub fn sync(handle: isize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.fs.number.FSYNC),
			"{a0}" (handle)
			: "memory"
		};
		return result;
	}

	/// Writes raw metadata for an open file to the supplied buffer.
	pub fn fstat(handle: isize, buffer: *mut u8) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.fs.number.FSTAT),
			"{a0}" (handle), "{a1}" (buffer)
			: "memory"
		};
		return result;
	}

	/// Writes raw metadata for a path to the supplied buffer.
	pub fn stat_path(path: *u8, buffer: *mut u8, flags: u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.fs.number.NEWFSTATAT),
			"{a0}" (AT_FDCWD cast isize),
			"{a1}" (path),
			"{a2}" (buffer), "{a3}" (flags cast usize)
			: "memory"
		};
		return result;
	}

	/// Creates a directory and returns the raw syscall result.
	pub fn mkdir(path: *u8, permissions: u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.fs.number.MKDIRAT),
			"{a0}" (AT_FDCWD cast isize), "{a1}" (path),
			"{a2}" (permissions cast usize)
			: "memory"
		};
		return result;
	}

	/// Removes a path and returns the raw syscall result.
	pub fn unlinkat(path: *u8, flags: u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.fs.number.UNLINKAT),
			"{a0}" (AT_FDCWD cast isize),
			"{a1}" (path),
			"{a2}" (flags cast usize)
			: "memory"
		};
		return result;
	}

	/// Renames a path and returns the raw syscall result.
	pub fn rename(old_path: *u8, new_path: *u8) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.fs.number.RENAMEAT2),
			"{a0}" (AT_FDCWD cast isize), "{a1}" (old_path),
			"{a2}" (AT_FDCWD cast isize), "{a3}" (new_path),
			"{a4}" (0)
			: "memory"
		};
		return result;
	}

	/// Reads directory records into the supplied buffer.
	pub fn getdents(handle: isize, buffer: *mut u8, capacity: usize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.fs.number.GETDENTS64),
			"{a0}" (handle), "{a1}" (buffer),
			"{a2}" (capacity)
			: "memory"
		};
		return result;
	}

	/// Writes the current path into the supplied buffer.
	pub fn getcwd(buffer: *mut u8, capacity: usize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.fs.number.GETCWD),
			"{a0}" (buffer), "{a1}" (capacity)
			: "memory"
		};
		return result;
	}
}
