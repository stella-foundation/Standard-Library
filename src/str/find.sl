mod std.str.find;
import "std/err.sl";

/// Normalizes an ASCII byte when case-insensitive matching is enabled.
fn normalize(byte: u8, ignore_case: bool) -> u8 {
	if ignore_case && byte >= 65 && byte <= 90 {
		return byte + 32;
	}
	return byte;
}

/// Finds the critical suffix and its period.
///
/// The returned position is the length of the left part
/// of the critical factorization.
fn max_suffix(
	needle: []u8,
	reverse: bool,
	ignore_case: bool,
	period_out: *mut usize
) -> usize {
	let needle_length: usize = needle.len;
	let mut suffix_start: usize = 0;
	let mut candidate_start: usize = 0;
	let mut match_length: usize = 1;
	let mut period: usize = 1;

	for candidate_start < needle_length
		&& match_length < needle_length - candidate_start {
		let suffix_byte: u8 = normalize(needle[suffix_start + match_length - 1], ignore_case);
		let candidate_byte: u8 = normalize(needle[candidate_start + match_length], ignore_case);

		let mut is_smaller: bool = candidate_byte < suffix_byte;
		if reverse {
			is_smaller = candidate_byte > suffix_byte;
		}

		if is_smaller {
			candidate_start += match_length;
			match_length = 1;
			period = candidate_start + 1 - suffix_start;
		} else if suffix_byte == candidate_byte {
			if match_length == period {
				candidate_start += period;
				match_length = 1;
			} else {
				match_length += 1;
			}
		} else {
			suffix_start = candidate_start + 1;
			candidate_start = suffix_start;
			match_length = 1;
			period = 1;
		}
	}

	*period_out = period;
	return suffix_start;
}

/// Finds a substring using the Two-Way algorithm, returning the matching slice or `None`.
pub fn substring(haystack: []u8, needle: []u8, ignore_case: bool) -> std.err.Option<[]u8> {
	let needle_length: usize = needle.len;
	let haystack_length: usize = haystack.len;

	if needle_length == 0 {
		return .Some(haystack[0..0]);
	}
	if haystack_length < needle_length {
		return .None;
	}

	if needle_length == 1 {
		let target: u8 = normalize(needle[0], ignore_case);

		for let mut i: usize = 0; i < haystack_length; i += 1 {
			if normalize(haystack[i], ignore_case) == target {
				return .Some(haystack[i .. i + 1]);
			}
		}
		return .None;
	}

	let mut period1: usize = 0;
	let mut period2: usize = 0;

	let suffix1: usize = max_suffix(needle, false, ignore_case, &period1);
	let suffix2: usize = max_suffix(needle, true, ignore_case, &period2);

	let mut critical_position: usize = 0;
	let mut period: usize = 0;

	if suffix1 > suffix2 {
		critical_position = suffix1;
		period = period1;
	} else {
		critical_position = suffix2;
		period = period2;
	}

	let mut is_periodic: bool = period <= needle_length - critical_position;

	if is_periodic {
		for let mut i: usize = 0; i < critical_position; i += 1 {
			if normalize(needle[i], ignore_case) != normalize(needle[period + i], ignore_case) {
				is_periodic = false;
				break;
			}
		}
	}

	if !is_periodic {
		if critical_position > needle_length - critical_position {
			period = critical_position;
		} else {
			period = needle_length - critical_position + 1;
		}
	}

	let mut i: usize = 0;
	let mut memory: usize = 0;

	for i <= haystack_length - needle_length {
		let mut right: usize = critical_position;

		if right < memory {
			right = memory;
		}

		for right < needle_length; right += 1 {
			if normalize(haystack[i + right], ignore_case)
				!= normalize(needle[right], ignore_case) {
				break;
			}
		}

		if right < needle_length {
			i += right - critical_position + 1;
			memory = 0;
		} else {
			let mut left: usize = critical_position;
			let mut is_match: bool = true;

			for left > memory {
				left -= 1;

				if normalize(haystack[i + left], ignore_case)
					!= normalize(needle[left], ignore_case) {
					is_match = false;
					break;
				}
			}

			if is_match {
				return .Some(haystack[i .. i + needle_length]);
			}

			i += period;

			if is_periodic {
				memory = needle_length - period;
			} else {
				memory = 0;
			}
		}
	}

	return .None;
}

mod byte {
	/// Returns the tail slice starting at the first occurrence of `byte`, or `None`.
	pub fn first(str: []u8, byte: u8) -> std.err.Option<[]u8> {
		for let mut i: usize = 0; i < str.len; i += 1 {
			if str[i] == byte {
				return .Some(str[i..]);
			}
		}
		return .None;
	}

	/// Returns the tail slice starting at the last occurrence of `byte`, or `None`.
	pub fn last(str: []u8, byte: u8) -> std.err.Option<[]u8> {
		let mut i: usize = str.len;
		for i > 0 {
			i -= 1;
			if str[i] == byte {
				return .Some(str[i..]);
			}
		}
		return .None;
	}

	/// Returns the tail slice starting at the first byte in `str` contained in `accept`,
	/// or `None`.
	pub fn any(str: []u8, accept: []u8) -> std.err.Option<[]u8> {
		for let mut i: usize = 0; i < str.len; i += 1 {
			for let mut j: usize = 0; j < accept.len; j += 1 {
				if str[i] == accept[j] {
					return .Some(str[i..]);
				}
			}
		}
		return .None;
	}
}
