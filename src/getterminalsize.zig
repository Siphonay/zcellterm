const std = @import("std");
const builtin = @import("builtin");
const os = std.os;

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
    
    if (!os.isatty(stdout.handle)) {
        return TermSizeError.NotATty;
    }

    switch (builtin.target.os.tag) {
        .windows => {
            var winsize: os.windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;

            if (os.windows.kernel32.GetConsoleScreenBufferInfo(stdout.handle, &winsize) != os.windows.TRUE) {
                return TermSizeError.Unexpected;
            }

            return TermSize{ // These are stored in a signed type (windows.SHORT) but will never be negative
                .col = @intCast(winsize.srWindow.Right - winsize.srWindow.Left + 1),
                .row = @intCast(winsize.srWindow.Bottom - winsize.srWindow.Top + 1),
            };
        },
        else => {
            if (!@hasDecl(os.system, "T")) {
                return TermSizeError.Unsupported;
            }

            var winsize: os.system.winsize = undefined;

            switch (os.errno(os.system.ioctl(stdout.handle, os.system.T.IOCGWINSZ, @intFromPtr(&winsize)))) {
                .SUCCESS => return TermSize{
                    .col = winsize.ws_col,
                    .row = winsize.ws_row,
                },
                else => return TermSizeError.Unexpected,
            }
        },
    }
}
