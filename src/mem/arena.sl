mod std.mem;
import "./allocator.sl";
import "std/err.sl";

/// Default slab size in bytes for `ArenaAllocator`.
pub const DEFAULT_ARENA_SLAB_SIZE: usize = 4096;

struct ArenaSlab {
	next: *mut ArenaSlab,
	size: usize,
	align: usize,
	used: usize
}

/// Region-based bump allocator backed by any `Allocator`, freeing all slabs on `deinit`.
pub struct ArenaAllocator<A: Allocator> {
	backing: *mut A,
	head: *mut ArenaSlab,
	default_slab_size: usize
}

impl<A: Allocator> ArenaAllocator<A> {
	/// Initializes an `ArenaAllocator` with the default slab size.
	pub fn init(backing: *mut A) -> ArenaAllocator<A> {
		return init_with_capacity(backing, DEFAULT_ARENA_SLAB_SIZE);
	}

	/// Initializes an `ArenaAllocator` with at least `slab_size` bytes per slab.
	pub fn init_with_capacity(backing: *mut A, slab_size: usize) -> ArenaAllocator<A> {
		let min_slab: usize = @of.size(ArenaSlab);
		let effective_size: usize = slab_size > min_slab ? slab_size : min_slab;
		let result: ArenaAllocator<A> = {
			.backing = backing,
			.head = null,
			.default_slab_size = effective_size
		};
		return result;
	}

	/// Releases all slabs except the primary slab, resetting it for reuse.
	pub fn reset(self: *mut Self) -> void {
		if self == null || self.backing == null || self.head == null {
			return;
		}
		let mut curr: *mut ArenaSlab = self.head.next;
		for curr != null {
			let next: *mut ArenaSlab = curr.next;
			self.backing.free(curr cast *u8, curr.size, curr.align);
			curr = next;
		}
		self.head.next = null;
		self.head.used = @of.size(ArenaSlab);
	}

	/// Releases all memory allocated by this arena back to its backing allocator.
	pub fn deinit(self: *mut Self) -> void {
		if self == null || self.backing == null {
			return;
		}
		let mut curr: *mut ArenaSlab = self.head;
		for curr != null {
			let next: *mut ArenaSlab = curr.next;
			self.backing.free(curr cast *u8, curr.size, curr.align);
			curr = next;
		}
		self.head = null;
	}
}

impl<A: Allocator> Allocator for ArenaAllocator<A> {
	/// Allocates `size` bytes aligned to `align` from the arena.
	pub fn alloc(
		self: *mut Self,
		size: usize,
		align: usize
	) -> std.err.Result<*mut u8, std.err.Code> {
		if self == null || self.backing == null || size == 0 || !is_valid_align(align) {
			return .Err(std.err.Code.InvalidArgument);
		}
		let max_size: usize = (0 cast usize) - 1;
		if self.head != null {
			let base: usize = self.head cast usize;
			if self.head.used <= self.head.size && self.head.used <= max_size - base {
				let current: usize = base + self.head.used;
				match align_up(current, align) {
					.Some(aligned) => {
						let padding: usize = aligned - current;
						let avail: usize = self.head.size - self.head.used;
						if padding <= avail && size <= avail - padding {
							self.head.used += padding + size;
							return .Ok(aligned cast *mut u8);
						}
					}
					.None => {}
				}
			}
		}
		let header_size: usize = @of.size(ArenaSlab);
		let header_align: usize = @of.align(ArenaSlab);
		let slab_align: usize = align > header_align ? align : header_align;
		let mut data_offset: usize = 0;
		match align_up(header_size, align) {
			.Some(v) => data_offset = v,
			.None => return .Err(std.err.Code.CannotAllocateMemory)
		}
		if size > max_size - data_offset {
			return .Err(std.err.Code.CannotAllocateMemory);
		}
		let min_needed: usize = data_offset + size;
		let base_slab: usize = self.default_slab_size > header_size
			? self.default_slab_size
			: DEFAULT_ARENA_SLAB_SIZE;
		let slab_size: usize = min_needed > base_slab ? min_needed : base_slab;
		let mut raw: *mut u8 = null;
		match self.backing.alloc(slab_size, slab_align) {
			.Ok(p) => raw = p,
			.Err(e) => return .Err(e)
		}
		let slab: *mut ArenaSlab = raw cast *mut ArenaSlab;
		slab.next = self.head;
		slab.size = slab_size;
		slab.align = slab_align;
		slab.used = min_needed;
		self.head = slab;
		return .Ok(((raw cast usize) + data_offset) cast *mut u8);
	}

	/// Resizes an allocation in place if it was the most recent allocation in the active slab.
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
		if self.head == null {
			return false;
		}
		let base: usize = self.head cast usize;
		let addr: usize = ptr cast usize;
		let header_size: usize = @of.size(ArenaSlab);
		if addr < base + header_size {
			return false;
		}
		let rel: usize = addr - base;
		if rel > self.head.used || old_size > self.head.used - rel {
			return false;
		}
		if rel + old_size == self.head.used {
			if new_size <= old_size {
				self.head.used -= old_size - new_size;
				return true;
			}
			let extra: usize = new_size - old_size;
			if extra > self.head.size - self.head.used {
				return false;
			}
			self.head.used += extra;
			return true;
		}
		return new_size <= old_size;
	}

	/// Reclaims `ptr` if it was the most recent allocation in the active slab.
	pub fn free(self: *mut Self, ptr: *u8, size: usize, align: usize) -> void {
		if self == null
			|| ptr == null
			|| size == 0
			|| !is_valid_align(align)
			|| self.head == null {
			return;
		}
		let base: usize = self.head cast usize;
		let addr: usize = ptr cast usize;
		let header_size: usize = @of.size(ArenaSlab);
		if addr < base + header_size {
			return;
		}
		let rel: usize = addr - base;
		if rel <= self.head.used
			&& size <= self.head.used - rel
			&& rel + size == self.head.used {
			self.head.used -= size;
		}
	}
}
