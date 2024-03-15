const std = @import("std");
const builtin = @import("builtin");
const getterminalsize = @import("getterminalsize.zig");
const page_allocator = std.heap.page_allocator;

fn printCells(cells: []u1, printNewline: bool) !void {
    const stdout = std.io.getStdOut().writer();
    const display = " #";

    for (cells) |*cell|
        try stdout.print("{c}", .{display[cell.*]});

    if (printNewline)
        try stdout.print("\n", .{});
}

fn computeNextGen(cells: *const []u1, ruleset: [8]u1, size: u16) !void {
    const next_gen = try page_allocator.alloc(u1, size);
    defer page_allocator.free(next_gen);

    for (cells.*, next_gen, 0..) |*cell, *next_gen_cell, index| {
        const prev_cell = cells.*[(index + size - 1) % size];
        const next_cell = cells.*[(index + 1) % size];
        const neighborhood: u8 = (@as(u8, prev_cell) << 2) | (@as(u8, cell.*) << 1) | next_cell;

        next_gen_cell.* = ruleset[neighborhood];
    }

    for (next_gen, cells.*) |*next_gen_cell, *cell|
        cell.* = next_gen_cell.*;
}

pub fn main() !void {
    const args = try std.process.argsAlloc(page_allocator);
    defer std.process.argsFree(page_allocator, args);

    const stderr = std.io.getStdErr().writer();

    if (args.len < 2) {
        try stderr.print(
            \\usage: {s} <rule>
            \\rule should be a nubmer between 0 and 255.
            \\
        , .{args[0]});
        return error.InvalidArg;
    }

    const termsize = try getterminalsize.getTerminalSize();

    const cells = try page_allocator.alloc(u1, termsize.col);
    defer page_allocator.free(cells);

    @memset(cells, 0);
    cells[termsize.col / 2] = 1;

    const rule: u8 = std.fmt.parseInt(u8, args[1], 10) catch {
        try stderr.print("Please specify a rule between 0 and 255\n", .{});
        return error.InvalidArg;
    };

    var ruleset: [8]u1 = undefined;

    for (0..8) |index|
        ruleset[index] = if ((rule & (@as(u8, 1) << @intCast(index))) != 0) 1 else 0;

    try printCells(cells, true);

    for (0..termsize.row - 2) |iteration| {
        try computeNextGen(&cells, ruleset, termsize.col);
        // Windows’ prompt automatically prints a newline, so a final one is not needed.
        try printCells(cells, (builtin.target.os.tag != .windows or iteration != termsize.row - 3));
    }
}
