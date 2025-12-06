const std = @import("std");

const Solution = @import("root").Solution;

const Token = union(enum) {
    number: []const u8,
    plus,
    asterisk,
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
                    '+' => {
                        self.cur += 1;
                        return Token.plus;
                    },
                    '*' => {
                        self.cur += 1;
                        return Token.asterisk;
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
};

const Map = struct {
    tokens: []Token,
    width: u32,
    height: u32,

    pub fn init(tokens: []Token) !@This() {
        var map: @This() = .{
            .tokens = tokens,
            .width = 0,
            .height = 0,
        };

        for (tokens, 0..) |token, i| {
            switch (token) {
                .number, .plus, .asterisk, .EOI => {},
                .newline => {
                    if (map.width == 0) map.width = @intCast(i);
                    map.height += 1;
                },
                else => return error.InvalidInput,
            }
        }

        return map;
    }

    pub fn access(self: *@This(), x: i32, y: i32) ?*Token {
        if (x < 0 or x >= self.width) return null;
        if (y < 0 or y >= self.height) return null;
        return &self.tokens[@as(usize, @intCast(x)) + @as(usize, @intCast(y)) * (self.width + 1)];
    }
};

pub fn solve(input: std.fs.File) !Solution {
    const allocator = std.heap.smp_allocator;
    const size = try input.getEndPos() - try input.getPos();
    const text = try allocator.alloc(u8, size);
    defer allocator.free(text);
    _ = try input.read(text);

    var tokenizer = Tokenizer.init(text);
    var tokens: std.ArrayList(Token) = .{};
    while (true) {
        const token = tokenizer.nextToken();
        switch (token) {
            .number, .plus, .asterisk, .newline => {
                try tokens.append(allocator, token);
            },
            .EOI => {
                try tokens.append(allocator, token);
                break;
            },
            else => return error.UnexpectedToken,
        }
    }

    var map = try Map.init(tokens.items);
    var part_1: u64 = 0;
    for (0..map.width) |x| {
        const operation = map.access(@intCast(x), @intCast(map.height - 1)).?.*;
        var accumulator: u64 = 0;
        for (0..map.height - 1) |y| {
            const token = map.access(@intCast(x), @intCast(y)).?.*;
            const number: u64 = blk: switch (token) {
                .number => |number_text| {
                    break :blk try std.fmt.parseUnsigned(u64, number_text, 10);
                },
                else => return error.UnexpectedToken,
            };

            switch (operation) {
                .plus => {
                    accumulator += number;
                },
                .asterisk => {
                    if (accumulator == 0) accumulator = 1;
                    accumulator *= number;
                },
                else => return error.UnexpectedToken,
            }
        }
        part_1 += accumulator;
    }

    return .{
        .part_1 = @intCast(part_1),
        .part_2 = -1,
    };
}
