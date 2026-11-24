mod std.hash;

/// FNV-1a 32-bit offset basis.
pub const FNV1A_32_OFFSET: u32 = 2166136261;

/// FNV-1a 32-bit prime.
pub const FNV1A_32_PRIME: u32 = 16777619;

/// FNV-1a 64-bit offset basis.
pub const FNV1A_64_OFFSET: u64 = 14695981039346656037;

/// FNV-1a 64-bit prime.
pub const FNV1A_64_PRIME: u64 = 1099511628211;

/// Computes the 32-bit FNV-1a hash of `data`.
pub fn fnv1a_32(data: []u8) -> u32 {
	let mut h: u32 = FNV1A_32_OFFSET;
	for let mut i: usize = 0; i < data.len; i += 1 {
		h = (h ^ (data[i] cast u32)) *% FNV1A_32_PRIME;
	}
	return h;
}

/// Computes the 64-bit FNV-1a hash of `data`.
pub fn fnv1a_64(data: []u8) -> u64 {
	let mut h: u64 = FNV1A_64_OFFSET;
	for let mut i: usize = 0; i < data.len; i += 1 {
		h = (h ^ (data[i] cast u64)) *% FNV1A_64_PRIME;
	}
	return h;
}
