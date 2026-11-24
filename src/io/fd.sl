mod std.io.fd;
import "./fs.sl";
import "./io.sl";
import "std/arch/fs.sl";
import "std/arch/io.sl";
import "std/err.sl";

/// A borrowed native descriptor. Its owner remains responsible for closing it.
pub struct Descriptor {
	/// Borrowed native handle; its owner remains responsible for closing it.
	pub handle: isize
}

/// Borrows an existing native handle.
pub fn from(handle: isize) -> Descriptor {
	return { .handle = handle };
}

/// Returns a borrowed descriptor for standard input.
pub fn in() -> Descriptor {
	return from(0);
}

/// Returns a borrowed descriptor for standard output.
pub fn out() -> Descriptor {
	return from(1);
}

/// Returns a borrowed descriptor for standard error.
pub fn err() -> Descriptor {
	return from(2);
}

impl Descriptor {
	/// Reports whether this descriptor refers to a character device (terminal/TTY).
	pub fn is_tty(self: *Self) -> bool {
		if self == null || self.handle < 0 {
			return false;
		}
		match std.arch.fs.stat(self.handle) {
			.Ok(info) => return info.kind == std.io.fs.Kind.CharacterDevice,
			.Err(_) => return false
		}
	}
}

impl std.io.Reader for Descriptor {
	/// Reads from a borrowed descriptor and returns the byte count or an error.
	pub fn read(self: *Self, buffer: *mut u8, capacity: usize) -> std.err.Result<usize, std.err.Code> {
		if self == null || self.handle < 0 {
			return .Err(std.err.Code.BadFileDescriptor);
		}
		if capacity > 0 && buffer == null {
			return .Err(std.err.Code.InvalidArgument);
		}
		return std.arch.io.read(self.handle, buffer, capacity);
	}
}

impl std.io.Writer for Descriptor {
	/// Writes to a borrowed descriptor and returns the byte count or an error.
	pub fn write(self: *mut Self, buffer: *u8, length: usize) -> std.err.Result<usize, std.err.Code> {
		if self == null || self.handle < 0 {
			return .Err(std.err.Code.BadFileDescriptor);
		}
		if length > 0 && buffer == null {
			return .Err(std.err.Code.InvalidArgument);
		}
		return std.arch.io.write(self.handle, buffer, length);
	}
}
