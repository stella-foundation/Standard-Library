mod std.proc;
import "std/arch/proc.sl";
import "std/env.sl";
import "std/err.sl";
import "std/io/dir.sl";
import "std/io/fs.sl";
import "std/mem.sl";

/// Terminates the process with the supplied exit code.
pub fn exit(code: u8) -> void {
	std.arch.proc.exit(code);
}

/// Abnormally terminates the process.
#[!return]
pub fn abort() -> void {
	std.arch.proc.abort();
}

/// Executes `program` with `argv` (NULL-terminated) and returns its exit status.
pub fn exec(program: *u8, argv: **u8) -> isize {
	return std.arch.proc.exec(program, argv);
}

/// Executes `program` (searching `PATH` if `program` contains no `/`) with `argv`.
pub fn exec_in_path(program: []u8, argv: **u8) -> isize {
	if program.len == 0 {
		return -(std.err.Code.InvalidArgument cast isize);
	}
	let mut has_slash: bool = false;
	for let mut i: usize = 0; i < program.len; i += 1 {
		if program[i] == ('/' cast u8) {
			has_slash = true;
			break;
		}
	}
	if has_slash {
		let mut cbuf: [4096]u8;
		if program.len >= 4096 {
			return -(std.err.Code.FileNameTooLong cast isize);
		}
		std.mem.copy(&cbuf[0], program.ptr, program.len);
		cbuf[program.len] = 0;
		return exec(&cbuf[0], argv);
	}
	let mut path_buf: [4096]u8;
	let mut path_val: []u8 = "";
	match std.env.get("PATH", path_buf[0..4096]) {
		.Some(v) => path_val = v,
		.None => return -(std.err.Code.NoSuchFileOrDirectory cast isize)
	}
	let mut cand: [4096]u8;
	let mut start: usize = 0;
	for start <= path_val.len {
		let mut end: usize = start;
		for end < path_val.len && path_val[end] != (':' cast u8) {
			end += 1;
		}
		let seg_len: usize = end - start;
		let total: usize = (seg_len == 0 ? 1 : seg_len) + 1 + program.len;
		if total < 4096 {
			let mut pos: usize = 0;
			if seg_len == 0 {
				cand[0] = '.' cast u8;
				pos = 1;
			} else {
				std.mem.copy(&cand[0], &path_val[start], seg_len);
				pos = seg_len;
			}
			cand[pos] = '/' cast u8;
			pos += 1;
			std.mem.copy(&cand[pos], program.ptr, program.len);
			cand[pos + program.len] = 0;
			match std.io.dir.stat(&cand[0], true) {
				.Ok(info) => {
					if info.kind == std.io.fs.Kind.Regular {
						return exec(&cand[0], argv);
					}
				}
				.Err(_) => {}
			}
		}
		start = end + 1;
	}
	return -(std.err.Code.NoSuchFileOrDirectory cast isize);
}

/// Runs `command` through `/bin/sh -c` and returns its exit status.
/// Returns a negative `std.err.Code` value if the process could not be started
/// or its status could not be collected. The shell starts with an empty
/// environment; if it is terminated by a signal, the result is 128 plus the
/// signal number.
pub fn shell(command: *u8) -> isize {
	return std.arch.proc.shell(command);
}
