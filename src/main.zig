const std = @import("std");

const day_1 = @import("day_1.zig");
const day_2 = @import("day_2.zig");
const day_3 = @import("day_3.zig");
const day_4 = @import("day_4.zig");

pub const Solution = struct {
    part_1: i64,
    part_2: i64,
};

const usage =
    \\Usage: aoc <day> <input_file_path>
    \\Days 1 to 4 are available
;

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;

    const args = try std.process.argsAlloc(allocator);
    if (args.len != 3) {
        try stderr.print("{s}\n", .{usage});
        try stderr.flush();
        std.process.exit(1);
    }

    const path = args[2];
    const file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch {
        try stderr.print("Could not open file: {s}\n", .{path});
        try stderr.flush();
        std.process.exit(1);
    };
    defer file.close();

    const day = std.fmt.parseUnsigned(u8, args[1], 0) catch {
        try stderr.print("{s}\n", .{usage});
        try stderr.flush();
        std.process.exit(1);
    };

    const solution: Solution = blk: {
        if (day == 1) break :blk try day_1.solve(file);
        if (day == 2) break :blk try day_2.solve(file);
        if (day == 3) break :blk try day_3.solve(file);
        if (day == 4) break :blk try day_4.solve(file);
        try stderr.print("{s}\n", .{usage});
        try stderr.flush();
        std.process.exit(1);
    };

    try stdout.print("Part 1: {}\nPart 2: {}\n", .{ solution.part_1, solution.part_2 });
    try stdout.flush();
}
