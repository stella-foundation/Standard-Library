mod std.math.rand.splitmix64;

/// The Weyl-sequence increment used to advance SplitMix64 state.
pub const INCREMENT: u64 = 0x9e3779b97f4a7c15 cast u64;

/// Mixes a 64-bit value into a pseudorandom-looking 64-bit result.
pub fn mix(value: u64) -> u64 {
	let mut z: u64 = value;
	z = (z ^ (z >> 30)) *% (0xbf58476d1ce4e5b9 cast u64);
	z = (z ^ (z >> 27)) *% (0x94d049bb133111eb cast u64);
	return z ^ (z >> 31);
}
