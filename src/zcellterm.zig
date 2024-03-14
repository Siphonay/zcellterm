const std = @import("std");
const getterminalsize = @import("getterminalsize.zig");
const page_allocator = std.heap.page_allocator;

fn printCells(cells: []u8) !void {
    const stdout = std.io.getStdOut().writer();
    const display = " #";

    for (cells) |*cell|
        try stdout.print("{c}", .{ display[cell.*] });
}

fn computeNextGen(cells: *const []u8, ruleset: []u8, size: u16) !void {
    const next_gen = try page_allocator.alloc(u8, size);
    defer page_allocator.free(next_gen);

    for (cells.*, next_gen, 0..) |*cell, *next_gen_cell, index| {
        const prev_cell = cells.*[(index + size - 1) % size];
        const next_cell = cells.*[(index + 1) % size];
        const neighborhood: u8 = (prev_cell << 2) | (cell.* << 1) | next_cell;

        next_gen_cell.* = ruleset[neighborhood] - '0';
    }

    for (next_gen, cells.*) |*next_gen_cell, *cell|
        cell.* = next_gen_cell.*;
}

pub fn main() !void {
    const args = try std.process.argsAlloc(page_allocator);
    defer std.process.argsFree(page_allocator, args);

    const stderr = std.io.getStdErr().writer();

    if (args.len < 2) {
        try stderr.print("usage: {s} <rule>\nrule should be a nubmer between 0 and 255.\n", .{args[0]});
        return error.InvalidArg;
    }

    const termsize = try getterminalsize.getTerminalSize();

    const cells = try page_allocator.alloc(u8, termsize.col);
    defer page_allocator.free(cells);

    const rule: u8 = std.fmt.parseInt(u8, args[1], 10) catch {
        try stderr.print("Please specify a rule between 0 and 255", .{});
        return error.InvalidArg;
    };

    var ruleset_buffer: [8]u8 = undefined;
    var ruleset_fba = std.heap.FixedBufferAllocator.init(&ruleset_buffer);
    const ruleset_allocator = ruleset_fba.allocator();
    
    const ruleset = try ruleset_allocator.alloc(u8, 8);
    defer ruleset_allocator.free(ruleset);

    for (ruleset, 0..) |*byte, index|
        byte.* = if ((rule & (@as(u8,1) << @intCast(index))) != 0) '1' else '0';

    for (cells) |*cell|
        cell.* = 0;

    cells[termsize.col / 2] = 1;
    try printCells(cells);

    for (0..termsize.row - 2) |_| {
        try computeNextGen(&cells, ruleset, termsize.col);
        try printCells(cells);
    }
}