mod std.io.fs;

/// Kinds of filesystem objects reported by metadata and directory APIs.
pub enum Kind: u8 {
	Unknown,
	Regular,
	Directory,
	SymbolicLink,
	CharacterDevice,
	BlockDevice,
	Fifo,
	Socket
}

/// Bit flags identifying fields populated in an `Info` value.
pub enum InfoFields: u32 {
	Size = 1,
	Permissions = 2,
	ModifiedNs = 4,
	AccessedNs = 8,
	CreatedNs = 16,
	Links = 32
}

/// Filesystem metadata with a platform-dependent availability mask.
pub struct Info {
	/// Kind of filesystem object described by this value.
	pub kind: Kind,
	/// Bit mask identifying which metadata fields are available.
	pub available: u32,
	/// Filesystem object size in bytes.
	pub size: u64,
	/// Platform permission bits for the filesystem object.
	pub permissions: u32,
	/// Modification time in nanoseconds since the Unix epoch.
	pub modified_ns: u64,
	/// Access time in nanoseconds since the Unix epoch.
	pub accessed_ns: u64,
	/// Creation time in nanoseconds since the Unix epoch, when available.
	pub created_ns: u64,
	/// Number of hard links to the filesystem object.
	pub links: u32
}

/// Reports whether a path pointer is valid for filesystem operations.
pub fn valid_path(path: *u8) -> bool {
	return path != null;
}
