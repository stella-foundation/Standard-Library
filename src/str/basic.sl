mod std.str;

/// Returns the length of a NUL-terminated C string.
pub fn c_len(s: *u8) -> usize {
	if s == null {
		return 0;
	}
	let mut i: usize = 0;
	for s[i] != 0; i += 1 {
		// ...
	}
	return i;
}

/// Wraps a NUL-terminated C string as a byte slice (excluding the NUL byte).
pub fn from_cstr(s: *u8) -> []u8 {
	if s == null {
		return [];
	}
	return s[0..c_len(s)];
}

/// Reports whether two byte slices are equal.
pub fn eq(a: []u8, b: []u8) -> bool {
	if a.len != b.len {
		return false;
	}
	for let mut i: usize = 0; i < a.len; i += 1 {
		if a[i] != b[i] {
			return false;
		}
	}
	return true;
}

/// Compares two byte slices lexicographically.
/// Returns a negative, zero, or positive value.
pub fn cmp(a: []u8, b: []u8) -> i32 {
	let n: usize = a.len < b.len ? a.len : b.len;
	for let mut i: usize = 0; i < n; i += 1 {
		if a[i] != b[i] {
			return (a[i] cast i32) - (b[i] cast i32);
		}
	}
	if a.len < b.len {
		return -1;
	}
	if a.len > b.len {
		return 1;
	}
	return 0;
}

/// Copies bytes from `src` into `dst` (up to `dst.len`) and returns the number of bytes copied.
pub fn copy(dst: []mut u8, src: []u8) -> usize {
	let n: usize = dst.len < src.len ? dst.len : src.len;
	for let mut i: usize = 0; i < n; i += 1 {
		dst[i] = src[i];
	}
	return n;
}
