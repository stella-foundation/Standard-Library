mod std.math.sort;
pub import "./sort/low_mem.sl";

/// Interface for totally ordered types.
pub trait Ord {
	/// Compares two values, returning a negative, zero, or positive result.
	fn cmp(self: *Self, other: *Self) -> i32;
}
