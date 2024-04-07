const std = @import("std");
const builtin = @import("builtin");
const clap = @import("clap");
const getterminalsize = @import("getterminalsize.zig");

pub const std_options = .{ .log_level = .warn };

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gp_allocator = general_purpose_allocator.allocator();

fn handleArgs(comptime Id: type, comptime params: []const clap.Param(Id)) !clap.Result(clap.Help, params, clap.parsers.default) {
    const stderr = std.io.getStdErr().writer();
    var diag = clap.Diagnostic{};
    const res = clap.parse(clap.Help, params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gp_allocator,
    }) catch |err| {
        diag.report(stderr, err) catch {};
        return err;
    };

    if (res.args.help == 0) {
        if (res.positionals.len == 0) {
            std.log.err("Please specify a rule between 0 and 255.", .{});
            return error.InvalidArgs;
        }

        if (res.args.infinite != 0 and res.args.generations != null) {
            std.log.err("Infinite mode enabled. Cannot compute a fixed amount of generations.", .{});
            return error.InvalidArgs;
        }

        if (res.args.condition != null and res.args.random != null) {
            std.log.err("Cannot enable both specific and random conditions.", .{});
            return error.InvalidArgs;
        }

        if (res.args.condition != null and res.args.width != null) {
            std.log.warn("Starting condition specified. Width setting ignored.", .{});
        }

        if (res.args.random) |rate| {
            if (rate > 100) {
                std.log.err("Random activated cell rate needs to be between 0% and 100%", .{});
                return error.InvalidArgs;
            }
        }
    }

    return res;
}

fn printCells(cells: std.bit_set.DynamicBitSet, printNewline: bool, delay: ?usize) !void {
    const stdout = std.io.getStdOut().writer();
    const display = " #";

    for (0..cells.capacity()) |cell_index| try stdout.print("{c}", .{display[@intFromBool(cells.isSet(cell_index))]});
    if (printNewline) try stdout.print("\n", .{});
    if (delay) |delay_ms| std.time.sleep(delay_ms * 1_000_000);
}

fn computeNextGen(current_gen: *std.bit_set.DynamicBitSet, next_gen: *std.bit_set.DynamicBitSet, ruleset: [8]u1, size: usize) !void {
    for (0..size) |cell_index| {
        const prev_cell: u8 = @intFromBool(current_gen.isSet((cell_index + size - 1) % size));
        const next_cell: u8 = @intFromBool(current_gen.isSet((cell_index + 1) % size));
        const neighborhood: u8 = prev_cell << 2 | (@as(u8, @intFromBool(current_gen.isSet(cell_index))) << 1) | next_cell;

        next_gen.setValue(cell_index, ruleset[neighborhood] != 0);
    }

    std.mem.swap(std.bit_set.DynamicBitSet, current_gen, next_gen);
}

pub fn main() !void {
    const stdout = std.io.getStdOut();
    const stderr = std.io.getStdErr().writer();

    const params = comptime clap.parseParamsComptime(
        \\<u8>                          Rule between 0 and 255.
        \\-h, --help                    Display this help and exit.
        \\-w, --width <usize>           Width of each generation. Ignored if specific condition is set. Defaults to terminal width.
        \\-g, --generations <usize>     Number of generations to display. Incompatible with infinite mode. Defaults to terminal height.
        \\-s, --start <usize>           Pre-compute an amount of generations before displaying the automata.
        \\-i, --infinite                Infinite mode, keep computing generations until interrupted.
        \\-d, --delay <usize>           Delay display between lines, in milliseconds.
        \\-c, --condition <str>         Start with specific condition. 1 and # are active cells, the rest is empty cells. Incompatible with random condition.
        \\-r, --random <usize>          Start with a random condition, with percentage frequency of active cells.
    );

    const res = try handleArgs(clap.Help, &params);
    defer res.deinit();

    if (res.args.help != 0) {
        return clap.help(stderr, clap.Help, &params, .{});
    }

    var automaton_size: getterminalsize.TermSize = undefined;

    const width_is_set = res.args.width != null or res.args.condition != null;
    const height_is_set = res.args.generations != null or res.args.infinite != 0;

    if (!width_is_set or !height_is_set) {
        automaton_size = getterminalsize.getTerminalSize() catch |err| blk: {
            switch (err) {
                getterminalsize.TermSizeError.Unsupported => {
                    std.log.warn("Getting terminal size automatically is not available for platform {s}. Defaulting to 80x25.", .{@tagName(builtin.target.os.tag)});
                    break :blk getterminalsize.TermSize{
                        .col = 80,
                        .row = 25 - 1, // assume prompt is 1 line high
                    };
                },
                getterminalsize.TermSizeError.NotATty => {
                    std.log.err("Standard output is not a terminal. Please set a size manually.", .{});
                    return err;
                },
                else => {
                    std.log.err("Unexpected error getting terminal size.", .{});
                    return err;
                },
            }
        };
    }

    automaton_size.col = blk: {
        if (res.args.condition) |condition| break :blk condition.len;
        if (res.args.width) |width| break :blk width;
        break :blk automaton_size.col;
    };
    automaton_size.row = blk: {
        if (res.args.generations) |generations| break :blk generations;
        if (res.args.infinite != 0) break :blk undefined;
        break :blk automaton_size.row;
    };

    var current_gen = try std.bit_set.DynamicBitSet.initEmpty(gp_allocator, automaton_size.col);
    defer current_gen.deinit();

    var next_gen = try std.bit_set.DynamicBitSet.initEmpty(gp_allocator, automaton_size.col);
    defer next_gen.deinit();

    if (res.args.condition) |condition| {
        for (0..automaton_size.col) |index| {
            current_gen.setValue(index, condition[index] == '#' or condition[index] == '1');
        }
    } else if (res.args.random) |rate| {
        var rng = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));

        for (0..automaton_size.col) |index| {
            current_gen.setValue(index, rng.random().intRangeAtMost(u7, 1, 100) <= rate);
        }
    } else {
        current_gen.set(automaton_size.col / 2);
    }

    const rule = res.positionals[0];

    var ruleset: [8]u1 = undefined;

    for (0..8) |index|
        ruleset[index] = if ((rule & (@as(u8, 1) << @intCast(index))) != 0) 1 else 0;

    for (0..(res.args.start orelse 0)) |_| {
        try computeNextGen(&current_gen, &next_gen, ruleset, automaton_size.col);
    }

    try printCells(current_gen, true, res.args.delay);

    if (res.args.infinite == 0) {
        for (1..automaton_size.row) |iteration| {
            try computeNextGen(&current_gen, &next_gen, ruleset, automaton_size.col);

            // Windows’ prompt automatically prints a newline, so a final one is not needed.
            const windows_trailing_newline = (builtin.target.os.tag != .windows or iteration != automaton_size.row - 1);
            try printCells(current_gen, windows_trailing_newline or !std.posix.isatty(stdout.handle), res.args.delay);
        }
    } else {
        while (true) {
            try computeNextGen(&current_gen, &next_gen, ruleset, automaton_size.col);
            try printCells(current_gen, true, res.args.delay);
        }
    }
}
