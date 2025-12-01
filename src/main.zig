const std = @import("std");

const day_1 = @import("day_1.zig");

pub const Solution = struct {
    part_1: i64,
    part_2: i64,
};

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    const solution = try day_1.solve(stdin);

    try stdout.print("Part 1: {}\nPart 2: {}\n", .{ solution.part_1, solution.part_2 });

    try stdout.flush();
}
