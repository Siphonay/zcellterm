const std = @import("std");
const builtin = @import("builtin");
const os = std.os;
const windows = std.os.windows;
const c = @cImport({
    @cInclude("Windows.h");
});

pub const TermSize = struct {
    col: u16,
    row: u16,
};

pub fn getTerminalSize() !TermSize {
    switch (builtin.target.os.tag) {
        .linux, .macos => {
            var winsize: os.system.winsize = undefined;

            switch (os.errno(os.system.ioctl(std.io.getStdOut().handle, os.system.T.IOCGWINSZ, @intFromPtr(&winsize)))) {
                .SUCCESS => return TermSize{
                    .col = winsize.ws_col,
                    .row = winsize.ws_row,
                },
                else => return error.Unexpected,
            }
        },
        .windows => {
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
        },
        else => {
            std.log.info(
                \\Getting terminal size is not available for your platform yet. Defaulting to 80x25.
                \\Feel free to contribute by sending a pull request to add it!
                \\Setting terminal size manually will be implemented soon.
            , .{});
            return TermSize{
                .col = 80,
                .row = 25,
            };
        },
    }
}
