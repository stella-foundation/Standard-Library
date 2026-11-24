mod std.debug;
import "std/io/out.sl";
import "std/proc.sl";

fn __assert(expr: []u8, file: []u8, line: u32, func: []u8) -> void {
	std.io.eprintf("Assertion failed: {} ({}: {}: {})\n", expr, file, func, line);
	std.proc.abort();
}

pub macro assert(condition: bool) {
	if #DEBUG && !condition {
		__assert(@syn.stringify(condition), @src.file, @src.line, @src.func);
	}
}
