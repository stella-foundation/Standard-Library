mod std.arch.fs;
import "./io.sl";
import "std/err.sl";
pub import "./fs/syscall.sl";
pub import "./fs/types.sl";
import "std/io/fs.sl";

/// Opens a filesystem object using Linux syscalls.
pub fn open(path: *u8, flags: u32, permissions: u32) -> std.err.Result<isize, std.err.Code> {
	let mut native_flags: u32 = 0;
	let access: u32 = flags & std.arch.fs.file.ACCESS_MASK;
	if access == std.arch.fs.file.WRITE {
		native_flags = std.arch.fs.native.WRITE_ONLY;
	}
	if access == std.arch.fs.file.READ_WRITE {
		native_flags = std.arch.fs.native.READ_WRITE;
	}
	if (flags & std.arch.fs.file.CREATE) != 0 {
		native_flags |= std.arch.fs.native.CREATE;
	}
	if (flags & std.arch.fs.file.EXCLUSIVE) != 0 {
		native_flags |= std.arch.fs.native.EXCLUSIVE;
	}
	if (flags & std.arch.fs.file.TRUNCATE) != 0 {
		native_flags |= std.arch.fs.native.TRUNCATE;
	}
	if (flags & std.arch.fs.file.APPEND) != 0 {
		native_flags |= std.arch.fs.native.APPEND;
	}
	if (flags & std.arch.fs.file.NO_FOLLOW) != 0 {
		native_flags |= std.arch.fs.native.NO_FOLLOW;
	}
	let mut result: isize = std.arch.fs.syscall.open(path, native_flags, permissions);
	for std.arch.io.was_interrupted(result) {
		result = std.arch.fs.syscall.open(path, native_flags, permissions);
	}
	let code: std.err.Code = std.arch.io.portable_error(result);
	if code == std.err.Code.Success {
		return .Ok(result);
	}
	return .Err(code);
}

/// Opens a directory using Linux syscalls.
pub fn open_directory(path: *u8) -> std.err.Result<isize, std.err.Code> {
	let mut result: isize = std.arch.fs.syscall.open(
		path,
		std.arch.fs.native.DIRECTORY,
		std.arch.fs.native.READ_ONLY
	);
	for std.arch.io.was_interrupted(result) {
		result = std.arch.fs.syscall.open(
			path,
			std.arch.fs.native.DIRECTORY,
			std.arch.fs.native.READ_ONLY
		);
	}
	let code: std.err.Code = std.arch.io.portable_error(result);
	if code == std.err.Code.Success {
		return .Ok(result);
	}
	return .Err(code);
}

/// Moves the position of a Linux filesystem handle.
pub fn seek(handle: isize, offset: i64, whence: u8) -> std.err.Result<u64, std.err.Code> {
	let mut result: isize = std.arch.fs.syscall.seek(handle, offset, whence cast u32);
	for std.arch.io.was_interrupted(result) {
		result = std.arch.fs.syscall.seek(handle, offset, whence cast u32);
	}
	if result >= 0 {
		return .Ok(result cast u64);
	}
	return .Err(std.arch.io.portable_error(result));
}

/// Flushes a Linux filesystem handle.
pub fn sync(handle: isize) -> std.err.Code {
	let mut result: isize = std.arch.fs.syscall.sync(handle);
	for std.arch.io.was_interrupted(result) {
		result = std.arch.fs.syscall.sync(handle);
	}
	return std.arch.io.portable_error(result);
}

/// Retrieves metadata for a Linux filesystem handle.
pub fn stat(handle: isize) -> std.err.Result<std.io.fs.Info, std.err.Code> {
	let mut raw: [144]u8;
	let mut result: isize = std.arch.fs.syscall.fstat(handle, &raw[0]);
	for std.arch.io.was_interrupted(result) {
		result = std.arch.fs.syscall.fstat(handle, &raw[0]);
	}
	let code: std.err.Code = std.arch.io.portable_error(result);
	if code == std.err.Code.Success {
		let mut info: std.io.fs.Info;
		fill_info(&raw[0], &info);
		return .Ok(info);
	}
	return .Err(code);
}

/// Retrieves metadata for a Linux path.
pub fn stat_path(path: *u8, follow_links: bool) -> std.err.Result<std.io.fs.Info, std.err.Code> {
	let mut flags: u32 = 0;
	if !follow_links {
		flags = std.arch.fs.path.SYMLINK_NO_FOLLOW;
	}
	let mut raw: [144]u8;
	let mut result: isize = std.arch.fs.syscall.stat_path(path, &raw[0], flags);
	for std.arch.io.was_interrupted(result) {
		result = std.arch.fs.syscall.stat_path(path, &raw[0], flags);
	}
	let code: std.err.Code = std.arch.io.portable_error(result);
	if code == std.err.Code.Success {
		let mut info: std.io.fs.Info;
		fill_info(&raw[0], &info);
		return .Ok(info);
	}
	return .Err(code);
}

/// Creates a directory using Linux syscalls.
pub fn create_directory(path: *u8, permissions: u32) -> std.err.Code {
	let mut result: isize = std.arch.fs.syscall.mkdir(path, permissions);
	for std.arch.io.was_interrupted(result) {
		result = std.arch.fs.syscall.mkdir(path, permissions);
	}
	return std.arch.io.portable_error(result);
}

