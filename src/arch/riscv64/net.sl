mod std.arch.net;
import "./code.sl";
import "std/err.sl";

fn init_address(raw: *mut u8, a: u8, b: u8, c: u8, d: u8, port: u16) -> void {
	raw[0] = 2;
	raw[1] = 0;
	raw[2] = (port >> 8) cast u8;
	raw[3] = port cast u8;
	raw[4] = a;
	raw[5] = b;
	raw[6] = c;
	raw[7] = d;
	raw[8] = 0;
	raw[9] = 0;
	raw[10] = 0;
	raw[11] = 0;
	raw[12] = 0;
	raw[13] = 0;
	raw[14] = 0;
	raw[15] = 0;
}

fn read_address(raw: *u8, a: *mut u8, b: *mut u8, c: *mut u8, d: *mut u8, port: *mut u16) -> void {
	if a != null {
		a[0] = raw[4];
	}
	if b != null {
		b[0] = raw[5];
	}
	if c != null {
		c[0] = raw[6];
	}
	if d != null {
		d[0] = raw[7];
	}
	if port != null {
		port[0] = ((raw[2] cast u16) << 8) | (raw[3] cast u16);
	}
}

fn normalize_result(result: isize) -> isize {
	if result >= 0 {
		return result;
	}

	let native_value: isize = -result;
	if native_value > 255 {
		return -(std.err.Code.Unknown cast isize);
	}

	let native_code: std.arch.err.Code =
	(native_value cast u8) cast std.arch.err.Code;
	let portable_code: std.err.Code =
	std.arch.err.to_portable_code(native_code);
	if portable_code == std.err.Code.Unknown {
		return -(std.err.Code.Unknown cast isize);
	}
	return -(portable_code cast isize);
}

/// Creates a Linux IPv4 socket.
pub fn socket(kind: u32) -> isize {
	let mut ret: isize = 0;
	asm volatile {
		"ecall"
		: "=a0" (ret)
		: "{a7}" (198), "{a0}" (2), "{a1}" (kind cast usize), "{a2}" (0)
		: "memory"
	};
	return normalize_result(ret);
}

/// Binds a Linux socket to an IPv4 address and port.
pub fn bind(socket: isize, a: u8, b: u8, c: u8, d: u8, port: u16) -> isize {
	let mut raw: [16]u8;
	init_address(&raw[0], a, b, c, d, port);
	let mut ret: isize = 0;
	asm volatile {
		"ecall"
		: "=a0" (ret)
		: "{a7}" (200), "{a0}" (socket), "{a1}" (&raw[0]),
		"{a2}" (16)
		: "memory"
	};
	return normalize_result(ret);
}

/// Marks a Linux socket as listening.
pub fn listen(socket: isize, backlog: i32) -> isize {
	let mut ret: isize = 0;
	asm volatile {
		"ecall"
		: "=a0" (ret)
		: "{a7}" (201), "{a0}" (socket), "{a1}" (backlog cast usize)
		: "memory"
	};
	return normalize_result(ret);
}

/// Accepts a connection on a Linux socket.
pub fn accept(socket: isize, a: *mut u8, b: *mut u8, c: *mut u8, d: *mut u8, port: *mut u16) -> isize {
	let mut raw: [16]u8;
	let mut len: u32 = 16;
	let mut ret: isize = 0;
	asm volatile {
		"ecall"
		: "=a0" (ret)
		: "{a7}" (202), "{a0}" (socket), "{a1}" (&raw[0]),
		"{a2}" (&len)
		: "memory"
	};
	if ret >= 0 {
		read_address(&raw[0], a, b, c, d, port);
	}
	return normalize_result(ret);
}

/// Connects a Linux socket to an IPv4 endpoint.
pub fn connect(socket: isize, a: u8, b: u8, c: u8, d: u8, port: u16) -> isize {
	let mut raw: [16]u8;
	init_address(&raw[0], a, b, c, d, port);
	let mut ret: isize = 0;
	asm volatile {
		"ecall"
		: "=a0" (ret)
		: "{a7}" (203), "{a0}" (socket), "{a1}" (&raw[0]),
		"{a2}" (16)
		: "memory"
	};
	return normalize_result(ret);
}

/// Sends bytes over a Linux socket.
pub fn send(socket: isize, buffer: *u8, length: usize) -> isize {
	let mut ret: isize = 0;
	asm volatile {
		"ecall"
		: "=a0" (ret)
		: "{a7}" (206), "{a0}" (socket), "{a1}" (buffer),
		"{a2}" (length), "{a3}" (0), "{a4}" (null), "{a5}" (0)
		: "memory"
	};
	return normalize_result(ret);
}

/// Receives bytes from a Linux socket.
pub fn receive(socket: isize, buffer: *mut u8, length: usize) -> isize {
	let mut ret: isize = 0;
	asm volatile {
		"ecall"
		: "=a0" (ret)
		: "{a7}" (207), "{a0}" (socket), "{a1}" (buffer),
		"{a2}" (length), "{a3}" (0), "{a4}" (null), "{a5}" (null)
		: "memory"
	};
	return normalize_result(ret);
}

/// Sends bytes to an IPv4 destination endpoint.
pub fn send_to(
	socket: isize,
	buffer: *u8,
	length: usize,
	a: u8,
	b: u8,
	c: u8,
	d: u8,
	port: u16
) -> isize {
	let mut raw: [16]u8;
	init_address(&raw[0], a, b, c, d, port);
	let mut ret: isize = 0;
	asm volatile {
		"ecall"
		: "=a0" (ret)
		: "{a7}" (206), "{a0}" (socket), "{a1}" (buffer),
		"{a2}" (length), "{a3}" (0), "{a4}" (&raw[0]), "{a5}" (16)
		: "memory"
	};
	return normalize_result(ret);
}

/// Receives bytes and peer address from a Linux socket.
pub fn receive_from(
	socket: isize,
	buffer: *mut u8,
	length: usize,
	a: *mut u8,
	b: *mut u8,
	c: *mut u8,
	d: *mut u8,
	port: *mut u16
) -> isize {
	let mut raw: [16]u8;
	let mut raw_length: u32 = 16;
	let mut ret: isize = 0;
	asm volatile {
		"ecall"
		: "=a0" (ret)
		: "{a7}" (207), "{a0}" (socket), "{a1}" (buffer),
		"{a2}" (length), "{a3}" (0), "{a4}" (&raw[0]),
		"{a5}" (&raw_length)
		: "memory"
	};
	if ret >= 0 {
		read_address(&raw[0], a, b, c, d, port);
	}
	return normalize_result(ret);
}

/// Closes a Linux socket.
pub fn close(socket: isize) -> isize {
	let mut ret: isize = 0;
	asm volatile {
		"ecall"
		: "=a0" (ret)
		: "{a7}" (57), "{a0}" (socket)
		: "memory"
	};
	return normalize_result(ret);
}
