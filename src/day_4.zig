const std = @import("std");

const Solution = @import("root").Solution;

const Map = struct {
    text: []u8,
    width: u32,
    height: u32,

    pub fn init(text: []u8) !@This() {
        var map: @This() = .{
            .text = text,
            .width = 0,
            .height = 0,
        };

        for (text, 0..) |char, i| {
            switch (char) {
                '.', '@' => {},
                '\n' => {
                    if (map.width == 0) map.width = @intCast(i);
                    map.height += 1;
                },
                else => return error.InvalidInput,
            }
        }

        return map;
    }

    pub fn access(self: *@This(), x: i32, y: i32) ?*u8 {
        if (x < 0 or x >= self.width) return null;
        if (y < 0 or y >= self.height) return null;
        return &self.text[@as(usize, @intCast(x)) + @as(usize, @intCast(y)) * (self.width + 1)];
    }
};

const offsets = [8]@Vector(2, i32){
    .{ -1, -1 },
    .{ 0, -1 },
    .{ 1, -1 },
    .{ -1, 0 },
    .{ 1, 0 },
    .{ -1, 1 },
    .{ 0, 1 },
    .{ 1, 1 },
};

pub fn solve(input: std.fs.File) !Solution {
    const allocator = std.heap.smp_allocator;
    const size = try input.getEndPos() - try input.getPos();
    const text = try allocator.alloc(u8, size);
    _ = try input.read(text);

    var map = try Map.init(text);

    var part_1: i64 = 0;
    for (0..map.height) |y| {
        for (0..map.width) |x| {
            const pos: @Vector(2, i32) = .{ @as(i32, @intCast(x)), @as(i32, @intCast(y)) };
            if (map.access(pos[0], pos[1]).?.* != '@') continue;
            var count: u8 = 0;
            for (offsets) |offset| {
                const new_pos = pos + offset;
                const tile = map.access(new_pos[0], new_pos[1]);
                if (tile) |char| {
                    if (char.* == '@') count += 1;
                }
            }
            if (count < 4) part_1 += 1;
        }
    }

    var part_2: i64 = 0;
    while (true) {
        var new_rolls_removed: bool = false;
        for (0..map.height) |y| {
            for (0..map.width) |x| {
                const pos: @Vector(2, i32) = .{ @as(i32, @intCast(x)), @as(i32, @intCast(y)) };
                const tile = map.access(pos[0], pos[1]).?;
                if (tile.* != '@') continue;
                var count: u8 = 0;
                for (offsets) |offset| {
                    const new_pos = pos + offset;
                    const nei = map.access(new_pos[0], new_pos[1]);
                    if (nei) |char| {
                        if (char.* == '@') count += 1;
                    }
                }
                if (count < 4) {
                    part_2 += 1;
                    tile.* = '.';
                    new_rolls_removed = true;
                }
            }
        }
        if (!new_rolls_removed) break;
    }

    return .{
        .part_1 = part_1,
        .part_2 = part_2,
    };
}
