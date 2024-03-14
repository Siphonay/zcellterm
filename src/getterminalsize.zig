const std = @import("std");
const builtin = @import("builtin");
const os = std.os;
const windows = std.os.windows;
const linux = std.os.linux;
const c = @cImport({
    @cInclude("Windows.h");
});

pub const TermSize = struct {
    col: u16 = 0,
    row: u16 = 0,
};

pub fn getTerminalSize() !TermSize {
    if (builtin.target.os.tag == .linux) {
        var winsize: linux.winsize = undefined;

        switch (os.errno(linux.ioctl(std.io.getStdOut().handle, linux.T.IOCGWINSZ, @intFromPtr(&winsize)))) {
            .SUCCESS => return TermSize{
                .col = winsize.ws_col,
                .row = winsize.ws_row,
            },
            else => return error.Unexpected,
        }
    } else if (builtin.target.os.tag == .windows) {
        var info: windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
        const stdout_handle = windows.kernel32.GetStdHandle(c.STD_OUTPUT_HANDLE);

        if (stdout_handle == c.INVALID_HANDLE_VALUE)
            return error.Unexpected;

        if (windows.kernel32.GetConsoleScreenBufferInfo(stdout_handle.?, &info) != windows.TRUE)
            return error.Unexpected;

        return TermSize{ // These are stored in a signed type (windows.SHORT) but will never be negative
            .col = @intCast(info.dwSize.X),
            .row = @intCast(info.dwSize.Y),
        };
    } else {
        std.log.info("Getting terminal size is unavailable for your platform. Please specify size manually or create a pull request to implement support.", .{});
        return error.Unsupported;
    }
}