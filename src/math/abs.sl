mod std.math;
import "./is.sl";

/// Returns the absolute value of an arithmetic value.
pub fn abs<T: i | f>(x: T) -> T {
	let zero: T = x - x;
	if x != x {
		return x;
	}
	if x < zero {
		let magnitude: T = -x;
		// The minimum signed integer has no positive counterpart in its type.
		// Saturate to the maximum instead of returning the still-negative wrapped
		// result.
		if magnitude < zero {
			return -(x + 1);
		}
		return magnitude;
	}
	// Canonicalize both signed zero spellings to +0.
	if x == zero {
		return zero;
	}
	return x;
}

/// Returns `x` with the sign of `y`.
pub fn copysign<T: f>(x: T, y: T) -> T {
	let mut magnitude: T = abs(x);
	// `abs` preserves a NaN input, so normalize its sign here as well as for
	// finite values before applying the requested sign.
	if std.math.is.signbit(magnitude) {
		magnitude = -magnitude;
	}
	if std.math.is.signbit(y) {
		return -magnitude;
	}
	return magnitude;
}
