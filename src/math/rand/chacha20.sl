mod std.math.rand.chacha20;
import "./rand.sl";
import "./splitmix64.sl";
import "std/bit.sl";

/// State for a deterministic ChaCha20 pseudorandom generator.
/// This generator is not cryptographic; use an operating-system source when
/// cryptographic randomness is required.
pub struct State {
	state: [16]u32,
	block: [16]u32,
	index: u32
}

fn quarter_round(state: *mut u32, a: u32, b: u32, c: u32, d: u32) -> void {
	state[a] +%= state[b];
	state[d] ^= state[a];
	state[d] = std.bit.rotl(state[d], 16);

	state[c] +%= state[d];
	state[b] ^= state[c];
	state[b] = std.bit.rotl(state[b], 12);

	state[a] +%= state[b];
	state[d] ^= state[a];
	state[d] = std.bit.rotl(state[d], 8);

	state[c] +%= state[d];
	state[b] ^= state[c];
	state[b] = std.bit.rotl(state[b], 7);
}

fn generate_block(generator: *mut State) -> void {
	let mut working: [16]u32;

	for let mut i: usize = 0; i < 16; i += 1 {
		working[i] = generator.state[i];
	}
	for let mut i: usize = 0; i < 10; i += 1 {
		quarter_round(&working[0], 0, 4, 8, 12);
		quarter_round(&working[0], 1, 5, 9, 13);
		quarter_round(&working[0], 2, 6, 10, 14);
		quarter_round(&working[0], 3, 7, 11, 15);
		quarter_round(&working[0], 0, 5, 10, 15);
		quarter_round(&working[0], 1, 6, 11, 12);
		quarter_round(&working[0], 2, 7, 8, 13);
		quarter_round(&working[0], 3, 4, 9, 14);
	}

	for let mut i: usize = 0; i < 16; i += 1 {
		generator.block[i] = working[i] +% generator.state[i];
	}
	generator.state[12] +%= 1;
	if generator.state[12] == 0 {
		generator.state[13] +%= 1;
	}
	generator.index = 0;
}

/// Initializes a ChaCha20 generator from a deterministic seed.
pub fn init(seed_value: u64) -> State {
	let mut result: State;
	let mut expanded: u64 = seed_value;

	result.state[0] = 0x61707865;
	result.state[1] = 0x3320646e;
	result.state[2] = 0x79622d32;
	result.state[3] = 0x6b206574;

	for let mut i: usize = 0; i < 8; i += 1 {
		expanded +%= std.math.rand.splitmix64.INCREMENT;
		result.state[4 + i] = std.math.rand.splitmix64.mix(expanded) cast u32;
	}
	for let mut i: usize = 13; i < 16; i += 1 {
		expanded +%= std.math.rand.splitmix64.INCREMENT;
		result.state[i] = std.math.rand.splitmix64.mix(expanded) cast u32;
	}

	result.state[12] = 0;
	result.index = 16;
	return result;
}

impl std.math.rand.Rng32 for State {
	fn next(generator: *mut Self) -> u32 {
		if generator.index >= 16 {
			generate_block(generator);
		}
		let result: u32 = generator.block[generator.index];
		generator.index += 1;
		return result;
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
