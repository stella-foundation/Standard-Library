mod std.io;
import "./io.sl";
import "std/err.sl";
import "std/math/is.sl";
import "std/str/basic.sl";

/// Emits bytes directly through a writer, completing short writes.
pub fn append_bytes<W: Writer>(output: *mut W, source: *u8, length: usize) -> std.err.Code {
	return write_all(output, source, length);
}

/// Writes one byte to the writer, completing short writes.
pub fn append_byte<W: Writer>(output: *mut W, c: u8) -> std.err.Code {
	return write_all(output, &c, 1);
}

/// Writes an unsigned integer in the requested base.
#[!inline]
pub fn emit_uint<W: Writer>(output: *mut W, mut value: u64, base: u8) -> std.err.Code {
	let mut buf: [65]u8;
	let capacity: usize = 65;
	let mut pos: usize = capacity;
	let zero: u64 = 0;
	let ten: u64 = 10;
	let base64: u64 = base cast u64;

	if value == zero {
		pos -= 1;
		buf[pos] = '0';
	} else {
		for value != zero {
			let digit: u64 = value % base64;
			value /= base64;
			pos -= 1;
			if digit < ten {
				buf[pos] = (digit + ('0' cast u64)) cast u8;
			} else {
				buf[pos] = (digit + ('a' cast u64) - ten) cast u8;
			}
		}
	}

	return output.append_bytes(&buf[pos], capacity - pos);
}

/// Writes a signed integer in decimal notation.
pub fn emit_sint<W: Writer>(output: *mut W, value: i64) -> std.err.Code {
	let zero: i64 = 0;
	let mut n: u64 = value cast u64;
	if value < zero {
		let sign_code: std.err.Code = output.append_byte('-');
		if sign_code != std.err.Code.Success {
			return sign_code;
		}
		let uzero: u64 = 0;
		n = uzero - n;
	}
	return output.emit_uint(n, 10);
}

/// Writes an unsigned value as exactly six decimal digits, including leading zeroes.
/// The formatter uses this for the fractional part of `%f64` output.
pub fn emit_fraction6<W: Writer>(output: *mut W, mut value: u64) -> std.err.Code {
	let mut buf: [6]u8;
	let ten: u64 = 10;
	let mut pos: usize = 6;
	for pos != 0 {
		pos -= 1;
		buf[pos] = ((value % ten) + ('0' cast u64)) cast u8;
		value /= ten;
	}
	return output.append_bytes(&buf[0], 6);
}

/// Writes a floating-point value in scientific notation.
pub fn emit_scientific_float<W: Writer>(output: *mut W, value: f64) -> std.err.Code {
	let mut mantissa: f64 = value;
	let mut exponent: i32 = 0;
	for mantissa >= 10.0 {
		mantissa /= 10.0;
		exponent += 1;
	}
	for mantissa < 1.0 {
		mantissa *= 10.0;
		exponent -= 1;
	}
	let mut rounded: u64 = (mantissa * 1000000.0 + 0.5) cast u64;
	if rounded >= 10000000 {
		rounded = 1000000;
		exponent += 1;
	}
	let whole: u64 = rounded / 1000000;
	let fraction: u64 = rounded % 1000000;
	let whole_code: std.err.Code = output.emit_uint(whole, 10);
	if whole_code != std.err.Code.Success {
		return whole_code;
	}
	let decimal_code: std.err.Code = output.append_byte('.');
	if decimal_code != std.err.Code.Success {
		return decimal_code;
	}
	let fraction_code: std.err.Code = output.emit_fraction6(fraction);
	if fraction_code != std.err.Code.Success {
		return fraction_code;
	}
	let exponent_code: std.err.Code = output.append_byte('e');
	if exponent_code != std.err.Code.Success {
		return exponent_code;
	}
	if exponent < 0 {
		let negative_sign_code: std.err.Code = output.append_byte('-');
		if negative_sign_code != std.err.Code.Success {
			return negative_sign_code;
		}
	} else {
		let positive_sign_code: std.err.Code = output.append_byte('+');
		if positive_sign_code != std.err.Code.Success {
			return positive_sign_code;
		}
	}
	let mut exponent_magnitude: u64 = exponent cast u64;
	if exponent < 0 {
		exponent_magnitude = (0 cast u64) - exponent_magnitude;
	}
	return output.emit_uint(exponent_magnitude, 10);
}

