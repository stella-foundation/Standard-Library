mod std.io.path;
import "std/arch/fs.sl";
import "std/err.sl";
import "std/str/basic.sl";

fn separator() -> u8 {
	return std.arch.fs.path_separator();
}

fn copy_bytes(output: *mut u8, source: *u8, start: usize, length: usize, at: usize) -> void {
	for let mut i: usize = 0; i < length; i += 1 {
		output[at + i] = source[start + i];
	}
}

/// Joins two NUL-terminated paths and reports the required output length.
pub fn join(
	left: *u8,
	right: *u8,
	output: *mut u8,
	capacity: usize,
	length_out: *mut usize
) -> std.err.Code {
	if left == null || right == null || length_out == null {
		return std.err.Code.InvalidArgument;
	}
	let left_length: usize = std.str.c_len(left);
	let right_length: usize = std.str.c_len(right);
	let max_length: usize = (0 cast usize) - 1;
	if left_length > max_length - right_length {
		return std.err.Code.FileNameTooLong;
	}
	let mut needs_separator: bool = left_length > 0 && right_length > 0;
	let mut right_start: usize = 0;
	if needs_separator && left[left_length - 1] == separator() {
		needs_separator = false;
	}
	if needs_separator && right[0] == separator() {
		needs_separator = false;
	}
	if left_length > 0 && right_length > 0
		&& left[left_length - 1] == separator() && right[0] == separator() {
		right_start = 1;
	}
	let mut length: usize = left_length + right_length;
	length -= right_start;
	if needs_separator {
		if length == max_length {
			return std.err.Code.FileNameTooLong;
		}
		length += 1;
	}
	length_out[0] = length;
	if length == max_length || capacity < length + 1 || output == null {
		return std.err.Code.BufferTooSmall;
	}
	let mut at: usize = 0;
	copy_bytes(output, left, 0, left_length, at);
	at += left_length;
	if needs_separator {
		output[at] = separator();
		at += 1;
	}
	copy_bytes(output, right, right_start, right_length - right_start, at);
	output[length] = 0;
	return std.err.Code.Success;
}

/// Normalizes separators and dot components in a path.
pub fn normalize(path: *u8, output: *mut u8, capacity: usize, length_out: *mut usize) -> std.err.Code {
	if path == null || length_out == null {
		return std.err.Code.InvalidArgument;
	}
	let path_length: usize = std.str.c_len(path);
	let max_length: usize = (0 cast usize) - 1;
	let root: bool = path_length > 0 && path[0] == separator();
	let mut stack: [4096]usize;
	let mut stack_kind: [4096]u8;
	let mut stack_count: usize = 0;
	let mut normalized_length: usize = 0;
	if root {
		normalized_length = 1;
	}
	let mut i: usize = 0;
	for i < path_length {
		for i < path_length && path[i] == separator(); i += 1 {
		}
		if i >= path_length {
			break;
		}
		let start: usize = i;
		for i < path_length && path[i] != separator(); i += 1 {
		}
		let component_length: usize = i - start;
		let is_dot: bool = component_length == 1 && path[start] == '.';
		let is_dot_dot: bool = component_length == 2
			&& path[start] == '.' && path[start + 1] == '.';
		if is_dot {
			continue;
		}
		if is_dot_dot {
			if stack_count > 0 && stack_kind[stack_count - 1] == 1 {
				stack_count -= 1;
				normalized_length = stack[stack_count];
			} else if !root {
				if stack_count >= 4096 {
					return std.err.Code.FileNameTooLong;
				}
				stack[stack_count] = normalized_length;
				stack_kind[stack_count] = 0;
				stack_count += 1;
				if normalized_length > 0 {
					if normalized_length == max_length {
						return std.err.Code.FileNameTooLong;
					}
					normalized_length += 1;
				}
				if normalized_length > max_length - 2 {
					return std.err.Code.FileNameTooLong;
				}
				normalized_length += 2;
			}
			continue;
		}
		if stack_count >= 4096 {
			return std.err.Code.FileNameTooLong;
		}
		stack[stack_count] = normalized_length;
		stack_kind[stack_count] = 1;
		stack_count += 1;
		if normalized_length > 0 && !(root && normalized_length == 1) {
			if normalized_length == max_length {
				return std.err.Code.FileNameTooLong;
			}
			normalized_length += 1;
		}
		if component_length > max_length - normalized_length {
			return std.err.Code.FileNameTooLong;
		}
		normalized_length += component_length;
	}
	if normalized_length == 0 {
		normalized_length = 1;
	}
	length_out[0] = normalized_length;
	if normalized_length == max_length || output == null || capacity < normalized_length + 1 {
		return std.err.Code.BufferTooSmall;
	}

	// re-run the lexical walk, this time writing components into the caller's
	// buffer. the first pass above guarantees that this pass cannot overflow
	let mut at: usize = 0;
	if root {
		output[0] = separator();
		at = 1;
	}
	stack_count = 0;
	i = 0;
	for i < path_length {
		for i < path_length && path[i] == separator(); i += 1 {
		}
		if i >= path_length {
			break;
		}
		let start2: usize = i;
		for i < path_length && path[i] != separator(); i += 1 {
			// ...
		}
		let component_length2: usize = i - start2;
		let is_dot2: bool = component_length2 == 1 && path[start2] == '.';
		let is_dot_dot2: bool = component_length2 == 2
			&& path[start2] == '.' && path[start2 + 1] == '.';
		if is_dot2 {
			continue;
		}
		if is_dot_dot2 {
			if stack_count > 0 && stack_kind[stack_count - 1] == 1 {
				stack_count -= 1;
				at = stack[stack_count];
			} else if !root {
				stack[stack_count] = at;
				stack_kind[stack_count] = 0;
				stack_count += 1;
				if at > 0 {
					output[at] = separator();
					at += 1;
				}
				copy_bytes(output, path, start2, component_length2, at);
				at += component_length2;
			}
			continue;
		}
		stack[stack_count] = at;
		stack_kind[stack_count] = 1;
		stack_count += 1;
		if at > 0 && !(root && at == 1) {
			output[at] = separator();
			at += 1;
		}
		copy_bytes(output, path, start2, component_length2, at);
		at += component_length2;
	}
	if at == 0 {
		output[0] = '.';
		at = 1;
	}
	output[at] = 0;
	return std.err.Code.Success;
}

/// Reports whether a path begins at the filesystem root.
pub fn is_absolute(path: *u8) -> bool {
	return path != null && path[0] == separator();
}

/// Writes the current directory and reports its length.
pub fn current_directory(output: *mut u8, capacity: usize, length_out: *mut usize) -> std.err.Code {
	if length_out == null || (capacity > 0 && output == null) {
		return std.err.Code.InvalidArgument;
	}
	return std.arch.fs.current_directory(output, capacity, length_out);
}
