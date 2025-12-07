const std = @import("std");

const Solution = @import("root").Solution;

const Map = struct {
    text: []u8,
    width: u32,
    height: u32,
    start: @Vector(2, i32),
    splitter_count: u32,

    pub fn init(text: []u8) !@This() {
        var map: @This() = .{
            .text = text,
            .width = 0,
            .height = 0,
            .start = undefined,
            .splitter_count = 0,
        };

        var start: ?@Vector(2, i32) = null;
        for (text, 0..) |char, i| {
            switch (char) {
                '.' => {},
                '^' => map.splitter_count += 1,
                'S' => {
                    if (start != null) return error.InvalidInput;
                    const x = if (map.width == 0) i else i % (map.width + 1);
                    start = .{ @intCast(x), @intCast(map.height) };
                },
                '\n' => {
                    if (map.width == 0) map.width = @intCast(i);
                    map.height += 1;
                },
                else => return error.InvalidInput,
            }
        }

        if (start) |pos| {
            map.start = pos;
        } else {
            return error.InvalidInput;
        }

        return map;
    }

    pub fn access(self: *@This(), pos: @Vector(2, i32)) ?*u8 {
        if (pos[0] < 0 or pos[0] >= self.width) return null;
        if (pos[1] < 0 or pos[1] >= self.height) return null;
        return &self.text[@as(usize, @intCast(pos[0])) + @as(usize, @intCast(pos[1])) * (self.width + 1)];
    }
};

fn trackBeam(map: *Map, pos: @Vector(2, i32), memo: *std.AutoHashMap(@Vector(2, i32), u64)) !u64 {
    if (memo.getEntry(pos)) |entry| {
        return entry.value_ptr.*;
    }
    var current_pos = pos;
    while (true) {
        const tile = if (map.access(current_pos)) |tile| tile.* else return 0;
        if (tile == '^') break;
        current_pos += .{ 0, 1 };
    }
    const value = try trackBeam(map, current_pos + @Vector(2, i32){ -1, 0 }, memo) +
        try trackBeam(map, current_pos + @Vector(2, i32){ 1, 0 }, memo) +
        1;
    try memo.put(pos, value);
    return value;
}

pub fn solve(input: std.fs.File) !Solution {
    const allocator = std.heap.smp_allocator;
    const size = try input.getEndPos() - try input.getPos();
    const text = try allocator.alloc(u8, size);
    defer allocator.free(text);
    _ = try input.read(text);

    var map = try Map.init(text);

    var memo = std.AutoHashMap(@Vector(2, i32), u64).init(allocator);
    defer memo.deinit();
    try memo.ensureTotalCapacity(map.splitter_count * 2 + 1);
    const part_2 = try trackBeam(&map, map.start, &memo) + 1;

    var part_1: u64 = 0;
    for (0..map.height - 1) |y| {
        for (0..map.width) |x| {
            const tile = map.access(.{ @intCast(x), @intCast(y) }).?;
            switch (tile.*) {
                '.', '^' => {},
                'S', '|' => {
                    const down = map.access(.{ @intCast(x), @intCast(y + 1) }).?;
                    switch (down.*) {
                        '.', '|' => down.* = '|',
                        '^' => {
                            const left = map.access(.{ @intCast(x - 1), @intCast(y + 1) }) orelse return error.InvalidInput;
                            left.* = '|';
                            const right = map.access(.{ @intCast(x + 1), @intCast(y + 1) }) orelse return error.InvalidInput;
                            right.* = '|';
                            part_1 += 1;
                        },
                        else => return error.InvalidInput,
                    }
                },
                else => return error.InvalidInput,
            }
        }
    }

    return .{
        .part_1 = @intCast(part_1),
        .part_2 = @intCast(part_2),
    };
}
