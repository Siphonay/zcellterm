const std = @import("std");
const builtin = @import("builtin");
const getterminalsize = @import("getterminalsize.zig");

fn printCells(cells: []u1, printNewline: bool) !void {
    const stdout = std.io.getStdOut().writer();
    const display = " #";

    for (cells) |*cell|
        try stdout.print("{c}", .{display[cell.*]});

    if (printNewline)
        try stdout.print("\n", .{});
}

fn computeNextGen(current_gen: []u1, next_gen: []u1, ruleset: [8]u1, size: u16) !void {
    for (current_gen, next_gen, 0..) |cell, *next_gen_cell, index| {
        const prev_cell = current_gen[(index + size - 1) % size];
        const next_cell = current_gen[(index + 1) % size];
        const neighborhood: u8 = (@as(u8, prev_cell) << 2) | (@as(u8, cell) << 1) | next_cell;

        next_gen_cell.* = ruleset[neighborhood];
    }
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gp_allocator = general_purpose_allocator.allocator();

    const args = try std.process.argsAlloc(gp_allocator);
    defer std.process.argsFree(gp_allocator, args);

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

    var current_gen = try gp_allocator.alloc(u1, termsize.col);
    defer gp_allocator.free(current_gen);

    var next_gen = try gp_allocator.alloc(u1, termsize.col);
    defer gp_allocator.free(next_gen);

    @memset(current_gen, 0);
    current_gen[termsize.col / 2] = 1;

    const rule: u8 = std.fmt.parseInt(u8, args[1], 10) catch {
        try stderr.print("Please specify a rule between 0 and 255\n", .{});
        return error.InvalidArg;
    };

    var ruleset: [8]u1 = undefined;

    for (0..8) |index|
        ruleset[index] = if ((rule & (@as(u8, 1) << @intCast(index))) != 0) 1 else 0;

    try printCells(current_gen, true);

    for (0..termsize.row - 2) |iteration| {
        try computeNextGen(current_gen, next_gen, ruleset, termsize.col);
        std.mem.swap([]u1, &current_gen, &next_gen);
        // Windows’ prompt automatically prints a newline, so a final one is not needed.
        try printCells(current_gen, (builtin.target.os.tag != .windows or iteration != termsize.row - 3));
    }
}
