mod std.math.is;

/// Reports whether an arithmetic value is NaN.
pub fn nan<T: f>(x: T) -> bool {
	return x != x;
}

/// Reports whether an arithmetic value is positive or negative infinity.
pub fn inf<T: f>(x: T) -> bool {
	let zero: T = x - x;
	if x == x && x != zero {
		let quotient: T = x / x;
		return quotient != quotient;
	}
	return false;
}

/// Reports whether `x` is finite.
pub fn finite<T: f>(x: T) -> bool {
	return x == x && !inf(x);
}

/// Reports whether `x` is either positive or negative zero.
pub fn zero<T: f>(x: T) -> bool {
	return x == x - x;
}

/// Reports the IEEE sign bit, including the sign of zero and NaN.
pub fn signbit(x: f16) -> bool {
	let bits: u16 = x bitcast u16;
	return (bits & (0x8000 cast u16)) != 0;
}

/// Reports whether the sign bit of `x` is set, including for zero and NaN.
pub fn signbit(x: f32) -> bool {
	let bits: u32 = x bitcast u32;
	return (bits & (0x80000000 cast u32)) != 0;
}

/// Reports whether the sign bit of `x` is set, including for zero and NaN.
pub fn signbit(x: f64) -> bool {
	let bits: u64 = x bitcast u64;
	return (bits & (0x8000000000000000 cast u64)) != 0;
}

/// Reports whether `x` is a finite non-zero normal value.
pub fn normal<T: f>(x: T) -> bool {
	if !finite(x) || zero(x) {
		return false;
	}
	let a: T = x < x - x ? -x : x;
	let mut minimum: T;
	if @of.bits(T) == 16 {
		minimum = 6.103515625e-5 cast T;
	} else if @of.bits(T) == 32 {
		minimum = 1.1754943508222875e-38 cast T;
	} else {
		minimum = 2.2250738585072014e-308 cast T;
	}
	return a >= minimum;
}

/// Reports whether `x` is a finite non-zero subnormal value.
pub fn subnormal<T: f>(x: T) -> bool {
	if !finite(x) || zero(x) {
		return false;
	}
	let a: T = x < x - x ? -x : x;
	let mut minimum: T;
	if @of.bits(T) == 16 {
		minimum = 6.103515625e-5 cast T;
	} else if @of.bits(T) == 32 {
		minimum = 1.1754943508222875e-38 cast T;
	} else {
		minimum = 2.2250738585072014e-308 cast T;
	}
	return a < minimum;
}

/// Reports whether neither operand is NaN (an ordered comparison domain).
pub fn ordered<T: f>(x: T, y: T) -> bool {
	return x == x && y == y;
}

/// Reports whether at least one operand is NaN.
pub fn unordered<T: f>(x: T, y: T) -> bool {
	return x != x || y != y;
}
