mod std.arch.fs;

/// Contains Linux syscall numbers for filesystem operations.
pub mod number {
	/// Linux syscall number for opening a file.
	pub const OPEN: u64 = 2;
	/// Linux syscall number for changing a file offset.
	pub const SEEK: u64 = 8;
	/// Linux syscall number for synchronizing file data and metadata.
	pub const SYNC: u64 = 74;
	/// Linux syscall number for retrieving metadata from an open file.
	pub const FSTAT: u64 = 5;
	/// Linux syscall number for retrieving metadata from a path.
	pub const STAT_PATH: u64 = 262;
	/// Linux syscall number for creating a directory.
	pub const MKDIR: u64 = 83;
	/// Linux syscall number for removing a path relative to a handle.
	pub const UNLINKAT: u64 = 263;
	/// Linux syscall number for renaming a path.
	pub const RENAME: u64 = 82;
	/// Linux syscall number for reading directory entries.
	pub const GETDENTS: u64 = 217;
	/// Linux syscall number for retrieving the current directory.
	pub const GETCWD: u64 = 79;
}

/// Provides raw Linux system call wrappers for filesystem operations.
pub mod syscall {
	const AT_FDCWD: i32 = (0 cast i32) - (100 cast i32);

	/// Opens a path with the requested flags and permissions.
	pub fn open(path: *u8, flags: u32, permissions: u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.fs.number.OPEN),
			"{rdi}" (path), "{rsi}" (flags),
			"{rdx}" (permissions)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Changes a descriptor’s file offset and returns the raw syscall result.
	pub fn seek(handle: isize, offset: i64, whence: u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.fs.number.SEEK),
			"{rdi}" (handle), "{rsi}" (offset),
			"{rdx}" (whence)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Synchronizes a descriptor and returns the raw syscall result.
	pub fn sync(handle: isize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.fs.number.SYNC),
			"{rdi}" (handle)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Writes raw metadata for an open file to the supplied buffer.
	pub fn fstat(handle: isize, buffer: *mut u8) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.fs.number.FSTAT),
			"{rdi}" (handle), "{rsi}" (buffer)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Writes raw metadata for a path to the supplied buffer.
	pub fn stat_path(path: *u8, buffer: *mut u8, flags: u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.fs.number.STAT_PATH),
			"{rdi}" (AT_FDCWD),
			"{rsi}" (path),
			"{rdx}" (buffer), "{r10}" (flags)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Creates a directory and returns the raw syscall result.
	pub fn mkdir(path: *u8, permissions: u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.fs.number.MKDIR),
			"{rdi}" (path), "{rsi}" (permissions)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Removes a path and returns the raw syscall result.
	pub fn unlinkat(path: *u8, flags: u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.fs.number.UNLINKAT),
			"{rdi}" (AT_FDCWD),
			"{rsi}" (path),
			"{rdx}" (flags)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Renames a path and returns the raw syscall result.
	pub fn rename(old_path: *u8, new_path: *u8) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.fs.number.RENAME),
			"{rdi}" (old_path), "{rsi}" (new_path)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Reads directory records into the supplied buffer.
	pub fn getdents(handle: isize, buffer: *mut u8, capacity: usize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.fs.number.GETDENTS),
			"{rdi}" (handle), "{rsi}" (buffer),
			"{rdx}" (capacity)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Writes the current path into the supplied buffer.
	pub fn getcwd(buffer: *mut u8, capacity: usize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.fs.number.GETCWD),
			"{rdi}" (buffer), "{rsi}" (capacity)
			: "rcx", "r11", "memory"
		};
		return result;
	}
}
