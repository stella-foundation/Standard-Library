mod std.net;

/// An IPv4 address and transport port in host byte order.
pub struct Ipv4Address {
	/// First IPv4 address octet in host order.
	pub a: u8,
	/// Second IPv4 address octet in host order.
	pub b: u8,
	/// Third IPv4 address octet in host order.
	pub c: u8,
	/// Fourth IPv4 address octet in host order.
	pub d: u8,
	/// Transport port in host byte order.
	pub port: u16
}

/// Constructs an IPv4 address and port.
pub fn ipv4(a: u8, b: u8, c: u8, d: u8, port: u16) -> Ipv4Address {
	let mut address: Ipv4Address;
	address.a = a;
	address.b = b;
	address.c = c;
	address.d = d;
	address.port = port;
	return address;
}

/// Constructs the IPv4 loopback endpoint `127.0.0.1:port`.
pub fn loopback(port: u16) -> Ipv4Address {
	return ipv4(127, 0, 0, 1, port);
}

/// Constructs the wildcard IPv4 endpoint `0.0.0.0:port`.
pub fn any(port: u16) -> Ipv4Address {
	return ipv4(0, 0, 0, 0, port);
}
