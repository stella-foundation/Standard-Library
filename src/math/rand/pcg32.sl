mod std.math.rand.pcg32;
import "./rand.sl";
import "std/bit.sl";

/// Explicit PCG state. The generator is deterministic and non-cryptographic.
pub struct State {
	state: u64,
	increment: u64
}

/// Initializes a PCG32 generator from a seed and sequence value.
pub fn init(seed_value: u64, sequence: u64) -> State {
	let mut result: State;
	result.state = 0;
	result.increment = (sequence << 1) | 1;
	result.state = result.state *% 6364136223846793005 +% result.increment;
	result.state +%= seed_value;
	result.state = result.state *% 6364136223846793005 +% result.increment;
	return result;
}

impl std.math.rand.Rng32 for State {
	fn next(generator: *mut Self) -> u32 {
		let old_state: u64 = generator.state;
		generator.state = old_state *% 6364136223846793005 +% generator.increment;
		let xorshifted: u32 = (((old_state >> 18) ^ old_state) >> 27) cast u32;
		let rotation: u32 = (old_state >> 59) cast u32;
		return std.bit.rotr(xorshifted, rotation cast usize);
	}

	fn below(generator: *mut Self, bound: u32) -> u32 {
		if bound == 0 {
			return 0;
		}
		let mut threshold: u32 = (0 cast u32) -% bound;
		threshold %= bound;
		let mut value: u32;
		for true {
			value = generator.next();
			if value >= threshold {
				return value % bound;
			}
		}
		return 0;
	}
}
