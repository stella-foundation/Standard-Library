mod std.math.trig;
import "./abs.sl";
import "./is.sl";
import "./num.sl";
import "./sqrt.sl";

fn reduce_period<T: f>(x: T, period: T) -> T {
	if x != x || std.math.is.inf(x) {
		return (x - x) / (x - x);
	}
	let negative: bool = std.math.is.signbit(x);
	let mut value: T = std.math.abs(x);
	let mut scale: T = period;
	for let mut i: u32 = 0; i < 1100; i += 1 {
		let next: T = scale + scale;
		if std.math.is.inf(next) || next > value {
			break;
		}
		scale = next;
	}
	for let mut i: u32 = 0; i < 1100; i += 1 {
		if value >= scale {
			value -= scale;
		}
		if scale <= period {
			break;
		}
		scale /= (2 cast T);
	}
	return negative ? -value : value;
}

fn sin_kernel<T: f>(x: T) -> T {
	let x2: T = x * x;
	let mut p: T = 0.0000000000000000000000386817017063068413 cast T;
	p = 0.0000000000000000000195729410633912626 cast T - x2 * p;
	p = 0.0000000000000000082206352466243295 cast T - x2 * p;
	p = 0.0000000000000028114572543455206 cast T - x2 * p;
	p = 0.000000000000764716373181981641 cast T - x2 * p;
	p = 0.000000000160590438368216133 cast T - x2 * p;
	p = 0.0000000250521083854417202 cast T - x2 * p;
	p = 0.00000275573192239858925 cast T - x2 * p;
	p = 0.000198412698412698413 cast T - x2 * p;
	p = 0.00833333333333333333333333333333333333 cast T - x2 * p;
	p = 0.166666666666666666666666666666666667 cast T - x2 * p;
	return x * ((1 cast T) - x2 * p);
}

fn cos_kernel<T: f>(x: T) -> T {
	let x2: T = x * x;
	let mut p: T = 0.000000000000000000000889679139245057408 cast T;
	p = 0.000000000000000000411031762331216484 cast T - x2 * p;
	p = 0.000000000000000156192069685862253 cast T - x2 * p;
	p = 0.0000000000000477947733238738525 cast T - x2 * p;
	p = 0.0000000000114707455977297245 cast T - x2 * p;
	p = 0.00000000208767569878681002 cast T - x2 * p;
	p = 0.000000275573192239858883 cast T - x2 * p;
	p = 0.0000248015873015873016 cast T - x2 * p;
	p = 0.00138888888888888888888888888888888888889 cast T - x2 * p;
	p = 0.0416666666666666666666666666666666667 cast T - x2 * p;
	return (1 cast T) - x2 * ((0.5 cast T) - x2 * p);
}

/// Returns the sine of `x`, measured in radians.
pub fn sin<T: f>(x: T) -> T {
	if x != x || std.math.is.inf(x) {
		return (x - x) / (x - x);
	}
	let p: f64 = std.math.num.PI;
	let mut r: f64 = reduce_period(x cast f64, p * 2.0);
	if r > p * 0.5 {
		r = p - r;
	}
	if r < -p * 0.5 {
		r = -p - r;
	}
	return sin_kernel(r cast T);
}

/// Returns the cosine of `x`, measured in radians.
pub fn cos<T: f>(x: T) -> T {
	if x != x || std.math.is.inf(x) {
		return (x - x) / (x - x);
	}
	let p: f64 = std.math.num.PI;
	let mut r: f64 = reduce_period(x cast f64, p * 2.0);
	let mut sign: f64 = 1.0;
	if r > p * 0.5 {
		r = p - r;
		sign = -sign;
	}
	if r < -p * 0.5 {
		r = -p - r;
		sign = -sign;
	}
	return (sign cast T) * cos_kernel(r cast T);
}