/// Formats an `f64` value with six fractional digits.
/// Uses scientific notation for values outside the unsigned integer range.
#[!inline]
pub fn emit_float<W: Writer>(output: *mut W, mut value: f64) -> std.err.Code {
	let zero: f64 = 0.0;
	let half: f64 = 0.5;
	let scale: f64 = 1000000.0;
	let scale_int: u64 = 1000000;
	if value != value {
		let nan_first_code: std.err.Code = output.append_byte('n');
		if nan_first_code != std.err.Code.Success {
			return nan_first_code;
		}
		let nan_middle_code: std.err.Code = output.append_byte('a');
		if nan_middle_code != std.err.Code.Success {
			return nan_middle_code;
		}
		let nan_last_code: std.err.Code = output.append_byte('n');
		if nan_last_code != std.err.Code.Success {
			return nan_last_code;
		}
		return std.err.Code.Success;
	}
	let negative: bool = std.math.is.signbit(value);
	if std.math.is.inf(value) {
		if negative {
			let infinity_sign_code: std.err.Code = output.append_byte('-');
			if infinity_sign_code != std.err.Code.Success {
				return infinity_sign_code;
			}
		}
		let infinity_first_code: std.err.Code = output.append_byte('i');
		if infinity_first_code != std.err.Code.Success {
			return infinity_first_code;
		}
		let infinity_middle_code: std.err.Code = output.append_byte('n');
		if infinity_middle_code != std.err.Code.Success {
			return infinity_middle_code;
		}
		let infinity_last_code: std.err.Code = output.append_byte('f');
		if infinity_last_code != std.err.Code.Success {
			return infinity_last_code;
		}
		return std.err.Code.Success;
	}

	if negative {
		value = zero - value;
	}
	if negative {
		let negative_sign_code: std.err.Code = output.append_byte('-');
		if negative_sign_code != std.err.Code.Success {
			return negative_sign_code;
		}
	}
	if value >= 18446744073709551616.0 {
		let scientific_code: std.err.Code = output.emit_scientific_float(value);
		if scientific_code != std.err.Code.Success {
			return scientific_code;
		}
		return std.err.Code.Success;
	}

	let mut whole: u64 = value cast u64;
	let fraction: f64 = value - (whole cast f64);
	let mut fraction_int: u64 = (fraction * scale + half) cast u64;
	if fraction_int == scale_int {
		whole += 1;
		fraction_int = 0;
	}

	let whole_code: std.err.Code = output.emit_uint(whole, 10);
	if whole_code != std.err.Code.Success {
		return whole_code;
	}
	let decimal_code: std.err.Code = output.append_byte('.');
	if decimal_code != std.err.Code.Success {
		return decimal_code;
	}
	return output.emit_fraction6(fraction_int);
}

pub enum FormatArg: u8 {
	Sint(i64),
	Uint(u64),
	Float(f64),
	Bool(bool),
	Str([]u8),
	CStr(*u8),
	Ptr(u64)
}

pub fn fmt_arg(v: FormatArg) -> FormatArg {
	return v;
}
pub fn fmt_arg<T: i>(v: T) -> FormatArg {
	return FormatArg.Sint(v cast i64);
}
pub fn fmt_arg<T: u>(v: T) -> FormatArg {
	return FormatArg.Uint(v cast u64);
}
pub fn fmt_arg<T: f>(v: T) -> FormatArg {
	return FormatArg.Float(v cast f64);
}
pub fn fmt_arg(v: bool) -> FormatArg {
	return FormatArg.Bool(v);
}
pub fn fmt_arg(v: []u8) -> FormatArg {
	return FormatArg.Str(v);
}
pub fn fmt_arg(v: *u8) -> FormatArg {
	return FormatArg.CStr(v);
}
pub fn fmt_arg(v: *void) -> FormatArg {
	return FormatArg.Ptr(v cast usize cast u64);
}

pub fn emit_format_arg<W: Writer>(output: *mut W, arg: FormatArg, spec: u8) -> std.err.Code {
	match spec {
		'x' => {
			match arg {
				.Uint(u) => return output.emit_uint(u, 16),
				.Sint(s) => return output.emit_uint(s cast u64, 16),
				.Ptr(p) => {
					if output.append_bytes("0x".ptr, 2) != std.err.Code.Success {
						return std.err.Code.InputOutputError;
					}
					return output.emit_uint(p, 16);
				}
				_ => return std.err.Code.InvalidArgument,
			}
		}
		'c' => {
			match arg {
				.Uint(u) => return output.append_byte(u cast u8),
				.Sint(s) => return output.append_byte(s cast u8),
				_ => return std.err.Code.InvalidArgument,
			}
		}
		's' => {
			// {cs}
			match arg {
				.CStr(p) => {
					if p != null {
						return output.append_bytes(p, std.str.c_len(p));
					}
					return std.err.Code.Success;
				}
				_ => return std.err.Code.InvalidArgument,
			}
		}
		_ => {
			// Default `{}`
			match arg {
				.Sint(s) => return output.emit_sint(s),
				.Uint(u) => return output.emit_uint(u, 10),
				.Float(flt) => return output.emit_float(flt),
				.Bool(b) => {
					if b {
						return output.append_bytes("true".ptr, 4);
					}
					return output.append_bytes("false".ptr, 5);
				}
				.Str(str) => {
					if str.len > 0 && str.ptr != null {
						return output.append_bytes(str.ptr, str.len);
					}
					return std.err.Code.Success;
				}
				.CStr(cstr) => {
					if cstr != null {
						return output.append_bytes(cstr, std.str.c_len(cstr));
					}
					return std.err.Code.Success;
				}
				.Ptr(p) => {
					if output.append_bytes("0x".ptr, 2) != std.err.Code.Success {
						return std.err.Code.InputOutputError;
					}
					return output.emit_uint(p, 16);
				}
			}
		}
	}
}
