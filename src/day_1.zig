const std = @import("std");

const Solution = @import("root").Solution;

pub fn solve(input: std.fs.File) !Solution {
    var reader = blk: {
        var reader_buffer: [1024]u8 = undefined;
        var reader = input.reader(&reader_buffer);
        break :blk &reader.interface;
    };

    var dial: i32 = 50;
    var sign: i32 = 1;
    var number: u32 = 0;
    var part_1: u32 = 0;
    var part_2: u32 = 0;
    while (true) {
        var char: u8 = reader.takeByte() catch 0;
        back: switch (char) {
            0 => break,
            'r', 'R' => {
                sign = 1;
            },
            'l', 'L' => {
                sign = -1;
            },
            '0'...'9' => {
                while (std.ascii.isDigit(char)) {
                    const digit = char - '0';
                    number *= 10;
                    number += digit;
                    char = reader.takeByte() catch 0;
                }
                continue :back char;
            },
            '\n' => {
                //dial += sign * number;
                for (0..number) |_| {
                    dial += sign;
                    dial = @mod(dial, 100);
                    if (dial == 0) part_2 += 1;
                }

                if (dial == 0) {
                    part_1 += 1;
                }

                number = 0;
            },
            else => return error.InvalidInput,
        }
    }

    return .{
        .part_1 = part_1,
        .part_2 = part_2,
    };
}
