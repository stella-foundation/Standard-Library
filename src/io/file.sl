mod std.io.file;
import "./fs.sl";
import "std/arch/fs.sl";
import "std/arch/io.sl";
import "std/err.sl";
import "std/io/io.sl";

/// An open file and its owned native handle.
pub struct File {
	/// Native file handle owned by this value; a negative value marks it closed.
	pub handle: isize
}

/// Options controlling file access and creation.
pub enum OpenFlags: u32 {
	Read = 1,
	Write = 2,
	ReadWrite = 3,
	Create = 4,
	Exclusive = 8,
	Truncate = 16,
	Append = 32,
	NoFollow = 64
}

const CLOSED_HANDLE: isize = (0 cast isize) - (1 cast isize);

fn valid_file(file: *File) -> bool {
	return file != null && file.handle >= 0;
}

/// Opens or creates a file according to `flags`.
pub fn open(path: *u8, flags: OpenFlags, permissions: u32) -> std.err.Result<File, std.err.Code> {
	if !std.io.fs.valid_path(path) {
		return .Err(std.err.Code.InvalidArgument);
	}
	let raw: u32 = flags cast u32;
	if (raw & 127) != raw || (raw & 3) == 0 {
		return .Err(std.err.Code.InvalidArgument);
	}
	if ((raw & (OpenFlags.Exclusive cast u32)) != 0
		&& (raw & (OpenFlags.Create cast u32)) == 0) {
		return .Err(std.err.Code.InvalidArgument);
	}
	if ((raw & (OpenFlags.Truncate cast u32)) != 0
		&& (raw & (OpenFlags.Write cast u32)) == 0) {
		return .Err(std.err.Code.InvalidArgument);
	}
	if ((raw & (OpenFlags.Append cast u32)) != 0
		&& (raw & (OpenFlags.Write cast u32)) == 0) {
		return .Err(std.err.Code.InvalidArgument);
	}
	match std.arch.fs.open(path, raw, permissions) {
		.Ok(handle) => return .Ok({ .handle = handle }),
		.Err(e) => return .Err(e),
	}
}

impl std.io.Reader for File {
	/// Reads up to `capacity` bytes and returns the byte count or an error.
	pub fn read(self: *Self, buffer: *mut u8, capacity: usize) -> std.err.Result<usize, std.err.Code> {
		if !valid_file(self) {
			return .Err(std.err.Code.BadFileDescriptor);
		}
		if capacity > 0 && buffer == null {
			return .Err(std.err.Code.InvalidArgument);
		}
		if capacity == 0 {
			return .Ok(0);
		}
		match std.arch.io.read(self.handle, buffer, capacity) {
			.Ok(count) => {
				if count > capacity {
					return .Err(std.err.Code.InputOutputError);
				}
				return .Ok(count);
			}
			.Err(e) => return .Err(e),
		}
	}
}

impl std.io.Writer for File {
	/// Writes up to `length` bytes and returns the byte count or an error.
	pub fn write(self: *mut Self, buffer: *u8, length: usize) -> std.err.Result<usize, std.err.Code> {
		if !valid_file(self) {
			return .Err(std.err.Code.BadFileDescriptor);
		}
		if length > 0 && buffer == null {
			return .Err(std.err.Code.InvalidArgument);
		}
		if length == 0 {
			return .Ok(0);
		}
		match std.arch.io.write(self.handle, buffer, length) {
			.Ok(count) => {
				if count > length {
					return .Err(std.err.Code.InputOutputError);
				}
				return .Ok(count);
			}
			.Err(e) => return .Err(e),
		}
	}
}

impl std.io.Seeker for File {
	/// Moves the file position and returns the resulting position or an error.
	pub fn seek(
		self: *Self,
		offset: i64,
		whence: std.io.SeekWhence
	) -> std.err.Result<u64, std.err.Code> {
		if !valid_file(self) {
			return .Err(std.err.Code.BadFileDescriptor);
		}
		if whence cast u8 > std.io.SeekWhence.End cast u8 {
			return .Err(std.err.Code.InvalidArgument);
		}
		return std.arch.fs.seek(self.handle, offset, whence cast u8);
	}
}

impl std.io.Sync for File {
	/// Flushes pending file data to the underlying filesystem.
	pub fn sync(self: *Self) -> std.err.Code {
		if !valid_file(self) {
			return std.err.Code.BadFileDescriptor;
		}
		return std.arch.fs.sync(self.handle);
	}
}

impl std.io.Closer for File {
	/// Closes an open file.
	pub fn close(self: *mut Self) -> std.err.Code {
		if !valid_file(self) {
			return std.err.Code.BadFileDescriptor;
		}
		let code: std.err.Code = std.arch.io.close(self.handle);
		if code == std.err.Code.Success || code == std.err.Code.InterruptedSystemCall {
			self.handle = CLOSED_HANDLE;
		}
		return code;
	}
}

/// Retrieves metadata for an open file.
pub fn stat(file: *File) -> std.err.Result<std.io.fs.Info, std.err.Code> {
	if !valid_file(file) {
		return .Err(std.err.Code.BadFileDescriptor);
	}
	return std.arch.fs.stat(file.handle);
}
