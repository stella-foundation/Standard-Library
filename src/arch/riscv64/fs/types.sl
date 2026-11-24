mod std.arch.fs;
import "std/io/fs.sl";

/// Contains portable flags for opening files.
pub mod file {
	/// Mask selecting the access mode bits in a portable open flag value.
	pub const ACCESS_MASK: u32 = 3;
	/// Portable flag value selecting write-only access.
	pub const WRITE: u32 = 2;
	/// Portable flag value selecting both read and write access.
	pub const READ_WRITE: u32 = 3;
	/// Portable flag that creates the file if it does not exist.
	pub const CREATE: u32 = 4;
	/// Portable flag that fails if creation finds an existing file.
	pub const EXCLUSIVE: u32 = 8;
	/// Portable flag that truncates an opened file.
	pub const TRUNCATE: u32 = 16;
	/// Portable flag that appends writes to the end of a file.
	pub const APPEND: u32 = 32;
	/// Portable flag that prevents following a symbolic link.
	pub const NO_FOLLOW: u32 = 64;
}

/// Contains constants used by filesystem path operations.
pub mod path {
	/// Flag that makes path metadata calls inspect the link itself.
	pub const SYMLINK_NO_FOLLOW: u32 = 256;
	/// Capacity reserved for retrieving the current directory path.
	pub const CURRENT_DIRECTORY: usize = 4096;
}

/// Contains origins used when changing a file position.
pub mod seek_constants {
	/// Seek origin at the start of the file.
	pub const SET: u32 = 0;
	/// Seek origin at the current file position.
	pub const CURRENT: u32 = 1;
}

/// Contains byte offsets for fields in the Linux file status record.
pub mod stat_layout {
	/// Byte offset of the link count in the Linux file status record.
	pub const LINKS: usize = 16;
	/// Byte offset of the file type and permissions in the Linux status record.
	pub const MODE: usize = 24;
	/// Byte offset of the file size in the Linux status record.
	pub const SIZE: usize = 48;
	/// Byte offset of the access time seconds in the Linux status record.
	pub const ACCESSED_SECONDS: usize = 72;
	/// Byte offset of the access time nanoseconds in the Linux status record.
	pub const ACCESSED_NANOSECONDS: usize = 80;
	/// Byte offset of the modification time seconds in the Linux status record.
	pub const MODIFIED_SECONDS: usize = 88;
	/// Byte offset of the modification time nanoseconds in the Linux status record.
	pub const MODIFIED_NANOSECONDS: usize = 96;
}

/// Contains byte offsets and sizes for Linux directory records.
pub mod directory {
	/// Byte offset of the next directory position in a Linux record.
	pub const FILE: usize = 8;
	/// Byte offset of the record length in a Linux directory entry.
	pub const RECORD_LENGTH: usize = 16;
	/// Byte offset of the entry type in a Linux directory record.
	pub const TYPE: usize = 18;
	/// Byte offset of the entry name in a Linux directory record.
	pub const NAME: usize = 19;
	/// Minimum valid size of a Linux directory entry record.
	pub const MINIMUM_LENGTH: usize = 20;
	/// Capacity used to read Linux directory entry records.
	pub const BUFFER_SIZE: usize = 280;
}

/// Contains Linux flags passed to file-opening syscalls.
pub mod native {
	/// Linux flag that opens a file for reading.
	pub const READ_ONLY: u32 = 0;
	/// Linux flag that opens a file for writing.
	pub const WRITE_ONLY: u32 = 1;
	/// Linux flag that opens a file for reading and writing.
	pub const READ_WRITE: u32 = 2;
	/// Linux flag that creates a file if it does not exist.
	pub const CREATE: u32 = 64;
	/// Linux flag that fails if creation finds an existing file.
	pub const EXCLUSIVE: u32 = 128;
	/// Linux flag that truncates an opened file.
	pub const TRUNCATE: u32 = 512;
	/// Linux flag that appends writes to the end of a file.
	pub const APPEND: u32 = 1024;
	/// Linux flag that requires the path to name a directory.
	pub const DIRECTORY: u32 = 65536;
	/// Linux flag that prevents following a symbolic link.
	pub const NO_FOLLOW: u32 = 131072;
}

/// Contains flags and error values used when removing filesystem entries.
pub mod unlink {
	/// Flag passed to unlinkat when removing a directory.
	pub const DIRECTORY: u32 = 512;
	/// Linux error value returned when unlinkat is given a directory without its flag.
	pub const IS_DIRECTORY: isize = (0 cast isize) - (21 cast isize);
}

/// Contains Linux file type and permission masks.
pub mod mode {
	/// Mask selecting the file type bits in Linux mode metadata.
	pub const TYPE_MASK: u32 = 61440;
	/// Linux mode bits identifying a regular file.
	pub const REGULAR: u32 = 32768;
	/// Linux mode bits identifying a directory.
	pub const DIRECTORY: u32 = 16384;
	/// Linux mode bits identifying a symbolic link.
	pub const SYMBOLIC_LINK: u32 = 40960;
	/// Linux mode bits identifying a character device.
	pub const CHARACTER_DEVICE: u32 = 8192;
	/// Linux mode bits identifying a block device.
	pub const BLOCK_DEVICE: u32 = 24576;
	/// Linux mode bits identifying a FIFO.
	pub const FIFO: u32 = 4096;
	/// Linux mode bits identifying a socket.
	pub const SOCKET: u32 = 49152;
	/// Mask selecting permission bits in Linux mode metadata.
	pub const PERMISSIONS_MASK: u32 = 4095;
}

