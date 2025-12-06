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

fn Map(comptime T: type) type {
    return struct {
        tiles: []T,
        width: u32,
        height: u32,

        pub fn init(tiles: []T) !@This() {
            var map: @This() = .{
                .tiles = tiles,
                .width = 0,
                .height = 0,
            };

            if (T == Token) {
                for (tiles, 0..) |tile, i| {
                    switch (tile) {
                        .number, .plus, .asterisk, .EOI => {},
                        .newline => {
                            if (map.width == 0) map.width = @intCast(i);
                            map.height += 1;
                        },
                        else => return error.InvalidInput,
                    }
                }
            }
            if (T == u8) {
                for (tiles, 0..) |tile, i| {
                    switch (tile) {
                        ' ', '+', '*', '0'...'9' => {},
                        '\n' => {
                            if (map.width == 0) map.width = @intCast(i);
                            map.height += 1;
                        },
                        else => return error.InvalidInput,
                    }
                }
            }

            return map;
        }

        pub fn access(self: *@This(), x: i32, y: i32) ?*T {
            if (x < 0 or x >= self.width) return null;
            if (y < 0 or y >= self.height) return null;
            return &self.tiles[@as(usize, @intCast(x)) + @as(usize, @intCast(y)) * (self.width + 1)];
        }
    };
}

pub fn solve(input: std.fs.File) !Solution {
    const allocator = std.heap.smp_allocator;
    const size = try input.getEndPos() - try input.getPos();
    const text = try allocator.alloc(u8, size);
    defer allocator.free(text);
    _ = try input.read(text);

    var tokenizer = Tokenizer.init(text);
    var tokens: std.ArrayList(Token) = .{};
    defer tokens.deinit(allocator);
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

    var token_map = try Map(Token).init(tokens.items);
    var part_1: u64 = 0;
    for (0..token_map.width) |x| {
        const operation = token_map.access(@intCast(x), @intCast(token_map.height - 1)).?.*;
        var accumulator: u64 = 0;

        for (0..token_map.height - 1) |y| {
            const token = token_map.access(@intCast(x), @intCast(y)).?.*;

            const number: u64 = switch (token) {
                .number => |number_text| try std.fmt.parseUnsigned(u64, number_text, 10),
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

    var char_map = try Map(u8).init(text);
    var part_2: u64 = 0;
    var block_x: i32 = 0;
    var accumulator: u64 = 0;
    for (0..char_map.width) |x| {
        const operator = char_map.access(@intCast(block_x), @intCast(char_map.height - 1)).?.*;
        var number: u64 = 0;

        for (0..char_map.height - 1) |y| {
            const char = char_map.access(@intCast(x), @intCast(y)).?.*;
            switch (char) {
                ' ' => {},
                '0'...'9' => |digit_ascii| {
                    number *= 10;
                    number += digit_ascii - '0';
                },
                else => return error.InvalidInput,
            }
        }

        if (number == 0) {
            block_x = @intCast(x + 1);
            part_2 += accumulator;
            accumulator = 0;
        } else if (operator == '+') {
            accumulator += number;
        } else if (operator == '*') {
            if (accumulator == 0) accumulator = 1;
            accumulator *= number;
        } else {
            return error.InvalidInput;
        }
    }
    part_2 += accumulator;

    return .{
        .part_1 = @intCast(part_1),
        .part_2 = @intCast(part_2),
    };
}
