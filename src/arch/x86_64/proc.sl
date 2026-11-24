mod std.arch.proc;
import "./code.sl";
import "std/err.sl";

mod syscall_number {
	/// Linux syscall number for creating a child process.
	pub const FORK: u64 = 57;
	/// Linux syscall number for replacing the current process image.
	pub const EXECVE: u64 = 59;
	/// Linux syscall number for waiting on a child process.
	pub const WAIT4: u64 = 61;
	/// Linux syscall number for terminating all process threads.
	pub const EXIT_GROUP: u64 = 231;
	/// Linux syscall number for retrieving the process identifier.
	pub const GETPID: u64 = 39;
	/// Linux syscall number for retrieving the thread identifier.
	pub const GETTID: u64 = 186;
	/// Linux syscall number for sending a signal to a thread.
	pub const TGKILL: u64 = 234;
}

mod wait {
	/// Linux error value used when a wait operation is interrupted.
	pub const INTERRUPTED: isize = (0 cast isize) - (4 cast isize);
}

mod syscall {
	/// Creates a child process and returns the raw syscall result.
	pub fn fork() -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.proc.syscall_number.FORK)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Replaces the process image with the requested program and argument arrays.
	pub fn execve(path: *u8, arguments: **u8, environment: **u8) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.proc.syscall_number.EXECVE),
			"{rdi}" (path), "{rsi}" (arguments),
			"{rdx}" (environment)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Waits for a child process and writes its status when available.
	pub fn wait4(pid: isize, status: *mut u32) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.proc.syscall_number.WAIT4),
			"{rdi}" (pid), "{rsi}" (status), "{rdx}" (0), "{r10}" (null)
			: "rcx", "r11", "memory"
		};
		return result;
	}

	/// Terminates all threads in the current process with the supplied code.
	pub fn exit_group(code: u8) -> void {
		asm volatile {
			"syscall"
			:
			: "{rax}" (std.arch.proc.syscall_number.EXIT_GROUP),
			"{rdi}" (code)
			: "rcx", "r11", "memory"
		};
	}

	/// Returns the process identifier of the current process.
	pub fn getpid() -> usize {
		let mut pid: usize = 0;
		asm volatile {
			"syscall"
			: "=rax" (pid)
			: "{rax}" (std.arch.proc.syscall_number.GETPID)
			: "rcx", "r11", "memory"
		};
		return pid;
	}

	/// Returns the thread identifier of the current thread.
	pub fn gettid() -> usize {
		let mut tid: usize = 0;
		asm volatile {
			"syscall"
			: "=rax" (tid)
			: "{rax}" (std.arch.proc.syscall_number.GETTID)
			: "rcx", "r11", "memory"
		};
		return tid;
	}

	/// Sends a signal to the specified thread in the specified process.
	pub fn tgkill(pid: usize, tid: usize, sig: isize) -> isize {
		let mut result: isize = 0;
		asm volatile {
			"syscall"
			: "=rax" (result)
			: "{rax}" (std.arch.proc.syscall_number.TGKILL),
			"{rdi}" (pid), "{rsi}" (tid), "{rdx}" (sig)
			: "rcx", "r11", "memory"
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
	let child: isize = std.arch.proc.syscall.fork();
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
	arguments[0] = c"sh";
	arguments[1] = c"-c";
	arguments[2] = command;
	arguments[3] = null;
	return exec(c"/bin/sh", &arguments[0]);
}
