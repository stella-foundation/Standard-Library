mod std.mem;
import "./allocator.sl";
import "std/arch/mem.sl";
import "std/err.sl";

/// Virtual memory page size in bytes.
pub const PAGE_SIZE: usize = 4096;

/// Stateless allocator backed directly by OS virtual memory pages.
pub struct PageAllocator {}

impl PageAllocator {
	/// Returns a new `PageAllocator` instance.
	pub fn init() -> PageAllocator {
		let mut result: PageAllocator;
		return result;
	}
}

impl Allocator for PageAllocator {
	/// Allocates at least `size` bytes aligned to `align` using OS page mappings.
	pub fn alloc(
		self: *mut Self,
		size: usize,
		align: usize
	) -> std.err.Result<*mut u8, std.err.Code> {
		if self == null || size == 0 || !is_valid_align(align) {
			return .Err(std.err.Code.InvalidArgument);
		}
		let mut aligned_size: usize = 0;
		match align_up(size, PAGE_SIZE) {
			.Some(v) => aligned_size = v,
			.None => return .Err(std.err.Code.CannotAllocateMemory)
		}
		if align <= PAGE_SIZE {
			let raw: *mut u8 = std.arch.mem.alloc(aligned_size);
			if raw == null {
				return .Err(std.err.Code.CannotAllocateMemory);
			}
			return .Ok(raw);
		}
		let max_size: usize = (0 cast usize) - 1;
		if aligned_size > max_size - align {
			return .Err(std.err.Code.CannotAllocateMemory);
		}
		let total: usize = aligned_size + align;
		let raw: *mut u8 = std.arch.mem.alloc(total);
		if raw == null {
			return .Err(std.err.Code.CannotAllocateMemory);
		}
		let base: usize = raw cast usize;
		let mut aligned_addr: usize = 0;
		match align_up(base, align) {
			.Some(v) => aligned_addr = v,
			.None => {
				std.arch.mem.free(raw, total);
				return .Err(std.err.Code.CannotAllocateMemory);
			}
		}
		let prefix: usize = aligned_addr - base;
		if prefix > 0 {
			std.arch.mem.free(raw, prefix);
		}
		let tail_start: usize = aligned_addr + aligned_size;
		let end: usize = base + total;
		if end > tail_start {
			std.arch.mem.free(tail_start cast *u8, end - tail_start);
		}
		return .Ok(aligned_addr cast *mut u8);
	}

	/// Shrinks page-backed allocations in place or succeeds if page count is unchanged.
	pub fn resize(
		self: *mut Self,
		ptr: *mut u8,
		old_size: usize,
		new_size: usize,
		align: usize
	) -> bool {
		if self == null
			|| ptr == null
			|| old_size == 0
			|| new_size == 0
			|| !is_valid_align(align) {
			return false;
		}
		let mut old_aligned: usize = 0;
		match align_up(old_size, PAGE_SIZE) {
			.Some(v) => old_aligned = v,
			.None => return false
		}
		let mut new_aligned: usize = 0;
		match align_up(new_size, PAGE_SIZE) {
			.Some(v) => new_aligned = v,
			.None => return false
		}
		if new_aligned == old_aligned {
			return true;
		}
		if new_aligned < old_aligned {
			let tail: *u8 = ((ptr cast usize) + new_aligned) cast *u8;
			std.arch.mem.free(tail, old_aligned - new_aligned);
			return true;
		}
		return false;
	}

	/// Unmaps the pages backing `ptr`.
	pub fn free(self: *mut Self, ptr: *u8, size: usize, align: usize) -> void {
		if self == null || ptr == null || size == 0 || !is_valid_align(align) {
			return;
		}
		match align_up(size, PAGE_SIZE) {
			.Some(aligned_size) => std.arch.mem.free(ptr, aligned_size),
			.None => {}
		}
	}
}
