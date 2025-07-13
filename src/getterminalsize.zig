const std = @import("std");
const builtin = @import("builtin");

pub const TermSizeError = error{
    Unexpected,
    Unsupported,
    NotATty,
};

pub const TermSize = struct {
    col: usize,
    row: usize,
};

pub fn getTerminalSize() TermSizeError!TermSize {
    const stdout = std.io.getStdOut();

    return switch (builtin.target.os.tag) {
        .windows => windows: {
            var winsize: std.os.windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;

            if (std.os.windows.kernel32.GetConsoleScreenBufferInfo(stdout.handle, &winsize) != std.os.windows.TRUE) {
                break :windows TermSizeError.Unexpected;
            }

            break :windows TermSize{ // These are stored in a signed type (windows.SHORT) but will never be negative
                .col = @intCast(winsize.srWindow.Right - winsize.srWindow.Left + 1),
                .row = @intCast(winsize.srWindow.Bottom - winsize.srWindow.Top), // no +1, assume prompt is 1 line high
            };
        },
        else => |os_tag| other_os: {
            const ioctl_interface = switch (os_tag) {
                .linux => std.os.linux,
                else => std.c,
            };
            
            if (!@hasDecl(ioctl_interface, "T")) {
                break :other_os TermSizeError.Unsupported;
            }

            var winsize: std.posix.winsize = undefined;

            switch (std.posix.errno(ioctl_interface.ioctl(stdout.handle, ioctl_interface.T.IOCGWINSZ, @intFromPtr(&winsize)))) {
                .SUCCESS => break :other_os TermSize{
                    .col = winsize.col,
                    .row = winsize.row - 1, // assume prompt is 1 line high
                },
                else => break :other_os TermSizeError.Unexpected,
            }
        },
    } catch |err| {
        if (!std.posix.isatty(stdout.handle)) {
            return TermSizeError.NotATty;
        } else return err;
    };
}
