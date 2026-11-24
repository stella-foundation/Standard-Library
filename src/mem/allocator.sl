mod std.mem;
import "std/err.sl";

pub const MAX_USIZE: usize = (0 cast usize) - 1;

/// Interface for memory allocators.
pub trait Allocator {
	/// Allocates `size` bytes aligned to `align` and returns a pointer or an error.
	fn alloc(self: *mut Self, size: usize, align: usize) -> std.err.Result<*mut u8, std.err.Code>;
	/// Attempts to resize an existing allocation in place without moving `ptr`.
	fn resize(
		self: *mut Self,
		ptr: *mut u8,
		old_size: usize,
		new_size: usize,
		align: usize
	) -> bool;
	/// Releases a previous allocation of `size` bytes with alignment `align`.
	fn free(self: *mut Self, ptr: *u8, size: usize, align: usize) -> void;
}

/// Returns `true` when `align` is a non-zero power of two.
pub fn is_valid_align(align: usize) -> bool {
	return align != 0 && (align & (align - 1)) == 0;
}

/// Rounds `value` up to the next multiple of `align`, or `None` on invalid alignment or overflow.
pub fn align_up(value: usize, align: usize) -> std.err.Option<usize> {
	if !is_valid_align(align) {
		return .None;
	}
	let mask: usize = align - 1;
	if value > MAX_USIZE - mask {
		return .None;
	}
	return .Some((value + mask) & ~mask);
}

/// Rounds `value` down to a multiple of `align`, or `None` on invalid alignment.
pub fn align_down(value: usize, align: usize) -> std.err.Option<usize> {
	if !is_valid_align(align) {
		return .None;
	}
	let mask: usize = align - 1;
	return .Some(value & ~mask);
}

/// Copies exactly `n` bytes from `src` to `dst`. Regions must not overlap.
pub fn copy(dst: *mut u8, src: *u8, n: usize) -> void {
	if n == 0 || dst == null || src == null || dst == (src cast *mut u8) {
		return;
	}
	for let mut i: usize = 0; i < n; i += 1 {
		dst[i] = src[i];
	}
}

/// Copies exactly `n` bytes from `src` to `dst`, safely handling overlapping regions.
pub fn move(dst: *mut u8, src: *u8, n: usize) -> void {
	if n == 0 || dst == null || src == null || dst == (src cast *mut u8) {
		return;
	}
	let d: usize = dst cast usize;
	let s: usize = src cast usize;
	if d < s {
		for let mut i: usize = 0; i < n; i += 1 {
			dst[i] = src[i];
		}
		return;
	}
	let mut i: usize = n;
	for i > 0 {
		i -= 1;
		dst[i] = src[i];
	}
}

/// Sets exactly `n` bytes of `dst` to `value`.
pub fn set(dst: *mut u8, value: u8, n: usize) -> void {
	if n == 0 || dst == null {
		return;
	}
	for let mut i: usize = 0; i < n; i += 1 {
		dst[i] = value;
	}
}

/// Compares `n` bytes at `a` and `b`, returning `true` if all bytes are equal.
pub fn eq(a: *u8, b: *u8, n: usize) -> bool {
	if n == 0 {
		return true;
	}
	if a == null || b == null {
		return a == b;
	}
	if a == b {
		return true;
	}
	for let mut i: usize = 0; i < n; i += 1 {
		if a[i] != b[i] {
			return false;
		}
	}
	return true;
}

/// Copies up to `dst.len` bytes from `src` into `dst` and returns the count copied.
pub fn copy_slice(dst: []mut u8, src: []u8) -> usize {
	let n: usize = dst.len < src.len ? dst.len : src.len;
	copy(dst.ptr, src.ptr, n);
	return n;
}

/// Sets all bytes in `dst` to `value`.
pub fn fill(dst: []mut u8, value: u8) -> void {
	set(dst.ptr, value, dst.len);
}

/// Allocates `size` zero-initialized bytes using `allocator`.
pub fn alloc_zeroed<A: Allocator>(
	allocator: *mut A,
	size: usize,
	align: usize
) -> std.err.Result<*mut u8, std.err.Code> {
	if allocator == null {
		return .Err(std.err.Code.InvalidArgument);
	}
	match allocator.alloc(size, align) {
		.Ok(p) => {
			set(p, 0, size);
			return .Ok(p);
		}
		.Err(e) => return .Err(e)
	}
}

