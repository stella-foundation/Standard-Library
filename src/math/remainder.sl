mod std.math.remainder;
import "./abs.sl";
import "./is.sl";
import "./round.sl";

fn fmod_with_quotient_parity<T: f>(x: T, y: T, quotient_odd: *mut bool) -> T {
	if quotient_odd != null {
		quotient_odd[0] = false;
	}
	if x != x || y != y || std.math.is.inf(x) || y == 0 {
		let zero: T = x - x;
		return zero / zero;
	}
	if x == 0 || std.math.is.inf(y) {
		return x;
	}
	let mut ax: T = std.math.abs(x);
	let ay: T = std.math.abs(y);
	for ax >= ay {
		let mut ax_exponent: i32;
		let mut ay_exponent: i32;
		std.math.round.frexp(ax, &ax_exponent);
		std.math.round.frexp(ay, &ay_exponent);
		let mut scale_exponent: i32 = ax_exponent - ay_exponent;
		let mut scale: T = std.math.round.ldexp(ay, scale_exponent);
		if scale > ax {
			scale_exponent -= 1;
			scale = std.math.round.ldexp(ay, scale_exponent);
		}
		if scale == 0 {
			break;
		}
		ax -= scale;
		// Each subtraction removes one set bit from the truncated quotient;
		// only the unit bit affects whether it is even or odd.
		if scale_exponent == 0 && quotient_odd != null {
			quotient_odd[0] = !quotient_odd[0];
		}
	}
	return std.math.is.signbit(x) ? -ax : ax;
}

/// Returns the floating-point remainder of `x` divided by `y`.
pub fn fmod<T: f>(x: T, y: T) -> T {
	return fmod_with_quotient_parity(x, y, null);
}

/// Returns the IEEE remainder of `x` divided by `y`.
pub fn remainder<T: f>(x: T, y: T) -> T {
	let mut quotient_odd: bool = false;
	let r: T = fmod_with_quotient_parity(x, y, &quotient_odd);
	if r != r {
		return r;
	}
	if x == 0 || std.math.is.inf(y) {
		return r;
	}
	let abs_r: T = std.math.abs(r);
	let abs_y: T = std.math.abs(y);
	// Doubling the remainder is exact in binary floating point. This avoids
	// rounding or underflow in y/2 for subnormal divisors; overflow means the
	// doubled remainder is necessarily larger than finite y.
	let twice_r: T = abs_r + abs_r;
	if std.math.is.inf(twice_r) || twice_r > abs_y {
		return r - std.math.copysign(abs_y, r);
	}
	if twice_r == abs_y && quotient_odd {
		return r - std.math.copysign(std.math.abs(y), r);
	}
	return r;
}