/// Contains Linux directory entry type codes.
pub mod directory_type {
	/// Linux directory entry code for a regular file.
	pub const REGULAR: u8 = 8;
	/// Linux directory entry code for a directory.
	pub const DIRECTORY: u8 = 4;
	/// Linux directory entry code for a symbolic link.
	pub const SYMBOLIC_LINK: u8 = 10;
	/// Linux directory entry code for a character device.
	pub const CHARACTER_DEVICE: u8 = 2;
	/// Linux directory entry code for a block device.
	pub const BLOCK_DEVICE: u8 = 6;
	/// Linux directory entry code for a FIFO.
	pub const FIFO: u8 = 1;
	/// Linux directory entry code for a socket.
	pub const SOCKET: u8 = 12;
}

/// Converts Linux file type codes to portable filesystem kinds.
pub mod kind {
	/// Converts Linux mode bits to a portable filesystem kind.
	pub fn kind_from_mode(mode: u32) -> std.io.fs.Kind {
		let kind: u32 = mode & std.arch.fs.mode.TYPE_MASK;
		if kind == std.arch.fs.mode.REGULAR {
			return std.io.fs.Kind.Regular;
		}
		if kind == std.arch.fs.mode.DIRECTORY {
			return std.io.fs.Kind.Directory;
		}
		if kind == std.arch.fs.mode.SYMBOLIC_LINK {
			return std.io.fs.Kind.SymbolicLink;
		}
		if kind == std.arch.fs.mode.CHARACTER_DEVICE {
			return std.io.fs.Kind.CharacterDevice;
		}
		if kind == std.arch.fs.mode.BLOCK_DEVICE {
			return std.io.fs.Kind.BlockDevice;
		}
		if kind == std.arch.fs.mode.FIFO {
			return std.io.fs.Kind.Fifo;
		}
		if kind == std.arch.fs.mode.SOCKET {
			return std.io.fs.Kind.Socket;
		}
		return std.io.fs.Kind.Unknown;
	}

	/// Converts a Linux directory entry code to a portable kind.
	pub fn kind_from_directory_type(kind: u8) -> std.io.fs.Kind {
		if kind == std.arch.fs.directory_type.REGULAR {
			return std.io.fs.Kind.Regular;
		}
		if kind == std.arch.fs.directory_type.DIRECTORY {
			return std.io.fs.Kind.Directory;
		}
		if kind == std.arch.fs.directory_type.SYMBOLIC_LINK {
			return std.io.fs.Kind.SymbolicLink;
		}
		if kind == std.arch.fs.directory_type.CHARACTER_DEVICE {
			return std.io.fs.Kind.CharacterDevice;
		}
		if kind == std.arch.fs.directory_type.BLOCK_DEVICE {
			return std.io.fs.Kind.BlockDevice;
		}
		if kind == std.arch.fs.directory_type.FIFO {
			return std.io.fs.Kind.Fifo;
		}
		if kind == std.arch.fs.directory_type.SOCKET {
			return std.io.fs.Kind.Socket;
		}
		return std.io.fs.Kind.Unknown;
	}
}

/// Reads an unsigned little-endian integer from a byte record.
pub fn read_integer<T: u>(raw: *u8, offset: usize) -> T {
	let mut value: T = 0;
	let width: usize = @of.size(T);
	for let mut i: usize = 0; i < width; i += 1 {
		value = value | ((raw[offset + i] cast T) << ((i * 8) cast T));
	}
	return value;
}

/// Combines a seconds value and nanoseconds into one timestamp.
pub fn timestamp_nanoseconds(seconds: i64, nanoseconds: u64) -> u64 {
	if seconds < 0 {
		return 0;
	}
	let max_value: u64 = (0 cast u64) - 1;
	let billion: u64 = 1000000000;
	if (seconds cast u64) > (max_value - nanoseconds) / billion {
		return max_value;
	}
	return (seconds cast u64) * billion + nanoseconds;
}

/// Populates portable filesystem metadata from a Linux status record.
pub fn fill_info(raw: *u8, info: *mut std.io.fs.Info) -> void {
	// Linux fstat exposes ctime but not portable creation/birth time here;
	// CreatedNs is therefore zero and omitted from Available.
	let mode: u32 = read_integer<u32>(raw, std.arch.fs.stat_layout.MODE);
	let modified_seconds: i64 = read_integer<u64>(
		raw,
		std.arch.fs.stat_layout.MODIFIED_SECONDS
	) cast i64;
	let accessed_seconds: i64 = read_integer<u64>(
		raw,
		std.arch.fs.stat_layout.ACCESSED_SECONDS
	) cast i64;
	let modified_ns: u64 = read_integer<u32>(
		raw,
		std.arch.fs.stat_layout.MODIFIED_NANOSECONDS
	) cast u64;
	let accessed_ns: u64 = read_integer<u32>(
		raw,
		std.arch.fs.stat_layout.ACCESSED_NANOSECONDS
	) cast u64;
	info.kind = std.arch.fs.kind.kind_from_mode(mode);
	info.available = (std.io.fs.InfoFields.Size cast u32)
		| (std.io.fs.InfoFields.Permissions cast u32)
		| (std.io.fs.InfoFields.ModifiedNs cast u32)
		| (std.io.fs.InfoFields.AccessedNs cast u32)
		| (std.io.fs.InfoFields.Links cast u32);
	info.size = read_integer<u64>(raw, std.arch.fs.stat_layout.SIZE);
	info.permissions = mode
		& std.arch.fs.mode.PERMISSIONS_MASK;
	info.modified_ns = timestamp_nanoseconds(modified_seconds, modified_ns);
	info.accessed_ns = timestamp_nanoseconds(accessed_seconds, accessed_ns);
	info.created_ns = 0;
	let links: u64 = read_integer<u64>(raw, std.arch.fs.stat_layout.LINKS);
	let max_links: u32 = (0 cast u32) - 1;
	info.links = links > (max_links cast u64) ? max_links : links cast u32;
}