/// Resizes an allocation, moving its contents to a new allocation if in-place resize fails.
pub fn realloc<A: Allocator>(
	allocator: *mut A,
	ptr: *mut u8,
	old_size: usize,
	new_size: usize,
	align: usize
) -> std.err.Result<*mut u8, std.err.Code> {
	if allocator == null {
		return .Err(std.err.Code.InvalidArgument);
	}
	if ptr == null {
		if old_size != 0 {
			return .Err(std.err.Code.InvalidArgument);
		}
		return allocator.alloc(new_size, align);
	}
	if new_size == 0 || !is_valid_align(align) {
		return .Err(std.err.Code.InvalidArgument);
	}
	if allocator.resize(ptr, old_size, new_size, align) {
		return .Ok(ptr);
	}
	match allocator.alloc(new_size, align) {
		.Ok(new_ptr) => {
			let n: usize = old_size < new_size ? old_size : new_size;
			copy(new_ptr, ptr, n);
			allocator.free(ptr, old_size, align);
			return .Ok(new_ptr);
		}
		.Err(e) => return .Err(e)
	}
}

/// Allocates space for a single value of type `T` using `allocator`.
pub fn create<T, A: Allocator>(allocator: *mut A) -> std.err.Result<*mut T, std.err.Code> {
	if allocator == null {
		return .Err(std.err.Code.InvalidArgument);
	}
	let raw_size: usize = @of.size(T);
	let alloc_size: usize = raw_size == 0 ? 1 : raw_size;
	match allocator.alloc(alloc_size, @of.align(T)) {
		.Ok(p) => return .Ok(p cast *mut T),
		.Err(e) => return .Err(e)
	}
}

/// Frees a single value of type `T` previously allocated with `create`.
pub fn destroy<T, A: Allocator>(allocator: *mut A, ptr: *T) -> void {
	if allocator == null || ptr == null {
		return;
	}
	let raw_size: usize = @of.size(T);
	let alloc_size: usize = raw_size == 0 ? 1 : raw_size;
	allocator.free(ptr cast *u8, alloc_size, @of.align(T));
}

/// Allocates a mutable slice of `count` elements of type `T` using `allocator`.
pub fn alloc_slice_with<T, A: Allocator>(
	allocator: *mut A,
	count: usize
) -> std.err.Result<[]mut T, std.err.Code> {
	if allocator == null || count == 0 {
		return .Err(std.err.Code.InvalidArgument);
	}
	let elem_size: usize = @of.size(T);
	let mut total: usize = 1;
	if elem_size > 0 {
		if count > MAX_USIZE / elem_size {
			return .Err(std.err.Code.CannotAllocateMemory);
		}
		total = count * elem_size;
	}
	match allocator.alloc(total, @of.align(T)) {
		.Ok(p) => return .Ok((p cast *mut T)[0..count]),
		.Err(e) => return .Err(e)
	}
}

/// Frees a slice previously allocated with `alloc_slice_with`.
pub fn free_slice_with<T, A: Allocator>(allocator: *mut A, slice: []T) -> void {
	if allocator == null || slice.ptr == null || slice.len == 0 {
		return;
	}
	let elem_size: usize = @of.size(T);
	let total: usize = elem_size == 0 ? 1 : slice.len * elem_size;
	allocator.free(slice.ptr cast *u8, total, @of.align(T));
}

/// Allocates a copy of `src` using `allocator`.
pub fn dupe<T, A: Allocator>(
	allocator: *mut A,
	src: []T
) -> std.err.Result<[]mut T, std.err.Code> {
	if allocator == null || (src.len > 0 && src.ptr == null) {
		return .Err(std.err.Code.InvalidArgument);
	}
	match alloc_slice_with<T, A>(allocator, src.len) {
		.Ok(dst) => {
			let elem_size: usize = @of.size(T);
			if elem_size > 0 {
				copy(dst.ptr cast *mut u8, src.ptr cast *u8, src.len * elem_size);
			}
			return .Ok(dst);
		}
		.Err(e) => return .Err(e)
	}
}
