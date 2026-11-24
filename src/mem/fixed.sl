mod std.mem;
import "./allocator.sl";
import "std/err.sl";

/// Bump allocator operating over a caller-owned byte slice without heap allocation.
pub struct FixedBufferAllocator {
	buffer: []mut u8,
	offset: usize
}

impl FixedBufferAllocator {
	/// Initializes a `FixedBufferAllocator` backed by `buffer`.
	pub fn init(buffer: []mut u8) -> FixedBufferAllocator {
		let result: FixedBufferAllocator = {
			.buffer = buffer,
			.offset = 0
		};
		return result;
	}

	/// Resets the bump offset to zero, invalidating all prior allocations.
	pub fn reset(self: *mut Self) -> void {
		if self == null {
			return;
		}
		self.offset = 0;
	}

	/// Returns the number of bytes currently consumed from the backing buffer.
	pub fn used(self: *Self) -> usize {
		if self == null {
			return 0;
		}
		return self.offset;
	}

	/// Returns the number of unused bytes remaining in the backing buffer.
	pub fn remaining(self: *Self) -> usize {
		if self == null || self.offset >= self.buffer.len {
			return 0;
		}
		return self.buffer.len - self.offset;
	}

	/// Returns `true` if `ptr` points within the backing buffer.
	pub fn owns(self: *Self, ptr: *u8) -> bool {
		if self == null || ptr == null || self.buffer.ptr == null {
			return false;
		}
		let base: usize = self.buffer.ptr cast usize;
		let addr: usize = ptr cast usize;
		return addr >= base && addr - base < self.buffer.len;
	}
}

impl Allocator for FixedBufferAllocator {
	/// Allocates `size` bytes aligned to `align` from the remaining buffer capacity.
	pub fn alloc(
		self: *mut Self,
		size: usize,
		align: usize
	) -> std.err.Result<*mut u8, std.err.Code> {
		if self == null || size == 0 || !is_valid_align(align) {
			return .Err(std.err.Code.InvalidArgument);
		}
		if self.buffer.ptr == null || self.offset > self.buffer.len {
			return .Err(std.err.Code.InvalidArgument);
		}
		let max_size: usize = (0 cast usize) - 1;
		let base: usize = self.buffer.ptr cast usize;
		if self.offset > max_size - base {
			return .Err(std.err.Code.CannotAllocateMemory);
		}
		let current: usize = base + self.offset;
		let mut aligned: usize = 0;
		match align_up(current, align) {
			.Some(v) => aligned = v,
			.None => return .Err(std.err.Code.CannotAllocateMemory)
		}
		let padding: usize = aligned - current;
		let avail: usize = self.buffer.len - self.offset;
		if padding > avail || size > avail - padding {
			return .Err(std.err.Code.CannotAllocateMemory);
		}
		self.offset += padding + size;
		return .Ok(aligned cast *mut u8);
	}

	/// Resizes an allocation in place when it is the most recent allocation or shrinking.
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
		if !self.owns(ptr cast *u8) {
			return false;
		}
		let base: usize = self.buffer.ptr cast usize;
		let rel: usize = (ptr cast usize) - base;
		if rel > self.offset || old_size > self.offset - rel {
			return false;
		}
		if rel + old_size == self.offset {
			if new_size <= old_size {
				self.offset -= old_size - new_size;
				return true;
			}
			let extra: usize = new_size - old_size;
			if extra > self.buffer.len - self.offset {
				return false;
			}
			self.offset += extra;
			return true;
		}
		return new_size <= old_size;
	}

	/// Reclaims `ptr` if it was the most recent allocation; otherwise leaves it until `reset`.
	pub fn free(self: *mut Self, ptr: *u8, size: usize, align: usize) -> void {
		if self == null || ptr == null || size == 0 || !is_valid_align(align) {
			return;
		}
		if !self.owns(ptr) {
			return;
		}
		let base: usize = self.buffer.ptr cast usize;
		let rel: usize = (ptr cast usize) - base;
		if rel <= self.offset && size <= self.offset - rel && rel + size == self.offset {
			self.offset -= size;
		}
	}
}
