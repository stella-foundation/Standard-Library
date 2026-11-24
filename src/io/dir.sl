mod std.io.dir;
import "./fs.sl";
import "std/arch/fs.sl";
import "std/arch/io.sl";
import "std/err.sl";
import "std/io/io.sl";

/// An open directory and its owned native handle.
pub struct Directory {
	/// Native directory handle owned by this value; a negative value marks it closed.
	pub handle: isize
}

/// A directory entry returned by `next`.
pub struct Entry {
	/// Kind of the directory entry returned by `next`.
	pub kind: std.io.fs.Kind,
	/// Length excluding NUL on success, or required capacity including NUL on retry.
	pub name_length: usize
}

const CLOSED_HANDLE: isize = (0 cast isize) - (1 cast isize);

fn valid_directory(directory: *Directory) -> bool {
	return directory != null && directory.handle >= 0;
}

/// Opens a directory at `path` and returns its handle or an error.
pub fn open(path: *u8) -> std.err.Result<Directory, std.err.Code> {
	if !std.io.fs.valid_path(path) {
		return .Err(std.err.Code.InvalidArgument);
	}
	match std.arch.fs.open_directory(path) {
		.Ok(handle) => return .Ok({ .handle = handle }),
		.Err(e) => return .Err(e),
	}
}

/// Reads the next directory entry into the caller-provided buffers.
pub fn next(
	directory: *Directory,
	name_buffer: *mut u8,
	name_capacity: usize,
	entry_out: *mut Entry
) -> std.err.Code {
	if !valid_directory(directory) {
		return std.err.Code.BadFileDescriptor;
	}
	if entry_out == null || (name_capacity > 0 && name_buffer == null) {
		return std.err.Code.InvalidArgument;
	}
	return std.arch.fs.next_directory(
		directory.handle,
		name_buffer,
		name_capacity,
		&entry_out.kind,
		&entry_out.name_length
	);
}

impl std.io.Closer for Directory {
	/// Closes an open directory.
	pub fn close(self: *mut Self) -> std.err.Code {
		if !valid_directory(self) {
			return std.err.Code.BadFileDescriptor;
		}
		let code: std.err.Code = std.arch.io.close(self.handle);
		if code == std.err.Code.Success || code == std.err.Code.InterruptedSystemCall {
			self.handle = CLOSED_HANDLE;
		}
		return code;
	}
}

/// Creates a directory with the requested permissions.
pub fn create(path: *u8, permissions: u32) -> std.err.Code {
	if !std.io.fs.valid_path(path) {
		return std.err.Code.InvalidArgument;
	}
	return std.arch.fs.create_directory(path, permissions);
}

/// Removes a file or directory at `path`.
pub fn remove(path: *u8) -> std.err.Code {
	if !std.io.fs.valid_path(path) {
		return std.err.Code.InvalidArgument;
	}
	return std.arch.fs.remove(path);
}

/// Retrieves metadata for a path, optionally following symbolic links.
pub fn stat(path: *u8, follow_links: bool) -> std.err.Result<std.io.fs.Info, std.err.Code> {
	if !std.io.fs.valid_path(path) {
		return .Err(std.err.Code.InvalidArgument);
	}
	return std.arch.fs.stat_path(path, follow_links);
}

/// Renames a filesystem entry.
pub fn rename(old_path: *u8, new_path: *u8) -> std.err.Code {
	if !std.io.fs.valid_path(old_path) || !std.io.fs.valid_path(new_path) {
		return std.err.Code.InvalidArgument;
	}
	return std.arch.fs.rename(old_path, new_path);
}
