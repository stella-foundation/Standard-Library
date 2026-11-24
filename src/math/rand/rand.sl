mod std.math.rand;

/// Contract for 32-bit pseudorandom number generators.
pub trait Rng32 {
	/// Advances the generator and returns its next 32-bit value.
	fn next(generator: *mut Self) -> u32;
	/// Returns a value below `bound`, or zero when `bound` is zero.
	fn below(generator: *mut Self, bound: u32) -> u32;
}

/// Contract for 64-bit pseudorandom number generators.
pub trait Rng64 {
	/// Advances the generator and returns its next 64-bit value.
	fn next(generator: *mut Self) -> u64;
	/// Returns a value below `bound`, or zero when `bound` is zero.
	fn below(generator: *mut Self, bound: u64) -> u64;
}

/// Returns a pseudorandom value in [min, max] inclusive from any Rng32.
pub fn range32<R: Rng32>(rng: *mut R, min: u32, max: u32) -> u32 {
	if min >= max {
		return min;
	}
	return min + rng.below(max - min + 1);
}

/// Returns a pseudorandom value in [min, max] inclusive from any Rng64.
pub fn range64<R: Rng64>(rng: *mut R, min: u64, max: u64) -> u64 {
	if min >= max {
		return min;
	}
	return min + rng.below(max - min + 1);
}
