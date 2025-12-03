const std = @import("std");

const Solution = @import("root").Solution;

const Token = union(enum) {
    number: []const u8,
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
                    '\n', ' ' => {
                        self.cur += 1;
                        number_start = self.cur;
                        continue :state .start;
                    },
                    '1'...'9' => continue :state .number,
                    else => return Token.invalid,
                }
            },
            .number => {
                self.cur += 1;
                switch (self.currentChar()) {
                    '1'...'9' => continue :state .number,
                    else => {
                        return Token{ .number = self.text[number_start..self.cur] };
                    },
                }
            },
        }
        return Token.EOI;
    }
};

fn getLargestJoltage2Batteries(number_text: []const u8) u8 {
    var largest_left: usize = 0;
    for (number_text[1 .. number_text.len - 1], 1..) |char, i| {
        if (char > number_text[largest_left]) largest_left = i;
    }
    var largest_right: usize = largest_left + 1;
    for (number_text[largest_left + 1 ..], largest_left + 1..) |char, i| {
        if (char > number_text[largest_right]) largest_right = i;
    }

    return 10 * (number_text[largest_left] - '0') + (number_text[largest_right] - '0');
}

fn getLargestJoltage(number_text: []const u8, batteries: u8) u64 {
    var output: u64 = 0;
    var start: usize = 0;
    for (0..batteries) |i| {
        var char: u8 = 0;
        for (start..number_text.len - (batteries - i - 1)) |j| {
            if (number_text[j] > char) {
                char = number_text[j];
                start = j + 1;
            }
        }
        output *= 10;
        output += char - '0';
    }
    return output;
}

pub fn solve(input: std.fs.File) !Solution {
    const allocator = std.heap.smp_allocator;
    const size = try input.getEndPos() - try input.getPos();
    const text = try allocator.alloc(u8, size);
    _ = try input.read(text);

    var part_1: u64 = 0;
    var part_2: u64 = 0;

    var tokenizer = Tokenizer.init(text);
    loop: while (true) {
        switch (tokenizer.nextToken()) {
            .number => |number_text| {
                part_1 += getLargestJoltage2Batteries(number_text);
                part_2 += getLargestJoltage(number_text, 12);
                //std.debug.print("{s}, {}, {}\n", .{ number_text, getLargestJoltage2Batteries(number_text), getLargestJoltage(number_text, 2) });
            },
            .EOI => break :loop,
            else => return error.UnexpectedToken,
        }
    }

    return .{
        .part_1 = @intCast(part_1),
        .part_2 = @intCast(part_2),
    };
}
