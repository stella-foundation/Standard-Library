mod std.math.comp;
import "./is.sl";

/// Returns the smaller of two comparable arithmetic values.
pub fn min<T: i | u>(x: T, y: T) -> T {
	return x < y ? x : y;
}

/// Returns the smaller of two comparable arithmetic values.
pub fn min<T: f>(x: T, y: T) -> T {
	if x != x {
		return y;
	}
	if y != y {
		return x;
	}
	if x == y {
		if x == x - x && y == y - y {
			if std.math.is.signbit(x) {
				return x;
			}
			return y;
		}
		return x;
	}
	return x < y ? x : y;
}

/// Returns the larger of two comparable arithmetic values.
pub fn max<T: i | u>(x: T, y: T) -> T {
	return x > y ? x : y;
}

/// Returns the larger of two comparable arithmetic values.
pub fn max<T: f>(x: T, y: T) -> T {
	if x != x {
		return y;
	}
	if y != y {
		return x;
	}
	if x == y {
		if x == x - x && y == y - y {
			if !std.math.is.signbit(x) {
				return x;
			}
			return y;
		}
		return x;
	}
	return x > y ? x : y;
}

/// Clamps `x` to the closed interval `[lo, hi]`.
pub fn clamp<T: i | u | f>(x: T, lo: T, hi: T) -> T {
	return max(lo, min(x, hi));
}
