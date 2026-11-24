mod std.mem;
import "./allocator.sl";
import "std/err.sl";

/// Default backing chunk size in bytes for `HeapAllocator`.
pub const DEFAULT_HEAP_CHUNK_SIZE: usize = 65536;
pub const HEAP_ALIGN: usize = @of.align(u128);

struct HeapChunk {
	next: *mut HeapChunk,
	size: usize,
	align: usize
}

struct HeapBlock {
	payload_size: usize,
	is_free: bool,
	prev: *mut HeapBlock,
	next: *mut HeapBlock,
	prev_free: *mut HeapBlock,
	next_free: *mut HeapBlock
}

fn block_header_size() -> usize {
	match align_up(@of.size(HeapBlock), HEAP_ALIGN) {
		.Some(v) => return v,
		.None => return @of.size(HeapBlock)
	}
}

fn chunk_header_size() -> usize {
	match align_up(@of.size(HeapChunk), HEAP_ALIGN) {
		.Some(v) => return v,
		.None => return @of.size(HeapChunk)
	}
}

/// General-purpose coalescing free-list allocator backed by any `Allocator`.
pub struct HeapAllocator<A: Allocator> {
	backing: *mut A,
	chunks: *mut HeapChunk,
	free_head: *mut HeapBlock,
	default_chunk_size: usize
}

impl<A: Allocator> HeapAllocator<A> {
	/// Initializes a `HeapAllocator` with the default chunk size.
	pub fn init(backing: *mut A) -> HeapAllocator<A> {
		return init_with_chunk_size(backing, DEFAULT_HEAP_CHUNK_SIZE);
	}

	/// Initializes a `HeapAllocator` with at least `chunk_size` bytes per backing chunk.
	pub fn init_with_chunk_size(backing: *mut A, chunk_size: usize) -> HeapAllocator<A> {
		let min_chunk: usize = chunk_header_size() + block_header_size() + HEAP_ALIGN;
		let eff_size: usize = chunk_size > min_chunk ? chunk_size : min_chunk;
		let result: HeapAllocator<A> = {
			.backing = backing,
			.chunks = null,
			.free_head = null,
			.default_chunk_size = eff_size
		};
		return result;
	}

	/// Releases all backing chunks allocated by this heap back to its backing allocator.
	pub fn deinit(self: *mut Self) -> void {
		if self == null || self.backing == null {
			return;
		}
		let mut curr: *mut HeapChunk = self.chunks;
		for curr != null {
			let next: *mut HeapChunk = curr.next;
			self.backing.free(curr cast *u8, curr.size, curr.align);
			curr = next;
		}
		self.chunks = null;
		self.free_head = null;
	}

	fn insert_free(self: *mut Self, block: *mut HeapBlock) -> void {
		block.is_free = true;
		block.prev_free = null;
		block.next_free = self.free_head;
		if self.free_head != null {
			self.free_head.prev_free = block;
		}
		self.free_head = block;
	}

	fn remove_free(self: *mut Self, block: *mut HeapBlock) -> void {
		if block.prev_free != null {
			block.prev_free.next_free = block.next_free;
		} else {
			self.free_head = block.next_free;
		}
		if block.next_free != null {
			block.next_free.prev_free = block.prev_free;
		}
		block.prev_free = null;
		block.next_free = null;
	}

	fn split_tail(self: *mut Self, block: *mut HeapBlock, needed_size: usize) -> void {
		let hdr: usize = block_header_size();
		if block.payload_size < needed_size + hdr + HEAP_ALIGN {
			return;
		}
		let tail_addr: usize = (block cast usize) + hdr + needed_size;
		let tail: *mut HeapBlock = tail_addr cast *mut HeapBlock;
		tail.payload_size = block.payload_size - needed_size - hdr;
		tail.is_free = true;
		tail.prev = block;
		tail.next = block.next;
		tail.prev_free = null;
		tail.next_free = null;
		if block.next != null {
			block.next.prev = tail;
		}
		block.next = tail;
		block.payload_size = needed_size;
		self.insert_free(tail);
	}

	fn try_alloc_block(
		self: *mut Self,
		block: *mut HeapBlock,
		needed_size: usize,
		align: usize
	) -> *mut u8 {
		let hdr: usize = block_header_size();
		let payload_addr: usize = (block cast usize) + hdr;
		let mut aligned_addr: usize = payload_addr;
		if (payload_addr & (align - 1)) != 0 {
			match align_up(payload_addr + hdr, align) {
				.Some(v) => aligned_addr = v,
				.None => return null
			}
		}
		let pad: usize = aligned_addr - payload_addr;
		if pad > block.payload_size || needed_size > block.payload_size - pad {
			return null;
		}
		self.remove_free(block);
		block.is_free = false;
		if pad == 0 {
			self.split_tail(block, needed_size);
			return payload_addr cast *mut u8;
		}
		let used_block: *mut HeapBlock = (aligned_addr - hdr) cast *mut HeapBlock;
		used_block.payload_size = block.payload_size - pad;
		used_block.is_free = false;
		used_block.prev = block;
		used_block.next = block.next;
		used_block.prev_free = null;
		used_block.next_free = null;
		if block.next != null {
			block.next.prev = used_block;
		}
		block.next = used_block;
		block.payload_size = pad - hdr;
		self.insert_free(block);
		self.split_tail(used_block, needed_size);
		return aligned_addr cast *mut u8;
	}

