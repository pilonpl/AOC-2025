const std = @import("std");

const Solution = @import("root").Solution;

const Token = union(enum) {
    number: []const u8,
    dash,
    comma,
    invalid,
    EOI,
};

const Tokenizer = struct {
    text: []const u8,
    cur: usize = 0,

    const State = enum {
        start,
        number,
    };

    pub fn init(text: []const u8) @This() {
        return .{
            .text = text,
        };
    }

    fn currentChar(self: *@This()) u8 {
        if (self.cur == self.text.len) return 0;
        return self.text[self.cur];
    }

    pub fn nextToken(self: *@This()) Token {
        var number_start = self.cur;
        state: switch (State.start) {
            .start => {
                switch (self.currentChar()) {
                    0 => return Token.EOI,
                    '-' => {
                        self.cur += 1;
                        return Token.dash;
                    },
                    ',' => {
                        self.cur += 1;
                        return Token.comma;
                    },
                    '\n', ' ' => {
                        self.cur += 1;
                        number_start = self.cur;
                        continue :state .start;
                    },
                    '0'...'9' => continue :state .number,
                    else => return Token.invalid,
                }
            },
            .number => {
                self.cur += 1;
                switch (self.currentChar()) {
                    '0'...'9' => continue :state .number,
                    else => {
                        return Token{ .number = self.text[number_start..self.cur] };
                    },
                }
            },
        }
        return Token.EOI;
    }
};

fn part1InvalidIDs(start: u64, end: u64) u64 {
    var count: u64 = 0;
    for (start..end + 1) |id| {
        const digits = if (id == 0) 0 else std.math.log10_int(id) + 1;
        if (digits % 2 != 0) continue;
        const first_part = id % std.math.pow(u64, 10, @divExact(digits, 2));
        const second_part = @divTrunc(id, std.math.pow(u64, 10, @divExact(digits, 2)));
        if (first_part == second_part) count += id;
    }
    return count;
}

fn part2InvalidIDs(start: u64, end: u64) u64 {
    var count: u64 = 0;
    for (start..end + 1) |id| {
        const digits = if (id == 0) 0 else std.math.log10_int(id) + 1;
        j: for (2..digits + 1) |divisor| {
            if (digits % divisor != 0) continue;
            const mask = std.math.pow(u64, 10, @divExact(digits, divisor));
            const first_part = id % mask;
            var rolling = id;
            for (0..divisor - 1) |_| {
                rolling = @divTrunc(rolling, mask);
                if ((rolling % mask) != first_part) continue :j;
            }
            //std.debug.print("invalid id: {}\n", .{id});
            count += id;
            break;
        }
    }
    return count;
}

pub fn solve(input: std.fs.File) !Solution {
    const allocator = std.heap.smp_allocator;
    const size = try input.getEndPos() - try input.getPos();
    const text = try allocator.alloc(u8, size);
    _ = try input.read(text);

    var tokenizer = Tokenizer.init(text);
    var part_1: u64 = 0;
    var part_2: u64 = 0;
    while (true) {
        const interval_start: u64 = blk: switch (tokenizer.nextToken()) {
            .number => |num_text| {
                break :blk std.fmt.parseUnsigned(u64, num_text, 10) catch unreachable;
            },
            else => return error.unexpectedToken,
        };

        switch (tokenizer.nextToken()) {
            .dash => {},
            else => return error.unexpectedToken,
        }

        const interval_end: u64 = blk: switch (tokenizer.nextToken()) {
            .number => |num_text| {
                break :blk std.fmt.parseUnsigned(u64, num_text, 10) catch unreachable;
            },
            else => return error.unexpectedToken,
        };

        part_1 += part1InvalidIDs(interval_start, interval_end);
        part_2 += part2InvalidIDs(interval_start, interval_end);
        //std.debug.print("interval: {}, {}\n", .{ interval_start, interval_end });

        switch (tokenizer.nextToken()) {
            .comma => {},
            .EOI => break,
            else => return error.unexpectedToken,
        }
    }
    return .{
        .part_1 = @intCast(part_1),
        .part_2 = @intCast(part_2),
    };
}
