mod std.arch.io;
import "./code.sl";
import "std/err.sl";

/// Maps a Linux syscall result to the portable error code type.
pub fn portable_error(result: isize) -> std.err.Code {
	if result >= 0 {
		return std.err.Code.Success;
	}
	let native: isize = -result;
	if native > 255 {
		return std.err.Code.Unknown;
	}
	return std.arch.err.to_portable_code((native cast u8) cast std.arch.err.Code);
}

/// Reports whether a Linux syscall result indicates interruption.
pub fn was_interrupted(result: isize) -> bool {
	return result == -(4 cast isize);
}

/// Closes a Linux descriptor.
pub fn close(handle: isize) -> std.err.Code {
	let result: isize = std.arch.io.syscall.close(handle);
	// Linux releases the descriptor even when close(2) reports EINTR.
	if was_interrupted(result) {
		return std.err.Code.Success;
	}
	return portable_error(result);
}

/// Reads bytes from a Linux descriptor.
pub fn read(handle: isize, buffer: *mut u8, capacity: usize) -> std.err.Result<usize, std.err.Code> {
	let mut result: isize = std.arch.io.syscall.read(handle, buffer, capacity);
	for was_interrupted(result) {
		result = std.arch.io.syscall.read(handle, buffer, capacity);
	}
	if result >= 0 {
		return .Ok(result cast usize);
	}
	return .Err(portable_error(result));
}

/// Writes bytes to a Linux descriptor.
pub fn write(handle: isize, buffer: *u8, length: usize) -> std.err.Result<usize, std.err.Code> {
	let mut result: isize = std.arch.io.syscall.write(handle, buffer, length);
	for was_interrupted(result) {
		result = std.arch.io.syscall.write(handle, buffer, length);
	}
	if result >= 0 {
		return .Ok(result cast usize);
	}
	return .Err(portable_error(result));
}

/// Contains Linux syscall numbers for file descriptor operations.
pub mod number {
	/// Linux syscall number for closing a file descriptor.
	pub const CLOSE: u64 = 57;
	/// Linux syscall number for reading from a file descriptor.
	pub const READ: u64 = 63;
	/// Linux syscall number for writing to a file descriptor.
	pub const WRITE: u64 = 64;
}

/// Provides raw Linux system call wrappers for file descriptors.
pub mod syscall {
	/// Closes a descriptor and returns the raw syscall result.
	pub fn close(handle: isize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.io.number.CLOSE),
			"{a0}" (handle)
			: "memory"
		};
		return result;
	}

	/// Reads up to the requested capacity and returns the byte count or error.
	pub fn read(handle: isize, buffer: *mut u8, capacity: usize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.io.number.READ),
			"{a0}" (handle), "{a1}" (buffer),
			"{a2}" (capacity)
			: "memory"
		};
		return result;
	}

	/// Writes up to the requested length and returns the byte count or error.
	pub fn write(handle: isize, buffer: *u8, length: usize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"ecall"
			: "=a0" (result)
			: "{a7}" (std.arch.io.number.WRITE),
			"{a0}" (handle), "{a1}" (buffer),
			"{a2}" (length)
			: "memory"
		};
		return result;
	}
}
