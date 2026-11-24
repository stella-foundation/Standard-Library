mod std.io;
import "./buffer.sl";
import "./fd.sl";
import "./fmt.sl";
import "./io.sl";
import "std/err.sl";

/// Writes a string slice, preserving writer errors.
pub fn write<W: Writer>(output: *mut W, s: []u8) -> std.err.Code {
	if s.len == 0 {
		return std.err.Code.Success;
	}
	if s.ptr == null {
		return std.err.Code.InvalidArgument;
	}
	return write_all(output, s.ptr, s.len);
}

/// Formats a string slice using typed FormatArg arguments.
pub fn vwritef<W: Writer>(output: *mut W, s: []u8, args: []FormatArg) -> void {
	if output == null || (s.len > 0 && s.ptr == null) {
		return;
	}
	let mut arg_i: usize = 0;
	let mut i: usize = 0;
	for i < s.len {
		let start: usize = i;
		for i < s.len && s[i] != '{' && s[i] != '}' {
			i += 1;
		}
		if i != start {
			if output.append_bytes(&s[start], i - start) != std.err.Code.Success {
				return;
			}
		}
		if i >= s.len {
			break;
		}
		if s[i] == '}' {
			if i + 1 < s.len && s[i + 1] == '}' {
				if output.append_byte('}') != std.err.Code.Success {
					return;
				}
				i += 2;
				continue;
			}
			return;
		}
		// s[i] == '{'
		if i + 1 >= s.len {
			return;
		}
		if s[i + 1] == '{' {
			if output.append_byte('{') != std.err.Code.Success {
				return;
			}
			i += 2;
			continue;
		}
		let mut spec: u8 = 0;
		if s[i + 1] == '}' {
			i += 2;
		} else if i + 2 < s.len && s[i + 2] == '}' &&
				  (s[i + 1] == 'x' || s[i + 1] == 'c') {
			spec = s[i + 1];
			i += 3;
		} else if i + 3 < s.len && s[i + 1] == 'c' && s[i + 2] == 's' && s[i + 3] == '}' {
			spec = 's';
			i += 4;
		} else {
			return;
		}
		if arg_i >= args.len {
			return;
		}
		if emit_format_arg(output, args[arg_i], spec) != std.err.Code.Success {
			return;
		}
		arg_i += 1;
	}
}

/// Formats directly through a writer. The caller chooses any buffering.
pub macro writef<W: Writer>(output: *mut W, s: []u8, ...) {
	std.io.vwritef(output, s, ([std.io.fmt_arg(...)])[..]);
}

/// Writes a string slice to stdout in one descriptor write attempt.
pub fn print(s: []u8) -> void {
	if s.len == 0 || s.ptr == null {
		return;
	}
	let mut fd: std.io.fd.Descriptor = std.io.fd.out();
	fd.write(s.ptr, s.len);
}

/// Writes a string slice to stderr in one descriptor write attempt.
pub fn eprint(s: []u8) -> void {
	if s.len == 0 || s.ptr == null {
		return;
	}
	let mut fd: std.io.fd.Descriptor = std.io.fd.err();
	fd.write(s.ptr, s.len);
}

/// Formats to stdout using a stack-allocated buffer and typed FormatArg slice.
pub fn vprintf(s: []u8, args: []FormatArg) -> void {
	let mut fd: std.io.fd.Descriptor = std.io.fd.out();
	let mut output: Buffer<std.io.fd.Descriptor>;
	output.init(&fd);
	vwritef(&output, s, args);
	output.flush();
}

/// Formats to stderr using a stack-allocated buffer and typed FormatArg slice.
pub fn veprintf(s: []u8, args: []FormatArg) -> void {
	let mut fd: std.io.fd.Descriptor = std.io.fd.err();
	let mut output: Buffer<std.io.fd.Descriptor>;
	output.init(&fd);
	vwritef(&output, s, args);
	output.flush();
}

/// Formats to stdout using a stack-allocated buffer.
pub macro printf(s: []u8, ...) {
	std.io.vprintf(s, ([std.io.fmt_arg(...)])[..]);
}

/// Formats to stderr using a stack-allocated buffer.
pub macro eprintf(s: []u8, ...) {
	std.io.veprintf(s, ([std.io.fmt_arg(...)])[..]);
}
