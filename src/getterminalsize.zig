const std = @import("std");
const builtin = @import("builtin");
const os = std.os;

pub const TermSizeError = error{
    Unexpected,
    Unsupported,
};

pub const TermSize = struct {
    col: u16,
    row: u16,
};

pub fn getTerminalSize() TermSizeError!TermSize {
    switch (builtin.target.os.tag) {
        .windows => {
            var winsize: os.windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;

            if (os.windows.kernel32.GetConsoleScreenBufferInfo(std.io.getStdOut().handle, &winsize) != os.windows.TRUE)
                return error.Unexpected;

            return TermSize{ // These are stored in a signed type (windows.SHORT) but will never be negative
                .col = @intCast(winsize.srWindow.Right - winsize.srWindow.Left + 1),
                .row = @intCast(winsize.srWindow.Bottom - winsize.srWindow.Top + 1),
            };
        },
        else => {
            if (!@hasDecl(os.system, "T")) {
                return error.Unsupported;
            }

            var winsize: os.system.winsize = undefined;

            switch (os.errno(os.system.ioctl(std.io.getStdOut().handle, os.system.T.IOCGWINSZ, @intFromPtr(&winsize)))) {
                .SUCCESS => return TermSize{
                    .col = winsize.ws_col,
                    .row = winsize.ws_row,
                },
                else => return error.Unexpected,
            }
        },
    }
}
