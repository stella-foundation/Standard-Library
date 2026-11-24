mod std.math.rand.xoshiro256pp;
import "./rand.sl";
import "./splitmix64.sl";
import "std/bit.sl";

/// Explicit xoshiro256++ state. This PRNG is deterministic and non-cryptographic.
pub struct State {
	s0: u64,
	s1: u64,
	s2: u64,
	s3: u64
}

/// Initializes an xoshiro256++ generator from a deterministic seed.
pub fn init(seed: u64) -> State {
	let mut result: State;
	let mut value: u64 = seed;
	value +%= std.math.rand.splitmix64.INCREMENT;
	result.s0 = std.math.rand.splitmix64.mix(value);
	value +%= std.math.rand.splitmix64.INCREMENT;
	result.s1 = std.math.rand.splitmix64.mix(value);
	value +%= std.math.rand.splitmix64.INCREMENT;
	result.s2 = std.math.rand.splitmix64.mix(value);
	value +%= std.math.rand.splitmix64.INCREMENT;
	result.s3 = std.math.rand.splitmix64.mix(value);
	if result.s0 == 0 && result.s1 == 0 && result.s2 == 0 && result.s3 == 0 {
		result.s0 = 1;
	}
	return result;
}

impl std.math.rand.Rng64 for State {
	fn next(generator: *mut Self) -> u64 {
		let result: u64 = std.bit.rotl(generator.s0 +% generator.s3, 23) +% generator.s0;
		let temporary: u64 = generator.s1 << 17;
		generator.s2 ^= generator.s0;
		generator.s3 ^= generator.s1;
		generator.s1 ^= generator.s2;
		generator.s0 ^= generator.s3;
		generator.s2 ^= temporary;
		generator.s3 = std.bit.rotl(generator.s3, 45);
		return result;
	}

	fn below(generator: *mut Self, bound: u64) -> u64 {
		if bound == 0 {
			return 0;
		}
		let mut threshold: u64 = (0 cast u64) -% bound;
		threshold %= bound;
		for true {
			let value: u64 = generator.next();
			if value >= threshold {
				return value % bound;
			}
		}
		return 0;
	}
}