	fn grow(
		self: *mut Self,
		needed_size: usize,
		align: usize
	) -> std.err.Result<*mut HeapBlock, std.err.Code> {
		let max_size: usize = (0 cast usize) - 1;
		let chdr: usize = chunk_header_size();
		let bhdr: usize = block_header_size();
		let chunk_align: usize = align > HEAP_ALIGN ? align : HEAP_ALIGN;
		let mut payload_offset: usize = 0;
		match align_up(chdr + bhdr, chunk_align) {
			.Some(v) => payload_offset = v,
			.None => return .Err(std.err.Code.CannotAllocateMemory)
		}
		if needed_size > max_size - payload_offset {
			return .Err(std.err.Code.CannotAllocateMemory);
		}
		let min_needed: usize = payload_offset + needed_size;
		let chunk_size: usize = min_needed > self.default_chunk_size
			? min_needed
			: self.default_chunk_size;
		let mut raw: *mut u8 = null;
		match self.backing.alloc(chunk_size, chunk_align) {
			.Ok(p) => raw = p,
			.Err(e) => return .Err(e)
		}
		let chunk: *mut HeapChunk = raw cast *mut HeapChunk;
		chunk.next = self.chunks;
		chunk.size = chunk_size;
		chunk.align = chunk_align;
		self.chunks = chunk;
		let block_addr: usize = (raw cast usize) + payload_offset - bhdr;
		let block: *mut HeapBlock = block_addr cast *mut HeapBlock;
		block.payload_size = chunk_size - payload_offset;
		block.is_free = true;
		block.prev = null;
		block.next = null;
		block.prev_free = null;
		block.next_free = null;
		self.insert_free(block);
		return .Ok(block);
	}
}

impl<A: Allocator> Allocator for HeapAllocator<A> {
	/// Allocates `size` bytes aligned to `align` from the free list or a new backing chunk.
	pub fn alloc(
		self: *mut Self,
		size: usize,
		align: usize
	) -> std.err.Result<*mut u8, std.err.Code> {
		if self == null || self.backing == null || size == 0 || !is_valid_align(align) {
			return .Err(std.err.Code.InvalidArgument);
		}
		let mut needed_size: usize = 0;
		match align_up(size, HEAP_ALIGN) {
			.Some(v) => needed_size = v,
			.None => return .Err(std.err.Code.CannotAllocateMemory)
		}
		let mut curr: *mut HeapBlock = self.free_head;
		for curr != null {
			let ptr: *mut u8 = self.try_alloc_block(curr, needed_size, align);
			if ptr != null {
				return .Ok(ptr);
			}
			curr = curr.next_free;
		}
		match self.grow(needed_size, align) {
			.Ok(block) => {
				let ptr: *mut u8 = self.try_alloc_block(block, needed_size, align);
				if ptr == null {
					return .Err(std.err.Code.CannotAllocateMemory);
				}
				return .Ok(ptr);
			}
			.Err(e) => return .Err(e)
		}
	}

	/// Attempts to shrink or grow an allocation in place using adjacent free blocks.
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
		let mut needed_size: usize = 0;
		match align_up(new_size, HEAP_ALIGN) {
			.Some(v) => needed_size = v,
			.None => return false
		}
		let hdr: usize = block_header_size();
		let block: *mut HeapBlock = ((ptr cast usize) - hdr) cast *mut HeapBlock;
		if needed_size <= block.payload_size {
			self.split_tail(block, needed_size);
			if block.next != null && block.next.is_free {
				let tail: *mut HeapBlock = block.next;
				if tail.next != null && tail.next.is_free {
					let next_next: *mut HeapBlock = tail.next;
					self.remove_free(next_next);
					tail.payload_size += hdr + next_next.payload_size;
					tail.next = next_next.next;
					if tail.next != null {
						tail.next.prev = tail;
					}
				}
			}
			return true;
		}
		if block.next == null || !block.next.is_free {
			return false;
		}
		let combined: usize = block.payload_size + hdr + block.next.payload_size;
		if combined < needed_size {
			return false;
		}
		let next_block: *mut HeapBlock = block.next;
		self.remove_free(next_block);
		block.payload_size = combined;
		block.next = next_block.next;
		if block.next != null {
			block.next.prev = block;
		}
		self.split_tail(block, needed_size);
		return true;
	}

	/// Frees `ptr` and coalesces it with adjacent free blocks in the same chunk.
	pub fn free(self: *mut Self, ptr: *u8, size: usize, align: usize) -> void {
		if self == null || ptr == null || size == 0 || !is_valid_align(align) {
			return;
		}
		let hdr: usize = block_header_size();
		let mut block: *mut HeapBlock = ((ptr cast usize) - hdr) cast *mut HeapBlock;
		if block.is_free {
			return;
		}
		block.is_free = true;
		if block.next != null && block.next.is_free {
			let next_block: *mut HeapBlock = block.next;
			self.remove_free(next_block);
			block.payload_size += hdr + next_block.payload_size;
			block.next = next_block.next;
			if block.next != null {
				block.next.prev = block;
			}
		}
		if block.prev != null && block.prev.is_free {
			let prev_block: *mut HeapBlock = block.prev;
			prev_block.payload_size += hdr + block.payload_size;
			prev_block.next = block.next;
			if prev_block.next != null {
				prev_block.next.prev = prev_block;
			}
			return;
		}
		self.insert_free(block);
	}
}
