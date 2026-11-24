mod std.math.hyper;
import "./abs.sl";
import "./exp.sl";
import "./is.sl";
import "./sqrt.sl";

/// Returns the hyperbolic sine of `x`.
pub fn sinh<T: f>(x: T) -> T {
	if x != x || std.math.is.inf(x) {
		return x;
	}
	if std.math.abs(x) < (0.5 cast T) {
		return (std.math.exp.expm1(x) - std.math.exp.expm1(-x)) * 0.5;
	}
	return (std.math.exp.exp(x) - std.math.exp.exp(-x)) * 0.5;
}

/// Returns the hyperbolic cosine of `x`.
pub fn cosh<T: f>(x: T) -> T {
	if x != x {
		return x;
	}
	if std.math.is.inf(x) {
		return (1 cast T) / (0 cast T);
	}
	return (std.math.exp.exp(x) + std.math.exp.exp(-x)) * 0.5;
}

/// Returns the hyperbolic tangent of `x`.
pub fn tanh<T: f>(x: T) -> T {
	if x != x {
		return x;
	}
	if std.math.is.inf(x) {
		return std.math.is.signbit(x) ? -(1 cast T) : (1 cast T);
	}
	let e_minus_one: T = std.math.exp.expm1(2 * std.math.abs(x));
	if std.math.is.inf(e_minus_one) {
		return std.math.is.signbit(x) ? -(1 cast T) : (1 cast T);
	}
	let value: T = e_minus_one / (e_minus_one + (2 cast T));
	return std.math.is.signbit(x) ? -value : value;
}

/// Returns the inverse hyperbolic sine of `x`.
pub fn asinh<T: f>(x: T) -> T {
	if x != x || std.math.is.inf(x) {
		return x;
	}
	let magnitude: T = std.math.abs(x);
	if magnitude != (x - x) && magnitude * (0.5 cast T) == (x - x) {
		return x;
	}
	let mut result: T;
	if magnitude > (1 cast T) {
		result = std.math.exp.log(magnitude)
			+ std.math.exp.log(
			(1 cast T) + std.math.sqrt((1 cast T) + (1 cast T) / (magnitude * magnitude))
		);
	} else {
		let square: T = magnitude * magnitude;
		let root: T = std.math.sqrt((1 cast T) + square);
		let correction: T = square / (root + (1 cast T));
		result = std.math.exp.log1p(magnitude + correction);
	}
	return std.math.is.signbit(x) ? -result : result;
}

/// Returns the inverse hyperbolic cosine of `x`.
pub fn acosh<T: f>(x: T) -> T {
	if x != x {
		return x;
	}
	if std.math.is.inf(x) {
		if std.math.is.signbit(x) {
			return (x - x) / (x - x);
		}
		return x;
	}
	if x < (1 cast T) {
		return (x - x) / (x - x);
	}
	let delta: T = x - (1 cast T);
	if delta < (0.5 cast T) {
		return std.math.exp.log1p(delta + std.math.sqrt(delta * (x + (1 cast T))));
	}
	let square: T = x * x;
	if std.math.is.inf(square) {
		return std.math.exp.log(x) + std.math.exp.log(2 cast T);
	}
	return std.math.exp.log(x + std.math.sqrt(square - (1 cast T)));
}

/// Returns the inverse hyperbolic tangent of `x`.
pub fn atanh<T: f>(x: T) -> T {
	if x != x {
		return x;
	}
	if x == (1 cast T) {
		return (1 cast T) / (x - x);
	}
	if x == (-1 cast T) {
		return -(1 cast T) / (x - x);
	}
	if x > (1 cast T) || x < (-1 cast T) {
		return (x - x) / (x - x);
	}
	if std.math.abs(x) * (0.5 cast T) == (x - x) {
		return x;
	}
	return (std.math.exp.log1p(x) - std.math.exp.log1p(-x)) * (0.5 cast T);
}
