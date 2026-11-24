mod std.arch.proc;
import "./code.sl";
import "std/err.sl";

mod syscall_number {
	/// Linux syscall number for creating a process or thread.
	pub const CLONE: u64 = 220;
	/// Linux syscall number for replacing the current process image.
	pub const EXECVE: u64 = 221;
	/// Linux syscall number for waiting on a child process.
	pub const WAIT4: u64 = 260;
	/// Linux syscall number for terminating all process threads.
	pub const EXIT_GROUP: u64 = 94;
	/// Linux syscall number for retrieving the process identifier.
	pub const GETPID: u64 = 172;
	/// Linux syscall number for retrieving the thread identifier.
	pub const GETTID: u64 = 178;
	/// Linux syscall number for sending a signal to a thread.
	pub const TGKILL: u64 = 131;
}

mod wait {
	/// Linux error value used when a wait operation is interrupted.
	pub const INTERRUPTED: isize = (0 cast isize) - (4 cast isize);
}

mod syscall {
	/// Invokes Linux clone with the requested process flags.
	pub fn clone(flags: usize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"svc #0"
			: "=x0" (result)
			: "{w8}" (std.arch.proc.syscall_number.CLONE),
			"{x0}" (flags), "{x1}" (null), "{x2}" (null),
			"{x3}" (null), "{x4}" (null)
			: "memory"
		};
		return result;
	}

	/// Replaces the process image with the requested program and argument arrays.
	pub fn execve(path: *u8, arguments: **u8, environment: **u8) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"svc #0"
			: "=x0" (result)
			: "{w8}" (std.arch.proc.syscall_number.EXECVE),
			"{x0}" (path), "{x1}" (arguments),
			"{x2}" (environment)
			: "memory"
		};
		return result;
	}

	/// Waits for a child process and writes its status when available.
	pub fn wait4(pid: isize, status: *mut u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"svc #0"
			: "=x0" (result)
			: "{w8}" (std.arch.proc.syscall_number.WAIT4),
			"{x0}" (pid), "{x1}" (status), "{x2}" (0),
			"{x3}" (null)
			: "memory"
		};
		return result;
	}

	/// Terminates all threads in the current process with the supplied code.
	pub fn exit_group(code: u8) -> void {
		asm volatile {
			"svc #0"
			:
			: "{w8}" (std.arch.proc.syscall_number.EXIT_GROUP),
			"{x0}" (code cast usize)
			: "memory"
		};
	}

	/// Returns the process identifier of the current process.
	pub fn getpid() -> usize {
		let mut pid: usize = 0;
		asm volatile {
			"svc #0"
			: "=x0" (pid)
			: "{w8}" (std.arch.proc.syscall_number.GETPID)
			: "memory"
		};
		return pid;
	}

	/// Returns the thread identifier of the current thread.
	pub fn gettid() -> usize {
		let mut tid: usize = 0;
		asm volatile {
			"svc #0"
			: "=x0" (tid)
			: "{w8}" (std.arch.proc.syscall_number.GETTID)
			: "memory"
		};
		return tid;
	}

	/// Sends a signal to the specified thread in the specified process.
	pub fn tgkill(pid: usize, tid: usize, sig: isize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"svc #0"
			: "=x0" (result)
			: "{w8}" (std.arch.proc.syscall_number.TGKILL),
			"{x0}" (pid), "{x1}" (tid), "{x2}" (sig)
			: "memory"
		};
		return result;
	}
}

fn portable_error(result: isize) -> isize {
	let native: isize = (0 cast isize) - result;
	if native > 255 {
		return -(std.err.Code.Unknown cast isize);
	}
	let backend: std.arch.err.Code =
	(native cast u8) cast std.arch.err.Code;
	return -(std.arch.err.to_portable_code(backend) cast isize);
}

/// Terminates the process using the Linux exit_group syscall.
pub fn exit(code: u8) -> void {
	std.arch.proc.syscall.exit_group(code);
}

/// Raises SIGABRT for the calling thread, then forces process termination if
/// the signal is blocked or handled.
#[!return]
pub fn abort() -> void {
	let pid: usize = std.arch.proc.syscall.getpid();
	let tid: usize = std.arch.proc.syscall.gettid();
	std.arch.proc.syscall.tgkill(pid, tid, 6);
	std.arch.proc.syscall.exit_group(134);
	for true {
		// ...
	}
}

/// Executes `program` with `argv` and waits for it to finish.
pub fn exec(program: *u8, argv: **u8) -> isize {
	// 17 = SIGCHLD
	let child: isize = std.arch.proc.syscall.clone(17);
	if child < 0 {
		return portable_error(child);
	}
	if child == 0 {
		std.arch.proc.syscall.execve(program, argv, null);
		std.arch.proc.syscall.exit_group(127);
		for true {
			// The exit syscall should not return.
		}
	}

	let mut status: u32 = 0;
	let mut result: isize = std.arch.proc.syscall.wait4(child, &status);
	for result == std.arch.proc.wait.INTERRUPTED {
		result = std.arch.proc.syscall.wait4(child, &status);
	}
	if result < 0 {
		return portable_error(result);
	}

	if (status & 127) == 0 {
		return ((status >> 8) & 255) cast isize;
	}
	return (128 + (status & 127)) cast isize;
}

/// Runs `command` in `/bin/sh` and waits for the shell to finish.
pub fn shell(command: *u8) -> isize {
	let mut arguments: [4]*u8;
	arguments[0] = "sh";
	arguments[1] = "-c";
	arguments[2] = command;
	arguments[3] = null;
	return exec("/bin/sh", &arguments[0]);
}
