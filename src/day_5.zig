const std = @import("std");

const Solution = @import("root").Solution;

const Token = union(enum) {
    number: []const u8,
    dash,
    newline,
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
                    '\n' => {
                        self.cur += 1;
                        return Token.newline;
                    },
                    ' ' => {
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

    pub fn peek(self: *@This()) Token {
        const saved = self.cur;
        const token = self.nextToken();
        self.cur = saved;
        return token;
    }
};

const Range = struct {
    start: u64,
    end: u64,

    pub fn isWithin(self: *const @This(), value: u64) bool {
        return self.start <= value and value <= self.end;
    }

    pub fn size(self: *const @This()) u64 {
        return self.end - self.start + 1;
    }
};

pub fn solve(input: std.fs.File) !Solution {
    const allocator = std.heap.smp_allocator;
    const size = try input.getEndPos() - try input.getPos();
    const text = try allocator.alloc(u8, size);
    defer allocator.free(text);
    _ = try input.read(text);

    var tokenizer = Tokenizer.init(text);
    var ranges: std.ArrayList(Range) = .{};
    defer ranges.deinit(allocator);

    while (true) {
        const start: u64 = blk: switch (tokenizer.nextToken()) {
            .number => |number_text| {
                break :blk try std.fmt.parseUnsigned(u64, number_text, 10);
            },
            else => return error.UnexpectedToken,
        };

        switch (tokenizer.nextToken()) {
            .dash => {},
            else => return error.UnexpectedToken,
        }

        const end: u64 = blk: switch (tokenizer.nextToken()) {
            .number => |number_text| {
                break :blk try std.fmt.parseUnsigned(u64, number_text, 10);
            },
            else => return error.UnexpectedToken,
        };

        try ranges.append(allocator, .{ .start = start, .end = end });

        switch (tokenizer.nextToken()) {
            .newline => {},
            else => return error.UnexpectedToken,
        }

        if (tokenizer.peek() == .newline) {
            _ = tokenizer.nextToken();
            break;
        }
    }

    var part_1: i64 = 0;
    while (true) {
        switch (tokenizer.nextToken()) {
            .number => |number_text| {
                const number = std.fmt.parseUnsigned(u64, number_text, 10) catch unreachable;
                for (ranges.items) |range| {
                    if (range.isWithin(number)) {
                        part_1 += 1;
                        break;
                    }
                }
            },
            .EOI => break,
            else => return error.UnexpectedToken,
        }

        switch (tokenizer.nextToken()) {
            .newline => {},
            .EOI => break,
            else => return error.UnexpectedToken,
        }
    }

    var part_2: i64 = 0;
    const compare = struct {
        pub fn inner(_: void, a: Range, b: Range) bool {
            return a.start < b.start;
        }
    }.inner;
    std.sort.pdq(Range, ranges.items, {}, compare);

    var rolling = ranges.items[0];
    for (ranges.items[1..]) |range| {
        if (range.start <= rolling.end) {
            rolling.end = @max(range.end, rolling.end);
            continue;
        }
        part_2 += @intCast(rolling.size());
        rolling = range;
    }
    part_2 += @intCast(rolling.size());

    return .{
        .part_1 = part_1,
        .part_2 = part_2,
    };
}