fn atan_small<T: f>(x: T) -> T {
	let x2: T = x * x;
	let mut term: T = x;
	let mut sum: T = x;

	for let mut i: u32 = 3; i <= 41; i += 2 {
		term *= x2;
		if (i / 2) % 2 == 0 {
			sum += term / (i cast T);
		} else {
			sum -= term / (i cast T);
		}
	}
	return sum;
}

/// Returns the inverse tangent of `x` in radians.
pub fn atan<T: f>(x: T) -> T {
	if x != x {
		return x;
	}
	if std.math.is.inf(x) {
		let half_pi: T = (std.math.num.PI cast T) * (0.5 cast T);
		return std.math.is.signbit(x) ? -half_pi : half_pi;
	}
	let a: T = std.math.abs(x);
	let mut result: T = 0;
	if a > (2.414213562373095048801688724209698079 cast T) {
		result = (std.math.num.PI cast T) * (0.5 cast T) - atan_small((1 cast T) / a);
	} else if a > (0.414213562373095048801688724209698079 cast T) {
		result = (std.math.num.PI cast T) * (0.25 cast T) - atan_small(
			((1 cast T) - a) / ((1 cast T) + a)
		);
	} else {
		result = atan_small(a);
	}
	return std.math.is.signbit(x) ? -result : result;
}

/// Returns the tangent of `x`, measured in radians.
pub fn tan<T: f>(x: T) -> T {
	let c: T = cos(x);
	let s: T = sin(x);
	if c == 0 {
		let z: T = (1 cast T) / (0 cast T);
		return std.math.is.signbit(s) ? -z : z;
	}
	return s / c;
}

/// Returns the inverse sine of `x` in radians.
pub fn asin<T: f>(x: T) -> T {
	if x != x || std.math.is.inf(x) {
		return (x - x) / (x - x);
	}
	if x > (1 cast T) || x < (-1 cast T) {
		return (x - x) / (x - x);
	}
	if x == (1 cast T) {
		return (std.math.num.PI cast T) * (0.5 cast T);
	}
	if x == (-1 cast T) {
		return -(std.math.num.PI cast T) * (0.5 cast T);
	}
	let root: T = std.math.sqrt(((1 cast T) - x) * ((1 cast T) + x));
	return atan2(x, root);
}

/// Returns the inverse cosine of `x` in radians.
pub fn acos<T: f>(x: T) -> T {
	if x != x || std.math.is.inf(x) || x > (1 cast T) || x < (-1 cast T) {
		return (x - x) / (x - x);
	}
	let root: T = std.math.sqrt(((1 cast T) - x) * ((1 cast T) + x));
	return atan2(root, x);
}

/// Returns the angle of the point `(x, y)` in radians.
pub fn atan2<T: f>(y: T, x: T) -> T {
	if y != y || x != x {
		return (y - y) / (y - y);
	}
	let z: T = 0;
	let p: T = std.math.num.PI cast T;
	if std.math.is.inf(y) && std.math.is.inf(x) {
		let quarter: T = p * (0.25 cast T);
		let three_quarter: T = p * (0.75 cast T);
		if x > z {
			return std.math.is.signbit(y) ? -quarter : quarter;
		}
		return std.math.is.signbit(y) ? -three_quarter : three_quarter;
	}
	if std.math.is.inf(y) {
		return std.math.is.signbit(y) ? -p * 0.5 : p * 0.5;
	}
	if std.math.is.inf(x) {
		if x > z {
			return std.math.copysign(z, y);
		}
		return std.math.is.signbit(y) ? -p : p;
	}
	if x > z {
		return atan(y / x);
	}
	if x < z {
		return std.math.is.signbit(y) ? atan(y / x) - p : atan(y / x) + p;
	}
	if y > z {
		return p * 0.5;
	}
	if y < z {
		return -p * 0.5;
	}
	if x == z && y == z {
		if std.math.is.signbit(x) {
			return std.math.is.signbit(y) ? -p : p;
		}
		return std.math.copysign(z, y);
	}
	return std.math.copysign(z, y);
}
