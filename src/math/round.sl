mod std.math.round;
import "./abs.sl";
import "./is.sl";

fn power_of_two<T: f>(exponent: i32) -> T {
	let mut result: T = 1 cast T;
	if exponent >= 0 {
		for let mut i: i32 = 0; i < exponent; i += 1 {
			result *= 2 cast T;
		}
	} else {
		for let mut i: i32 = 0; i > exponent; i -= 1 {
			result *= 0.5 cast T;
		}
	}
	return result;
}

/// Scales `x` by a power of two using the supplied exponent.
pub fn ldexp<T: f>(x: T, exponent: i32) -> T {
	if x != x || std.math.is.inf(x) || x == x - x {
		return x;
	}
	let mut input_exponent: i32 = 0;
	let significand: T = frexp(x, &input_exponent);
	let target_exponent: i64 = (input_exponent cast i64) + (exponent cast i64);
	let mut minimum_normal_exponent: i32 = -1022;
	let mut maximum_exponent: i32 = 1023;
	if @of.bits(T) == 16 {
		minimum_normal_exponent = -14;
		maximum_exponent = 15;
	} else if @of.bits(T) == 32 {
		minimum_normal_exponent = -126;
		maximum_exponent = 127;
	}
	if target_exponent > (maximum_exponent + 1) cast i64 {
		let infinity: T = (1 cast T) / (0 cast T);
		return std.math.is.signbit(x) ? -infinity : infinity;
	}
	let minimum_subnormal_exponent: i64 =
	(minimum_normal_exponent - (@of.bits(T) == 16 ? 10 : @of.bits(T) == 32 ? 23 : 52)) cast i64;
	if target_exponent < minimum_subnormal_exponent {
		let zero: T = 0 cast T;
		return std.math.is.signbit(x) ? -zero : zero;
	}
	if target_exponent <= minimum_normal_exponent cast i64 {
		let scale_exponent: i32 =
		(target_exponent - (minimum_normal_exponent cast i64)) cast i32;
		let scale_factor: T = power_of_two<T>(scale_exponent);
		let minimum_normal: T = power_of_two<T>(minimum_normal_exponent);
		return (significand * scale_factor) * minimum_normal;
	}
	let scale_exponent: i32 = (target_exponent - 1) cast i32;
	return (significand * (2 cast T)) * power_of_two<T>(scale_exponent);
}

/// Splits `x` into a fraction and exponent and stores the exponent in `exponent`.
pub fn frexp<T: f>(x: T, exponent: *mut i32) -> T {
	if exponent == null {
		return x;
	}
	if x != x || std.math.is.inf(x) || x == x - x {
		exponent[0] = 0;
		return x;
	}
	let negative: bool = std.math.is.signbit(x);
	let mut value: T = std.math.abs(x);
	let mut e: i32 = 0;
	for let mut i: u32 = 0; i < 2048; i += 1 {
		if value >= (1 cast T) {
			value *= (0.5 cast T);
			e += 1;
		} else if value < (0.5 cast T) {
			value *= 2;
			e -= 1;
		} else {
			break;
		}
	}
	exponent[0] = e;
	return negative ? -value : value;
}

/// Returns `x` with its fractional part removed toward zero.
pub fn trunc<T: f>(x: T) -> T {
	if x != x || std.math.is.inf(x) || x == x - x {
		return x;
	}
	let limit: T = 9.223372036854774784e18 cast T;
	if x >= limit || x <= -limit {
		return x;
	}
	let i: i64 = x cast i64;
	let result: T = i cast T;
	if result == x - x && std.math.is.signbit(x) {
		return -(x - x);
	}
	return result;
}

/// Returns the greatest integer value that is not greater than `x`.
pub fn floor<T: f>(x: T) -> T {
	if x != x || std.math.is.inf(x) || x == x - x {
		return x;
	}
	let t: T = trunc(x);
	if t > x {
		return t - (1 cast T);
	}
	return t;
}

/// Returns the least integer value that is not less than `x`.
pub fn ceil<T: f>(x: T) -> T {
	if x != x || std.math.is.inf(x) || x == x - x {
		return x;
	}
	let t: T = trunc(x);
	if t < x {
		return t + (1 cast T);
	}
	if t == x - x && std.math.is.signbit(x) {
		return -(x - x);
	}
	return t;
}

/// Rounds `x` to the nearest integer value.
pub fn round<T: f>(x: T) -> T {
	if x != x || std.math.is.inf(x) || x == x - x {
		return x;
	}
	let integral: T = trunc(x);
	if std.math.abs(x - integral) < (0.5 cast T) {
		return integral;
	}
	return std.math.is.signbit(x) ? integral - (1 cast T) : integral + (1 cast T);
}
