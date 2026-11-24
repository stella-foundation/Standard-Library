mod std.math.exp;
import "./abs.sl";
import "./is.sl";
import "./round.sl";
import "./sqrt.sl";

fn scale<T: f>(x: T, exponent: i32) -> T {
	return std.math.round.ldexp(x, exponent);
}

fn series<T: f>(x: T) -> T {
	let mut sum: T = 1;
	let mut term: T = 1;
	for let mut i: u32 = 1; i <= 32; i += 1 {
		term = term * x / i cast T;
		sum += term;
	}
	return sum;
}

/// Returns the exponential function evaluated at `x`.
pub fn exp<T: f>(x: T) -> T {
	if x != x {
		return x;
	}
	let zero: T = 0 cast T;
	if std.math.is.inf(x) {
		return x < zero ? zero : x;
	}
	if x == zero {
		return 1 cast T;
	}
	if x > (710 cast T) {
		return (1 cast T) / (x - x);
	}
	if x < (-746 cast T) {
		return zero;
	}
	let n: T = std.math.round.floor(x / log(2 cast T));
	let r: T = x - n * log(2 cast T);
	return scale(series(r), n cast i32);
}

/// Returns two raised to the power `x`.
pub fn exp2<T: f>(x: T) -> T {
	return exp(x * log(2 cast T));
}

/// Returns the exponential of `x` minus one with improved small-value precision.
pub fn expm1<T: f>(x: T) -> T {
	if x != x {
		return x;
	}
	if x == x - x {
		return x;
	}
	if std.math.is.inf(x) {
		return std.math.is.signbit(x) ? -(1 cast T) : x;
	}
	// Keep the Taylor path through a range where `exp(x) - 1` would lose the
	// low-order bits, especially for f16 where the unit roundoff is much larger.
	if std.math.abs(x) < (0.5 cast T) {
		let mut term: T = x;
		let mut sum: T = x;
		for let mut i: u32 = 2; i <= 32; i += 1 {
			term = term * x / (i cast T);
			sum += term;
		}
		return sum;
	}
	return exp(x) - (1 cast T);
}

/// Returns the real cube root of `x`.
pub fn cbrt<T: f>(x: T) -> T {
	if x != x || std.math.is.inf(x) || x == x - x {
		return x;
	}
	let negative: bool = std.math.is.signbit(x);
	let value: T = std.math.abs(x);
	let mut guess: T = exp(log(value) / (3 cast T));
	for let mut i: u32 = 0; i < 24; i += 1 {
		let next: T = ((2 cast T) * guess + value / (guess * guess)) / (3 cast T);
		if next == guess {
			break;
		}
		guess = next;
	}
	return negative ? -guess : guess;
}

/// Returns the length of the vector with components `x` and `y`.
pub fn hypot<T: f>(x: T, y: T) -> T {
	if std.math.is.inf(x) || std.math.is.inf(y) {
		return (1 cast T) / (0 cast T);
	}
	if x != x || y != y {
		return (x - x) / (x - x);
	}
	let ax: T = std.math.abs(x);
	let ay: T = std.math.abs(y);
	let larger: T = ax > ay ? ax : ay;
	let smaller: T = ax > ay ? ay : ax;
	if larger == smaller - smaller {
		return larger;
	}
	let ratio: T = smaller / larger;
	return larger * std.math.sqrt((1 cast T) + ratio * ratio);
}

fn log_atanh<T: f>(z: T) -> T {
	let z2: T = z * z;
	let mut term: T = z;
	let mut sum: T = z;
	for let mut i: u32 = 3; i <= 99; i += 2 {
		term *= z2;
		sum += term / (i cast T);
	}
	return 2 * sum;
}

/// Returns the natural logarithm of `x`.
pub fn log<T: f>(x: T) -> T {
	if x != x {
		return x;
	}
	let zero: T = x - x;
	if x == zero {
		return -(1 cast T) / (x - x);
	}
	if x < zero {
		return (x - x) / (x - x);
	}
	if std.math.is.inf(x) {
		return x;
	}
	let mut value: T = x;
	let mut e: i32 = 0;
	for let mut i: u32 = 0; i < 2048; i += 1 {
		if value >= 2 {
			value *= 0.5;
			e += 1;
		} else if value < (1 cast T) {
			value *= 2;
			e -= 1;
		} else {
			break;
		}
	}
	// Center the mantissa around one. Keeping it below sqrt(2) avoids
	// subtracting log(2) from a nearly equal logarithm for inputs just below 1.
	if value > (1.414213562373095048801688724209698079 cast T) {
		value *= 0.5;
		e += 1;
	}
	// The logarithm of two is the reduction constant for this algorithm.
	// Handle it directly so the correction below does not recurse forever.
	if x == 2 {
		return log_atanh((1 cast T) / (3 cast T));
	}
	let z: T = (value - 1) / (value + 1);
	return log_atanh(z) + (e cast T) * log(2 cast T);
}

/// Returns the base-two logarithm of `x`.
pub fn log2<T: f>(x: T) -> T {
	return log(x) / log(2 cast T);
}

/// Returns the base-ten logarithm of `x`.
pub fn log10<T: f>(x: T) -> T {
	return log(x) / log(10 cast T);
}

/// Returns the natural logarithm of one plus `x` with improved small-value precision.
pub fn log1p<T: f>(x: T) -> T {
	let one_value: T = 1 cast T;
	if x != x {
		return x;
	}
	if x == -one_value {
		return -(1 cast T) / (x - x);
	}
	if x < -one_value {
		return (x - x) / (x - x);
	}
	if std.math.abs(x) < (0.5 cast T) {
		let z: T = x / (2 cast T + x);
		return log_atanh(z);
	}
	return log(one_value + x);
}
