mod std.bit;

/// Rotates an unsigned integer left by `amount` bits.
pub fn rotl<T: u>(x: T, amount: usize) -> T {
	let bits: T = @of.bits(T) cast T;
	let shift: T = (amount % (bits cast usize)) cast T;

	if shift == 0 {
		return x;
	}

	return (x << shift) | (x >> (bits - shift));
}

/// Rotates an unsigned integer right by `amount` bits.
pub fn rotr<T: u>(x: T, amount: usize) -> T {
	let bits: T = @of.bits(T) cast T;
	let shift: T = (amount % (bits cast usize)) cast T;

	if shift == 0 {
		return x;
	}

	return (x >> shift) | (x << (bits - shift));
}
