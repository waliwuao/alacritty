use std::ffi::CString;
use std::ffi::OsStr;
use std::fs;
use std::io;
use std::os::unix::ffi::OsStringExt;
use std::process::{Command, Stdio};

use std::error::Error;
use std::os::unix::io::RawFd;
use std::os::unix::process::CommandExt;
use std::path::PathBuf;

use libc::pid_t;

/// Start a new process in the background.
pub fn spawn_daemon<I, S>(
    program: &str,
    args: I,
    master_fd: RawFd,
    shell_pid: u32,
) -> io::Result<()>
where
    I: IntoIterator<Item = S> + Copy,
    S: AsRef<OsStr>,
{
    let mut command = Command::new(program);
    command.args(args).stdin(Stdio::null()).stdout(Stdio::null()).stderr(Stdio::null());

    let working_directory = foreground_process_path(master_fd, shell_pid)
        .ok()
        .and_then(|path| CString::new(path.into_os_string().into_vec()).ok());

    unsafe {
        command
            .pre_exec(move || {
                // POSIX.1-2017 describes `fork` as async-signal-safe with the following note:
                //
                // > While the fork() function is async-signal-safe, there is no way for
                // > an implementation to determine whether the fork handlers established by
                // > pthread_atfork() are async-signal-safe. [...] It is therefore undefined for the
                // > fork handlers to execute functions that are not async-signal-safe when fork()
                // > is called from a signal handler.
                //
                // POSIX.1-2024 removes this guarantee and introduces an async-signal-safe
                // replacement `_Fork`, which we'd like to use, but macOS doesn't support it yet.
                //
                // Since we aren't registering any fork handlers, and hopefully the OS doesn't
                // either, we're fine on systems compatible with POSIX.1-2017, which should be
                // enough for a long while. If this ever becomes a problem in the future, we should
                // be able to switch to `_Fork`.
                match libc::fork() {
                    -1 => return Err(io::Error::last_os_error()),
                    0 => (),
                    _ => libc::_exit(0),
                }

                // Copy foreground process' working directory, ignoring invalid paths.
                if let Some(working_directory) = working_directory.as_ref() {
                    libc::chdir(working_directory.as_ptr());
                }

                if libc::setsid() == -1 {
                    return Err(io::Error::last_os_error());
                }

                Ok(())
            })
            .spawn()?
            .wait()
            .map(|_| ())
    }
}

/// Get working directory of controlling process.
pub fn foreground_process_path(
    master_fd: RawFd,
    shell_pid: u32,
) -> Result<PathBuf, Box<dyn Error>> {
    let mut pid = unsafe { libc::tcgetpgrp(master_fd) };
    if pid < 0 {
        pid = shell_pid as pid_t;
    }

    let link_path = format!("/proc/{pid}/cwd");
    let cwd = fs::read_link(link_path)?;

    Ok(cwd)
}
