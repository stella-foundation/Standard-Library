mod std.math.sort;
import "std/math/sort.sl";
import "std/mem.sl";
import "./low_mem.sl";

fn swap<T>(buf: []mut T, a: usize, b: usize) -> void {
	let tmp: T = buf[a];
	buf[a] = buf[b];
	buf[b] = tmp;
}

fn partition<T: Ord>(buf: []mut T) -> usize {
	let n: usize = buf.len;
	let mid: usize = n / 2;
	if buf[mid].cmp(&buf[0]) < 0 {
		swap<T>(buf, 0, mid);
	}
	if buf[n - 1].cmp(&buf[0]) < 0 {
		swap<T>(buf, 0, n - 1);
	}
	if buf[n - 1].cmp(&buf[mid]) < 0 {
		swap<T>(buf, mid, n - 1);
	}
	let pivot: T = buf[mid];
	let mut i: usize = 0;
	let mut j: usize = n - 1;
	for true {
		for buf[i].cmp(&pivot) < 0 {
			i += 1;
		}
		for buf[j].cmp(&pivot) > 0 {
			j -= 1;
		}
		if i >= j {
			return j + 1;
		}
		swap<T>(buf, i, j);
		i += 1;
		j -= 1;
	}
	return 0;
}

fn introsort_loop<T: Ord>(mut buf: []mut T, mut depth_limit: usize) -> void {
	for buf.len > 16 {
		if depth_limit == 0 {
			std.math.sort.low_mem.unstable<T>(buf);
			return;
		}
		depth_limit -= 1;
		let p: usize = partition<T>(buf);
		if p < buf.len - p {
			introsort_loop<T>(buf[0..p], depth_limit);
			buf = buf[p..buf.len];
		} else {
			introsort_loop<T>(buf[p..buf.len], depth_limit);
			buf = buf[0..p];
		}
	}
	if buf.len > 1 {
		std.math.sort.low_mem.stable<T>(buf);
	}
}

/// Sorts `buf` in place using introsort (quicksort with heapsort fallback and
/// insertion sort for small partitions), with O(n log n) worst-case time and
/// O(log n) stack space.
pub fn unstable<T: Ord>(buf: []mut T) -> void {
	let n: usize = buf.len;
	if n < 2 {
		return;
	}
	let mut depth_limit: usize = 0;
	let mut k: usize = n;
	for k > 1 {
		k /= 2;
		depth_limit += 2;
	}
	introsort_loop<T>(buf, depth_limit);
}

/// Sorts `buf` in place using a stable bottom-up mergesort.
/// Uses O(n) auxiliary memory and O(n log n) time.
/// Falls back to a stable O(n²) insertion sort if allocation fails.
pub fn stable<T: Ord>(buf: []mut T) -> void {
	let n: usize = buf.len;
	if n < 2 {
		return;
	}
	let element_size: usize = @of.size(T);
	let max_size: usize = (0 cast usize) - 1;
	if element_size > 0 && n > max_size / element_size {
		std.math.sort.low_mem.stable<T>(buf);
		return;
	}
	let mut pa: std.mem.PageAllocator = std.mem.PageAllocator.init();
	let alloc_size: usize = n * element_size;
	let alloc_align: usize = @of.align(T);
	let mut scratch: *mut T = null;
	match pa.alloc(alloc_size, alloc_align) {
		.Ok(p) => scratch = p cast *mut T,
		.Err(_) => {
			std.math.sort.low_mem.stable<T>(buf);
			return;
		}
	}
	let mut width: usize = 1;
	for width < n {
		let mut left: usize = 0;
		for left < n {
			let mut mid: usize = n;
			if width < n - left {
				mid = left + width;
			}
			let mut right: usize = n;
			if width < n - mid {
				right = mid + width;
			}
			let mut i: usize = left;
			let mut j: usize = mid;
			let mut k: usize = left;
			for i < mid || j < right {
				if j == right || (i < mid && buf[i].cmp(&buf[j]) <= 0) {
					scratch[k] = buf[i];
					i += 1;
				} else {
					scratch[k] = buf[j];
					j += 1;
				}
				k += 1;
			}
			for let mut p: usize = left; p < right; p += 1 {
				buf[p] = scratch[p];
			}
			left = right;
		}
		if width > n / 2 {
			break;
		}
		width *= 2;
	}
	pa.free(scratch cast *u8, alloc_size, alloc_align);
}
