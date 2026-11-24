mod std.env;
import "std/err.sl";
import "std/io/file.sl";

const ENV_MATCH_KEY: u8 = 0;
const ENV_IN_VALUE: u8 = 1;
const ENV_SKIP_ENTRY: u8 = 2;

fn scan_environ(name: []u8, out: []mut u8, has_out: bool, out_len: *mut usize) -> bool {
	if name.len == 0 {
		return false;
	}
	let mut file: std.io.file.File;
	match std.io.file.open(c"/proc/self/environ", std.io.file.OpenFlags.Read, 0) {
		.Ok(opened) => file = opened,
		.Err(_) => return false
	}
	let mut buf: [4096]u8;
	let mut state: u8 = ENV_MATCH_KEY;
	let mut key_pos: usize = 0;
	*out_len = 0;
	for true {
		let mut n: usize = 0;
		match file.read(&buf[0], 4096) {
			.Ok(cnt) => n = cnt,
			.Err(e) => {
				if e == std.err.Code.InterruptedSystemCall {
					continue;
				}
				file.close();
				return false;
			}
		}
		if n == 0 {
			break;
		}
		for let mut i: usize = 0; i < n; i += 1 {
			let b: u8 = buf[i];
			if b == 0 {
				if state == ENV_IN_VALUE {
					file.close();
					return true;
				}
				state = ENV_MATCH_KEY;
				key_pos = 0;
			} else if state == ENV_MATCH_KEY {
				if key_pos == name.len {
					if b == ('=' cast u8) {
						state = ENV_IN_VALUE;
						*out_len = 0;
					} else {
						state = ENV_SKIP_ENTRY;
					}
				} else if b == name[key_pos] {
					key_pos += 1;
				} else {
					state = ENV_SKIP_ENTRY;
				}
			} else if state == ENV_IN_VALUE {
				if has_out && *out_len < out.len {
					out[*out_len] = b;
					*out_len += 1;
				}
			}
		}
	}
	file.close();
	return state == ENV_IN_VALUE;
}

/// Reports whether the environment variable `name` is set.
pub fn has(name: []u8) -> bool {
	let mut dummy: [1]u8;
	let mut val_len: usize = 0;
	return scan_environ(name, dummy[0..0], false, &val_len);
}

/// Looks up the environment variable `name`, copying its value into `out`.
pub fn get(name: []u8, out: []mut u8) -> std.err.Option<[]u8> {
	let mut val_len: usize = 0;
	if !scan_environ(name, out, true, &val_len) {
		return .None;
	}
	return .Some(out[0..val_len]);
}
