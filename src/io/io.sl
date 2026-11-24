mod std.io;
import "std/err.sl";

/// Interface for reading bytes into a buffer.
pub trait Reader {
	/// Reads up to `capacity` bytes and returns the byte count or an error.
	fn read(self: *Self, buffer: *mut u8, capacity: usize) -> std.err.Result<usize, std.err.Code>;
}

/// Interface for writing bytes from a buffer.
pub trait Writer {
	/// Writes up to `length` bytes and returns the accepted byte count or an error.
	fn write(self: *mut Self, buffer: *u8, length: usize) -> std.err.Result<usize, std.err.Code>;
}

/// Origins accepted by `seek`.
pub enum SeekWhence: u8 {
	Start,
	Current,
	End
}

/// Interface for seeking within a byte stream.
pub trait Seeker {
	/// Changes the stream position and returns the resulting position or an error.
	fn seek(
		self: *Self,
		offset: i64,
		whence: SeekWhence
	) -> std.err.Result<u64, std.err.Code>;
}

/// Interface for resources that can be explicitly synchronized to persistent storage.
pub trait Sync {
	/// Flushes buffered data to persistent storage.
	fn sync(self: *Self) -> std.err.Code;
}

/// Interface for resources that must be explicitly closed.
pub trait Closer {
	/// Releases the resource represented by the handle.
	fn close(self: *mut Self) -> std.err.Code;
}

/// Copies all available bytes from any Reader into any Writer using a caller-provided buffer.
pub fn copy<R: Reader, W: Writer>(
	reader: *R,
	writer: *mut W,
	buffer: *mut u8,
	buffer_capacity: usize
) -> std.err.Result<usize, std.err.Code> {
	if reader == null || writer == null || buffer == null || buffer_capacity == 0 {
		return .Err(std.err.Code.InvalidArgument);
	}
	let mut total: usize = 0;
	for true {
		let mut bytes_read: usize = 0;
		let mut read_err: std.err.Code = std.err.Code.Success;
		match reader.read(buffer, buffer_capacity) {
			.Ok(n) => bytes_read = n,
			.Err(e) => read_err = e,
		}
		if read_err == std.err.Code.InterruptedSystemCall {
			continue;
		}
		if read_err != std.err.Code.Success {
			return .Err(read_err);
		}
		if bytes_read > buffer_capacity {
			return .Err(std.err.Code.InputOutputError);
		}
		if bytes_read == 0 {
			return .Ok(total);
		}
		let mut offset: usize = 0;
		for offset < bytes_read {
			let mut count: usize = 0;
			let mut write_err: std.err.Code = std.err.Code.Success;
			match writer.write(&buffer[offset], bytes_read - offset) {
				.Ok(n) => count = n,
				.Err(e) => write_err = e,
			}
			if write_err == std.err.Code.InterruptedSystemCall {
				continue;
			}
			if write_err != std.err.Code.Success {
				return .Err(write_err);
			}
			if count > bytes_read - offset || count == 0 {
				return .Err(std.err.Code.InputOutputError);
			}
			offset += count;
			total += count;
		}
	}
}

/// Reads repeatedly from any Reader until the buffer is full or end of file is reached.
pub fn read_all<R: Reader>(
	reader: *R,
	buffer: *mut u8,
	capacity: usize
) -> std.err.Result<usize, std.err.Code> {
	if reader == null || (capacity > 0 && buffer == null) {
		return .Err(std.err.Code.InvalidArgument);
	}
	let mut total: usize = 0;
	for total < capacity {
		let mut count: usize = 0;
		let mut read_err: std.err.Code = std.err.Code.Success;
		match reader.read(&buffer[total], capacity - total) {
			.Ok(n) => count = n,
			.Err(e) => read_err = e,
		}
		if read_err == std.err.Code.InterruptedSystemCall {
			continue;
		}
		if read_err != std.err.Code.Success {
			return .Err(read_err);
		}
		if count > capacity - total {
			return .Err(std.err.Code.InputOutputError);
		}
		total += count;
		if count == 0 {
			break;
		}
	}
	return .Ok(total);
}

/// Writes all requested bytes to any Writer, retrying short writes.
pub fn write_all<W: Writer>(writer: *mut W, buffer: *u8, length: usize) -> std.err.Code {
	if writer == null || (length > 0 && buffer == null) {
		return std.err.Code.InvalidArgument;
	}
	let mut total: usize = 0;
	for total < length {
		let mut count: usize = 0;
		let mut write_err: std.err.Code = std.err.Code.Success;
		match writer.write(&buffer[total], length - total) {
			.Ok(n) => count = n,
			.Err(e) => write_err = e,
		}
		if write_err == std.err.Code.InterruptedSystemCall {
			continue;
		}
		if write_err != std.err.Code.Success {
			return write_err;
		}
		if count > length - total || count == 0 {
			return std.err.Code.InputOutputError;
		}
		total += count;
	}
	return std.err.Code.Success;
}
