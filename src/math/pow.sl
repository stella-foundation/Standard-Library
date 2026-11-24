mod std.math;
import "./abs.sl";
import "./exp.sl";
import "./is.sl";
import "./round.sl";

/// Raises an integer value to a non-negative integer power.
pub fn pow<T: i | u>(base: T, exponent: usize) -> T {
	let one: T = 1 cast T;
	let mut result: T = one;
	let mut b: T = base;
	let mut n: usize = exponent;
	for n != 0 {
		if n % 2 != 0 {
			result *= b;
		}
		n /= 2;
		if n != 0 {
			b *= b;
		}
	}
	return result;
}

fn odd_integer<T: f>(value: T) -> bool {
	if value != std.math.round.trunc(value) {
		return false;
	}
	let half: T = std.math.round.trunc(value * (0.5 cast T));
	return value - half * (2 cast T) != 0;
}

/// Raises a floating-point value to a floating-point power.
pub fn pow<T: f>(base: T, exponent: T) -> T {
	let zero: T = 0 cast T;
	let one: T = 1 cast T;
	if exponent == zero {
		return one;
	}
	if base == one {
		return one;
	}
	if exponent != exponent || base != base {
		return zero / zero;
	}
	if base == zero {
		if std.math.is.inf(exponent) {
			return exponent < zero ? one / zero : zero;
		}
		let negative_result: bool = std.math.is.signbit(base) && odd_integer(exponent);
		if exponent < zero {
			let infinity_value: T = one / zero;
			return negative_result ? -infinity_value : infinity_value;
		}
		if negative_result {
			return -zero;
		}
		return zero;
	}
	if std.math.is.inf(exponent) {
		let a: T = std.math.abs(base);
		if a == one {
			return one;
		}
		if (a > one && exponent > zero) || (a < one && exponent < zero) {
			return one / zero;
		}
		return zero;
	}
	if std.math.is.inf(base) {
		let negative_result: bool = std.math.is.signbit(base) && odd_integer(exponent);
		if exponent < zero {
			return negative_result ? -zero : zero;
		}
		let magnitude: T = std.math.abs(base);
		return negative_result ? -magnitude : magnitude;
	}
	if base < zero {
		let integral: T = std.math.round.trunc(exponent);
		if integral != exponent {
			return zero / zero;
		}
		let magnitude: T = std.math.exp.exp(exponent * std.math.exp.log(-base));
		return odd_integer(integral) ? -magnitude : magnitude;
	}
	return std.math.exp.exp(exponent * std.math.exp.log(base));
}
