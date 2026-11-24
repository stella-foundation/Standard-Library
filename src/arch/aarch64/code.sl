mod std.arch.err;
import "std/err.sl";

/// Linux errno values represented by the backend.
pub enum Code: u8 {
	Success,
	OperationNotPermitted,
	NoSuchFileOrDirectory,
	NoSuchProcess,
	InterruptedSystemCall,
	InputOutputError,
	NoSuchDeviceOrAddress,
	ArgumentListTooLong,
	ExecFormatError,
	BadFileDescriptor,
	NoChildProcesses,
	ResourceTemporarilyUnavailable,
	CannotAllocateMemory,
	PermissionDenied,
	BadAddress,
	BlockDeviceRequired,
	DeviceOrResourceBusy,
	FileExists,
	InvalidCrossDeviceLink,
	NoSuchDevice,
	NotADirectory,
	IsADirectory,
	InvalidArgument,
	TooManyOpenFilesInSystem,
	TooManyOpenFiles,
	InappropriateIoctlForDevice,
	TextFileBusy,
	FileTooLarge,
	NoSpaceLeftOnDevice,
	IllegalSeek,
	ReadOnlyFileSystem,
	TooManyLinks,
	BrokenPipe,
	NumericalArgumentOutOfDomain,
	NumericalResultOutOfRange,
	ResourceDeadlockAvoided,
	FileNameTooLong,
	NoLocksAvailable,
	FunctionNotImplemented,
	DirectoryNotEmpty,
	TooManyLevelsOfSymbolicLinks,
	NoMessageOfDesiredType,
	IdentifierRemoved,
	ChannelNumberOutOfRange,
	Level2NotSynchronized,
	Level3Halted,
	Level3Reset,
	LinkNumberOutOfRange,
	ProtocolDriverNotAttached,
	NoCsiStructureAvailable,
	Level2Halted,
	InvalidExchange,
	InvalidRequestDescriptor,
	ExchangeFull,
	NoAnode,
	InvalidRequestCode,
	InvalidSlot,
	BadFontFileFormat,
	DeviceNotAStream,
	NoDataAvailable,
	TimerExpired,
	OutOfStreamsResources,
	MachineIsNotOnTheNetwork,
	PackageNotInstalled,
	ObjectIsRemote,
	LinkHasBeenSevered,
	AdvertiseError,
	SrmountError,
	CommunicationErrorOnSend,
	ProtocolError,
	MultihopAttempted,
	RfsSpecificError,
	BadMessage,
	ValueTooLargeToBeStoredInDataType,
	NameNotUniqueOnNetwork,
	FileDescriptorInBadState,
	RemoteAddressChanged,
	CanNotAccessANeededSharedLibrary,
	AccessingACorruptedSharedLibrary,
	LibSectionInAOutCorrupted,
	AttemptingToLinkInTooManySharedLibraries,
	CannotExecASharedLibraryDirectly,
	IllegalByteSequence,
	InterruptedSystemCallShouldBeRestarted,
	StreamsPipeError,
	TooManyUsers,
	SocketOperationOnNonSocket,
	DestinationAddressRequired,
	MessageTooLong,
	ProtocolWrongTypeForSocket,
	ProtocolNotAvailable,
	ProtocolNotSupported,
	SocketTypeNotSupported,
	OperationNotSupported,
	ProtocolFamilyNotSupported,
	AddressFamilyNotSupportedByProtocol,
	AddressAlreadyInUse,
	CannotAssignRequestedAddress,
	NetworkIsDown,
	NetworkIsUnreachable,
	NetworkDroppedConnectionOnReset,
	SoftwareCausedConnectionAbort,
	ConnectionResetByPeer,
	NoBufferSpaceAvailable,
	TransportEndpointIsAlreadyConnected,
	TransportEndpointIsNotConnected,
	CannotSendAfterTransportEndpointShutdown,
	TooManyReferencesCannotSplice,
	ConnectionTimedOut,
	ConnectionRefused,
	HostIsDown,
	NoRouteToHost,
	OperationAlreadyInProgress,
	OperationNowInProgress,
	StaleFileHandle,
	StructureNeedsCleaning,
	NotAXenixNamedTypeFile,
	NoXenixSemaphoresAvailable,
	IsANamedTypeFile,
	RemoteIoError,
	DiskQuotaExceeded,
	NoMediumFound,
	WrongMediumType,
	OperationCanceled,
	RequiredKeyNotAvailable,
	KeyHasExpired,
	KeyHasBeenRevoked,
	KeyWasRejectedByService,
	PreviousOwnerDied,
	StateNotRecoverable,
	OperationNotPossibleDueToRfKill,
	MemoryPageHasHardwareError,
	NotSupportedParameterOrOption,
	Unknown = 255
}

/// Converts a Linux errno value to a portable error code.
pub fn to_portable_code(code: Code) -> std.err.Code {
	if code == Code.Success {
		return std.err.Code.Success;
	}
	if code >= Code.OperationNotPermitted && code <= Code.TooManyLevelsOfSymbolicLinks {
		return code cast std.err.Code;
	}
	if code >= Code.NoMessageOfDesiredType && code <= Code.NotSupportedParameterOrOption {
		return code cast std.err.Code;
	}
	return std.err.Code.Unknown;
}

/// Converts a portable error code to a Linux errno value.
pub fn to_backend_code(code: std.err.Code) -> Code {
	if code == std.err.Code.Success {
		return Code.Success;
	}
	if code >= std.err.Code.OperationNotPermitted
		&& code <= std.err.Code.TooManyLevelsOfSymbolicLinks {
		return code cast Code;
	}
	if code >= std.err.Code.NoMessageOfDesiredType
		&& code <= std.err.Code.NotSupportedParameterOrOption {
		return code cast Code;
	}
	return Code.Unknown;
}
