mod std.math.sort.low_mem;
import "std/math/sort.sl";

fn sift_down<T: std.math.sort.Ord>(buf: []mut T, heapn: usize, root: usize) -> void {
	let mut current: usize = root;
	for true {
		if current >= heapn / 2 {
			break;
		}
		let mut largest: usize = current;
		let left: usize = current * 2 + 1;
		let right: usize = left + 1;
		if left < heapn && buf[left].cmp(&buf[largest]) > 0 {
			largest = left;
		}
		if right < heapn && buf[right].cmp(&buf[largest]) > 0 {
			largest = right;
		}
		if largest == current {
			break;
		}

		let value: T = buf[current];
		buf[current] = buf[largest];
		buf[largest] = value;
		current = largest;
	}
}

/// Sorts `buf` in place using heapsort, with O(n log n) time and O(1) auxiliary memory.
/// Uses the Ord trait for comparisons without function pointer overhead.
pub fn unstable<T: std.math.sort.Ord>(buf: []mut T) -> void {
	let n: usize = buf.len;
	if n < 2 {
		return;
	}
	for let mut i: usize = n / 2; i > 0; i = i - 1 {
		sift_down<T>(buf, n, i - 1);
	}
	for let mut end: usize = n - 1; end > 0; end = end - 1 {
		let value: T = buf[0];
		buf[0] = buf[end];
		buf[end] = value;
		sift_down<T>(buf, end, 0);
	}
}

/// Sorts `buf` in place using insertion sort, with O(n²) worst-case time and O(1)
/// auxiliary memory. Preserves the relative order of equal elements.
pub fn stable<T: std.math.sort.Ord>(buf: []mut T) -> void {
	let n: usize = buf.len;
	if n < 2 {
		return;
	}
	for let mut i: usize = 1; i < n; i += 1 {
		let key: T = buf[i];
		let mut j: usize = i;
		for j > 0 && buf[j - 1].cmp(&key) > 0 {
			buf[j] = buf[j - 1];
			j -= 1;
		}
		buf[j] = key;
	}
}
