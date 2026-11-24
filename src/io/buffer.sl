mod std.io;
import "./io.sl";
import "std/err.sl";

/// Storage capacity used by the buffered writer.
pub const BUFFER_CAPACITY: usize = 4096;

/// Caller-owned buffering around a borrowed writer. Error remains sticky until init.
pub struct Buffer<W: Writer> {
	data: [4096]u8,
	length: usize,
	destination: *mut W,
	/// Sticky writer error, cleared when the buffer is initialized.
	pub error: std.err.Code
}

impl<W: Writer> Buffer<W> {
	/// Initializes the buffered writer and records an invalid destination as an error.
	pub fn init(output: *mut Self, destination: *mut W) -> void {
		output.length = 0;
		output.destination = destination;
		output.error = destination == null ? std.err.Code.InvalidArgument : std.err.Code.Success;
	}

	/// Flushes pending bytes, preserving the underlying writer's error.
	pub fn flush(output: *mut Self) -> std.err.Code {
		if output == null {
			return std.err.Code.InvalidArgument;
		}
		if output.error != std.err.Code.Success {
			return output.error;
		}
		if output.length == 0 {
			return std.err.Code.Success;
		}
		output.error = write_all(output.destination, &output.data[0], output.length);
		output.length = 0;
		return output.error;
	}
}

impl<W: Writer> Writer for Buffer<W> {
	/// Buffers source bytes and returns how many bytes were accepted or an error.
	pub fn write(self: *mut Self, source: *u8, length: usize) -> std.err.Result<usize, std.err.Code> {
		if self == null {
			return .Err(std.err.Code.InvalidArgument);
		}
		if self.error != std.err.Code.Success {
			return .Err(self.error);
		}
		if length > 0 && source == null {
			return .Err(std.err.Code.InvalidArgument);
		}
		let mut offset: usize = 0;
		let capacity: usize = @of.size([4096]u8);
		for offset < length {
			if self.length == capacity {
				self.flush();
				if self.error != std.err.Code.Success {
					return .Err(self.error);
				}
			}
			// Bypass the array for a large write when there are no pending bytes.
			if self.length == 0 && length - offset >= capacity {
				for offset < length {
					let mut count: usize = 0;
					let mut write_err: std.err.Code = std.err.Code.Success;
					match self.destination.write(&source[offset], length - offset) {
						.Ok(n) => count = n,
						.Err(e) => write_err = e,
					}
					if write_err == std.err.Code.InterruptedSystemCall {
						continue;
					}
					if write_err != std.err.Code.Success {
						self.error = write_err;
						return .Err(write_err);
					}
					if count > length - offset || count == 0 {
						self.error = std.err.Code.InputOutputError;
						return .Err(self.error);
					}
					offset += count;
				}
				return .Ok(offset);
			}
			let available: usize = capacity - self.length;
			let chunk: usize = length - offset < available ? length - offset : available;
			for let mut i: usize = 0; i < chunk; i += 1 {
				self.data[self.length + i] = source[offset + i];
			}
			self.length += chunk;
			offset += chunk;
		}
		return .Ok(offset);
	}
}
