mod std.math;
import "./is.sl";
import "./round.sl";

/// Returns the non-negative square root. Domain errors produce NaN.
pub fn sqrt<T: f>(x: T) -> T {
	let zero: T = x - x;
	let one: T = 1 cast T;
	if x != x {
		return x;
	}
	if x == zero {
		return x;
	}
	if x < zero {
		return zero / zero;
	}
	if std.math.is.inf(x) {
		return x;
	}

	// Normalize first so subnormals and very large finite values converge in
	// the same small, bounded number of Newton steps.
	let mut exponent: i32;
	let mut mantissa: T = std.math.round.frexp(x, &exponent);
	if exponent % 2 != 0 {
		mantissa *= 2 cast T;
		exponent -= 1;
	}
	let mut guess: T = (mantissa + one) / (2 cast T);
	for let mut i: u32 = 0; i < 32; i += 1 {
		let next: T = (guess + mantissa / guess) / (2 cast T);
		if next == guess {
			return std.math.round.ldexp(next, exponent / 2);
		}
		guess = next;
	}
	return std.math.round.ldexp(guess, exponent / 2);
}