/// Removes a filesystem object using Linux syscalls.
pub fn remove(path: *u8) -> std.err.Code {
	let mut result: isize = std.arch.fs.syscall.unlinkat(path, 0);
	for std.arch.io.was_interrupted(result) {
		result = std.arch.fs.syscall.unlinkat(path, 0);
	}
	if result == std.arch.fs.unlink.IS_DIRECTORY {
		result = std.arch.fs.syscall.unlinkat(path, std.arch.fs.unlink.DIRECTORY);
		for std.arch.io.was_interrupted(result) {
			result = std.arch.fs.syscall.unlinkat(path, std.arch.fs.unlink.DIRECTORY);
		}
	}
	return std.arch.io.portable_error(result);
}

/// Renames a filesystem object using Linux syscalls.
pub fn rename(old_path: *u8, new_path: *u8) -> std.err.Code {
	let mut result: isize = std.arch.fs.syscall.rename(old_path, new_path);
	for std.arch.io.was_interrupted(result) {
		result = std.arch.fs.syscall.rename(old_path, new_path);
	}
	return std.arch.io.portable_error(result);
}

/// Reads the next directory entry from a Linux handle.
pub fn next_directory(
	handle: isize,
	name_buffer: *mut u8,
	name_capacity: usize,
	kind_out: *mut std.io.fs.Kind,
	name_length_out: *mut usize
) -> std.err.Code {
	let mut old_position: isize = std.arch.fs.syscall.seek(
		handle,
		0,
		std.arch.fs.seek_constants.CURRENT
	);
	for std.arch.io.was_interrupted(old_position) {
		old_position = std.arch.fs.syscall.seek(handle, 0, std.arch.fs.seek_constants.CURRENT);
	}
	if old_position < 0 {
		return std.arch.io.portable_error(old_position);
	}
	let mut raw: [280]u8;
	let mut result: isize = std.arch.fs.syscall.getdents(
		handle,
		&raw[0],
		std.arch.fs.directory.BUFFER_SIZE
	);
	for std.arch.io.was_interrupted(result) {
		result = std.arch.fs.syscall.getdents(handle, &raw[0], std.arch.fs.directory.BUFFER_SIZE);
	}
	if result < 0 {
		return std.arch.io.portable_error(result);
	}
	if result == 0 {
		name_length_out[0] = 0;
		kind_out[0] = std.io.fs.Kind.Unknown;
		if name_capacity > 0 {
			name_buffer[0] = 0;
		}
		return std.err.Code.Success;
	}
	let bytes: usize = result cast usize;
	let record_length: usize = read_integer<u16>(
		&raw[0],
		std.arch.fs.directory.RECORD_LENGTH
	) cast usize;
	if record_length < std.arch.fs.directory.MINIMUM_LENGTH
		|| record_length > bytes {
		return std.err.Code.InputOutputError;
	}
	let mut name_length: usize = 0;
	for std.arch.fs.directory.NAME + name_length < record_length
		&& raw[std.arch.fs.directory.NAME + name_length] != 0; name_length += 1 {
	}
	if std.arch.fs.directory.NAME + name_length >= record_length {
		return std.err.Code.InputOutputError;
	}
	let required: usize = name_length + 1;
	if name_capacity < required || name_buffer == null {
		let mut restored: isize = std.arch.fs.syscall.seek(
			handle,
			old_position cast i64,
			std.arch.fs.seek_constants.SET
		);
		for std.arch.io.was_interrupted(restored) {
			restored = std.arch.fs.syscall.seek(
				handle,
				old_position cast i64,
				std.arch.fs.seek_constants.SET
			);
		}
		name_length_out[0] = required;
		if restored < 0 {
			return std.arch.io.portable_error(restored);
		}
		return std.err.Code.BufferTooSmall;
	}
	for let mut i: usize = 0; i < name_length; i += 1 {
		name_buffer[i] = raw[std.arch.fs.directory.NAME + i];
	}
	name_buffer[name_length] = 0;
	kind_out[0] = std.arch.fs.kind.kind_from_directory_type(raw[std.arch.fs.directory.TYPE]);
	name_length_out[0] = name_length;
	let next_position: i64 = read_integer<u64>(&raw[0], std.arch.fs.directory.FILE) cast i64;
	let mut restored: isize = std.arch.fs.syscall.seek(
		handle,
		next_position,
		std.arch.fs.seek_constants.SET
	);
	for std.arch.io.was_interrupted(restored) {
		restored = std.arch.fs.syscall.seek(handle, next_position, std.arch.fs.seek_constants.SET);
	}
	if restored < 0 {
		return std.arch.io.portable_error(restored);
	}
	return std.err.Code.Success;
}

/// Writes the Linux process's current directory.
pub fn current_directory(output: *mut u8, capacity: usize, length_out: *mut usize) -> std.err.Code {
	let mut raw: [4096]u8;
	let mut result: isize = std.arch.fs.syscall.getcwd(&raw[0], std.arch.fs.path.CURRENT_DIRECTORY);
	for std.arch.io.was_interrupted(result) {
		result = std.arch.fs.syscall.getcwd(&raw[0], std.arch.fs.path.CURRENT_DIRECTORY);
	}
	if result < 0 {
		let code: std.err.Code = std.arch.io.portable_error(result);
		if code == std.err.Code.NumericalResultOutOfRange {
			return std.err.Code.FileNameTooLong;
		}
		return code;
	}
	let mut length: usize = result cast usize;
	if length > 0 {
		length -= 1;
	}
	length_out[0] = length;
	if output == null || capacity < length + 1 {
		return std.err.Code.BufferTooSmall;
	}
	for let mut i: usize = 0; i <= length; i += 1 {
		output[i] = raw[i];
	}
	return std.err.Code.Success;
}

/// Returns Linux's path separator byte.
pub fn path_separator() -> u8 {
	return '/';
}
