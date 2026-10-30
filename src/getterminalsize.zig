const std = @import("std");
const builtin = @import("builtin");

pub const TermSizeError = error{
    Canceled,
    Unexpected,
    Unsupported,
    NotATty,
};

pub const TermSize = struct {
    col: usize,
    row: usize,
};

pub fn getTerminalSize(init: std.process.Init) TermSizeError!TermSize {
    const stdout = std.Io.File.stdout();

    return switch (builtin.target.os.tag) {
        .windows => windows: {
            var buffer_info_req = std.os.windows.CONSOLE.USER_IO.GET_SCREEN_BUFFER_INFO;

            switch (try buffer_info_req.operate(init.io, stdout)) {
                .SUCCESS => {},
                else => break :windows TermSizeError.Canceled,
            }

            const winsize = buffer_info_req.Data;
            break :windows TermSize{
                .col = @intCast(winsize.dwWindowSize.X),
                .row = @intCast(winsize.dwWindowSize.Y - 1), // prompt is 1 line high
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
        if (!try std.Io.File.stdout().isTty(init.io)) {
            return TermSizeError.NotATty;
        } else return err;
    };
}
