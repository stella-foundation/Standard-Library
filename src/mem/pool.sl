mod std.mem;
import "./allocator.sl";
import "std/err.sl";

struct PoolNode {
	next: *mut PoolNode
}

struct PoolChunk {
	next: *mut PoolChunk,
	size: usize,
	align: usize
}

/// Fixed-size block pool allocator with O(1) allocation and deallocation.
pub struct PoolAllocator<A: Allocator> {
	backing: *mut A,
	chunks: *mut PoolChunk,
	free_list: *mut PoolNode,
	block_size: usize,
	block_align: usize,
	blocks_per_chunk: usize
}

impl<A: Allocator> PoolAllocator<A> {
	/// Initializes a `PoolAllocator` for blocks of `block_size` bytes and `block_align` alignment.
	pub fn init(
		backing: *mut A,
		block_size: usize,
		block_align: usize,
		blocks_per_chunk: usize
	) -> std.err.Result<Self, std.err.Code> {
		if backing == null || !is_valid_align(block_align) || blocks_per_chunk == 0 {
			return .Err(std.err.Code.InvalidArgument);
		}
		let min_size: usize = @of.size(PoolNode);
		let min_align: usize = @of.align(PoolNode);
		let eff_align: usize = block_align > min_align ? block_align : min_align;
		let raw_size: usize = block_size > min_size ? block_size : min_size;
		let mut eff_size: usize = 0;
		match align_up(raw_size, eff_align) {
			.Some(v) => eff_size = v,
			.None => return .Err(std.err.Code.CannotAllocateMemory)
		}
		let result: PoolAllocator<A> = {
			.backing = backing,
			.chunks = null,
			.free_list = null,
			.block_size = eff_size,
			.block_align = eff_align,
			.blocks_per_chunk = blocks_per_chunk
		};
		return .Ok(result);
	}

	/// Releases all chunks allocated by this pool back to the backing allocator.
	pub fn deinit(self: *mut Self) -> void {
		if self == null || self.backing == null {
			return;
		}
		let mut curr: *mut PoolChunk = self.chunks;
		for curr != null {
			let next: *mut PoolChunk = curr.next;
			self.backing.free(curr cast *u8, curr.size, curr.align);
			curr = next;
		}
		self.chunks = null;
		self.free_list = null;
	}

	/// Returns the effective size in bytes of each pooled block.
	pub fn slot_size(self: *Self) -> usize {
		if self == null {
			return 0;
		}
		return self.block_size;
	}

	fn grow(self: *mut Self) -> std.err.Code {
		let max_size: usize = (0 cast usize) - 1;
		let mut data_offset: usize = 0;
		match align_up(@of.size(PoolChunk), self.block_align) {
			.Some(v) => data_offset = v,
			.None => return std.err.Code.CannotAllocateMemory
		}
		if self.blocks_per_chunk > max_size / self.block_size {
			return std.err.Code.CannotAllocateMemory;
		}
		let blocks_bytes: usize = self.block_size * self.blocks_per_chunk;
		if blocks_bytes > max_size - data_offset {
			return std.err.Code.CannotAllocateMemory;
		}
		let chunk_size: usize = data_offset + blocks_bytes;
		let header_align: usize = @of.align(PoolChunk);
		let chunk_align: usize = self.block_align > header_align
			? self.block_align
			: header_align;
		let mut raw: *mut u8 = null;
		match self.backing.alloc(chunk_size, chunk_align) {
			.Ok(p) => raw = p,
			.Err(e) => return e
		}
		let chunk: *mut PoolChunk = raw cast *mut PoolChunk;
		chunk.next = self.chunks;
		chunk.size = chunk_size;
		chunk.align = chunk_align;
		self.chunks = chunk;
		let base: usize = (raw cast usize) + data_offset;
		let mut i: usize = self.blocks_per_chunk;
		for i > 0 {
			i -= 1;
			let node: *mut PoolNode = (base + i * self.block_size) cast *mut PoolNode;
			node.next = self.free_list;
			self.free_list = node;
		}
		return std.err.Code.Success;
	}
}

impl<A: Allocator> Allocator for PoolAllocator<A> {
	/// Allocates one fixed-size block if `size` and `align` fit the pool configuration.
	pub fn alloc(
		self: *mut Self,
		size: usize,
		align: usize
	) -> std.err.Result<*mut u8, std.err.Code> {
		if self == null || self.backing == null || size == 0 || !is_valid_align(align) {
			return .Err(std.err.Code.InvalidArgument);
		}
		if size > self.block_size || align > self.block_align {
			return .Err(std.err.Code.InvalidArgument);
		}
		if self.free_list == null {
			let err: std.err.Code = self.grow();
			if err != std.err.Code.Success {
				return .Err(err);
			}
		}
		let node: *mut PoolNode = self.free_list;
		self.free_list = node.next;
		return .Ok(node cast *mut u8);
	}

	/// Succeeds in place when `new_size` and `align` remain within the pool block limits.
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
		return old_size <= self.block_size
			&& new_size <= self.block_size
			&& align <= self.block_align;
	}

	/// Returns a block back to the pool free list.
	pub fn free(self: *mut Self, ptr: *u8, size: usize, align: usize) -> void {
		if self == null
			|| ptr == null
			|| size == 0
			|| !is_valid_align(align)
			|| size > self.block_size
			|| align > self.block_align {
			return;
		}
		let node: *mut PoolNode = ptr cast *mut PoolNode;
		node.next = self.free_list;
		self.free_list = node;
	}
}
