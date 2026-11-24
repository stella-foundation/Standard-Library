mod std.math.sort;
import "std/err.sl";

/// Returns the first index whose element is not less than `key`, or `buf.len`.
pub fn lower_bound<T: Ord>(buf: []T, key: *T) -> usize {
	let mut first: usize = 0;
	let mut count: usize = buf.len;
	for count > 0 {
		let step: usize = count / 2;
		let mid: usize = first + step;
		if buf[mid].cmp(key) < 0 {
			first = mid + 1;
			count -= step + 1;
		} else {
			count = step;
		}
	}
	return first;
}

/// Returns the matching index, or `None` when `key` is absent.
pub fn binary_search<T: Ord>(buf: []T, key: *T) -> std.err.Option<usize> {
	let index: usize = lower_bound<T>(buf, key);
	if index < buf.len && buf[index].cmp(key) == 0 {
		return .Some(index);
	}
	return .None;
}
