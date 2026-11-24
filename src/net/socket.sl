mod std.net;
import "./endpoint.sl";
import "std/arch/net.sl";
import "std/err.sl";
import "std/io/io.sl";

/// Supported transport socket families.
pub enum SocketKind: u8 {
	Tcp = 1,
	Udp = 2
}

/// Managed network socket wrapping an OS descriptor.
pub struct Socket {
	/// Native socket handle owned by this value.
	pub handle: isize
}

impl std.io.Reader for Socket {
	/// Reads bytes from the socket and returns the number received or an error.
	pub fn read(self: *Self, buffer: *mut u8, capacity: usize) -> std.err.Result<usize, std.err.Code> {
		if self.handle < 0 {
			return .Err(std.err.Code.BadFileDescriptor);
		}
		if capacity > 0 && buffer == null {
			return .Err(std.err.Code.InvalidArgument);
		}
		if capacity == 0 {
			return .Ok(0);
		}
		let res: isize = std.arch.net.receive(self.handle, buffer, capacity);
		if res < 0 {
			let code_val: isize = -res;
			return .Err((code_val cast u8) cast std.err.Code);
		}
		return .Ok(res cast usize);
	}
}

impl std.io.Writer for Socket {
	/// Writes bytes to the socket and returns the number sent or an error.
	pub fn write(self: *mut Self, buffer: *u8, length: usize) -> std.err.Result<usize, std.err.Code> {
		if self.handle < 0 {
			return .Err(std.err.Code.BadFileDescriptor);
		}
		if length > 0 && buffer == null {
			return .Err(std.err.Code.InvalidArgument);
		}
		if length == 0 {
			return .Ok(0);
		}
		let res: isize = std.arch.net.send(self.handle, buffer, length);
		if res < 0 {
			let code_val: isize = -res;
			return .Err((code_val cast u8) cast std.err.Code);
		}
		return .Ok(res cast usize);
	}
}

impl std.io.Closer for Socket {
	/// Closes the socket and marks its handle as closed on success.
	pub fn close(self: *mut Self) -> std.err.Code {
		if self.handle < 0 {
			return std.err.Code.BadFileDescriptor;
		}
		let res: isize = std.arch.net.close(self.handle);
		self.handle = -1;
		if res < 0 {
			let code_val: isize = -res;
			return (code_val cast u8) cast std.err.Code;
		}
		return std.err.Code.Success;
	}
}

/// Creates a socket for the requested transport protocol.
pub fn create(kind: SocketKind) -> std.err.Result<Socket, std.err.Code> {
	let mut handle: isize = -(std.err.Code.InvalidArgument cast isize);
	if kind == SocketKind.Tcp {
		handle = std.arch.net.socket(1);
	} else if kind == SocketKind.Udp {
		handle = std.arch.net.socket(2);
	}
	if handle < 0 {
		let code_val: isize = -handle;
		return .Err((code_val cast u8) cast std.err.Code);
	}
	return .Ok({ .handle = handle });
}

/// Binds a socket to an IPv4 endpoint.
pub fn bind(sock: *Socket, address: Ipv4Address) -> std.err.Code {
	if sock == null || sock.handle < 0 {
		return std.err.Code.BadFileDescriptor;
	}
	let res: isize = std.arch.net.bind(
		sock.handle,
		address.a,
		address.b,
		address.c,
		address.d,
		address.port
	);
	if res < 0 {
		let code_val: isize = -res;
		return (code_val cast u8) cast std.err.Code;
	}
	return std.err.Code.Success;
}

/// Marks a bound socket as listening with the requested backlog.
pub fn listen(sock: *Socket, backlog: i32) -> std.err.Code {
	if sock == null || sock.handle < 0 {
		return std.err.Code.BadFileDescriptor;
	}
	let res: isize = std.arch.net.listen(sock.handle, backlog);
	if res < 0 {
		let code_val: isize = -res;
		return (code_val cast u8) cast std.err.Code;
	}
	return std.err.Code.Success;
}

/// Accepts a connection and optionally writes its peer address.
pub fn accept(sock: *Socket, address_out: *mut Ipv4Address) -> std.err.Result<Socket, std.err.Code> {
	if sock == null || sock.handle < 0 {
		return .Err(std.err.Code.BadFileDescriptor);
	}
	let mut handle: isize = 0;
	if address_out == null {
		handle = std.arch.net.accept(sock.handle, null, null, null, null, null);
	} else {
		handle = std.arch.net.accept(
			sock.handle,
			&address_out.a,
			&address_out.b,
			&address_out.c,
			&address_out.d,
			&address_out.port
		);
	}
	if handle < 0 {
		let code_val: isize = -handle;
		return .Err((code_val cast u8) cast std.err.Code);
	}
	return .Ok({ .handle = handle });
}

/// Connects a socket to an IPv4 endpoint.
pub fn connect(sock: *Socket, address: Ipv4Address) -> std.err.Code {
	if sock == null || sock.handle < 0 {
		return std.err.Code.BadFileDescriptor;
	}
	let res: isize = std.arch.net.connect(
		sock.handle,
		address.a,
		address.b,
		address.c,
		address.d,
		address.port
	);
	if res < 0 {
		let code_val: isize = -res;
		return (code_val cast u8) cast std.err.Code;
	}
	return std.err.Code.Success;
}

/// Sends bytes over a connected stream socket.
pub fn send(sock: *Socket, buffer: *u8, length: usize) -> isize {
	return std.arch.net.send(sock.handle, buffer, length);
}

/// Receives bytes from a connected stream socket.
pub fn receive(sock: *Socket, buffer: *mut u8, length: usize) -> isize {
	return std.arch.net.receive(sock.handle, buffer, length);
}

/// Sends bytes to an explicit IPv4 destination endpoint.
pub fn send_to(sock: *Socket, buffer: *u8, length: usize, address: Ipv4Address) -> isize {
	return std.arch.net.send_to(
		sock.handle,
		buffer,
		length,
		address.a,
		address.b,
		address.c,
		address.d,
		address.port
	);
}

/// Receives bytes and peer endpoint from a datagram socket.
pub fn receive_from(
	sock: *Socket,
	buffer: *mut u8,
	length: usize,
	address_out: *mut Ipv4Address
) -> isize {
	if address_out == null {
		return std.arch.net.receive_from(sock.handle, buffer, length, null, null, null, null, null);
	}
	return std.arch.net.receive_from(
		sock.handle,
		buffer,
		length,
		&address_out.a,
		&address_out.b,
		&address_out.c,
		&address_out.d,
		&address_out.port
	);
}
