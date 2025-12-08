const std = @import("std");

const Solution = @import("root").Solution;

const Token = union(enum) {
    number: []const u8,
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
                    ',' => {
                        self.cur += 1;
                        return Token.comma;
                    },
                    ' ', '\n' => {
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

const Node = struct {
    pos: @Vector(3, f32),
    circuit_id: u32,

    pub fn distance(self: *const @This(), node: *const @This()) f32 {
        const x = std.math.pow(f32, self.pos[0] - node.pos[0], 2);
        const y = std.math.pow(f32, self.pos[1] - node.pos[1], 2);
        const z = std.math.pow(f32, self.pos[2] - node.pos[2], 2);
        return std.math.sqrt(x + y + z);
    }
};

const Edge = struct {
    from: u32,
    to: u32,
};

const Graph = struct {
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(Node),
    next_id: u32,
    skip: std.AutoHashMap(Edge, void),

    pub fn init(allocator: std.mem.Allocator, tokenizer: *Tokenizer) !@This() {
        var graph: @This() = .{
            .allocator = allocator,
            .nodes = .{},
            .next_id = 0,
            .skip = std.AutoHashMap(Edge, void).init(allocator),
        };

        while (true) {
            const x = switch (tokenizer.nextToken()) {
                .number => |number_text| try std.fmt.parseFloat(f32, number_text),
                .EOI => break,
                else => return error.UnexpectedToken,
            };

            switch (tokenizer.nextToken()) {
                .comma => {},
                else => return error.UnexpectedToken,
            }

            const y = switch (tokenizer.nextToken()) {
                .number => |number_text| try std.fmt.parseFloat(f32, number_text),
                else => return error.UnexpectedToken,
            };

            switch (tokenizer.nextToken()) {
                .comma => {},
                else => return error.UnexpectedToken,
            }

            const z = switch (tokenizer.nextToken()) {
                .number => |number_text| try std.fmt.parseFloat(f32, number_text),
                else => return error.UnexpectedToken,
            };

            try graph.nodes.append(allocator, .{ .pos = .{ x, y, z }, .circuit_id = graph.next_id });
            graph.next_id += 1;
        }

        return graph;
    }

    pub fn deinit(self: *@This()) void {
        self.skip.deinit();
        self.nodes.deinit(self.allocator);
    }

    pub fn isConnected(self: *const @This(), node_1: u32, node_2: u32) bool {
        return self.nodes.items[node_1].circuit_id == self.nodes.items[node_2].circuit_id;
    }

    pub fn connect(self: *@This(), node_1: u32, node_2: u32) void {
        const target_id = self.nodes.items[node_1].circuit_id;
        const replaced_id = self.nodes.items[node_2].circuit_id;
        for (self.nodes.items) |*node| {
            if (node.circuit_id != replaced_id) continue;
            node.circuit_id = target_id;
        }
    }

    pub fn distance(self: *const @This(), node_1: u32, node_2: u32) f32 {
        return self.nodes.items[node_1].distance(self.nodes.items[node_2]);
    }

    pub fn isOneCircuit(self: *const @This()) bool {
        const id = self.nodes.items[0].circuit_id;
        for (self.nodes.items[1..]) |*node| {
            if (node.circuit_id != id) return false;
        }
        return true;
    }

    pub fn connectClosests(self: *@This()) !Edge {
        var best_distance: f32 = std.math.inf(f32);
        var best_edge: ?Edge = null;
        for (0..self.nodes.items.len - 1) |i| {
            for (i + 1..self.nodes.items.len) |j| {
                const node_1 = &self.nodes.items[i];
                const node_2 = &self.nodes.items[j];
                const node_distance = node_1.distance(node_2);
                const edge: Edge = .{ .from = @intCast(i), .to = @intCast(j) };

                if (node_distance > best_distance) continue;
                if (self.skip.contains(edge)) continue;

                best_distance = node_distance;
                best_edge = edge;
            }
        }
        if (best_edge) |edge| {
            if (!self.isConnected(edge.from, edge.to)) {
                self.connect(edge.from, edge.to);
            }
            std.debug.assert(edge.from < edge.to);
            try self.skip.put(edge, {});
            return edge;
        } else {
            return error.TooManyCycles;
        }
    }
};

pub fn solve(input: std.fs.File, args: []const []const u8) !Solution {
    const allocator = std.heap.smp_allocator;
    const file_size = try input.getEndPos() - try input.getPos();
    const text = try allocator.alloc(u8, file_size);
    defer allocator.free(text);
    _ = try input.read(text);

    var tokenizer = Tokenizer.init(text);
    var graph = try Graph.init(allocator, &tokenizer);
    defer graph.deinit();
    const cycles = if (args.len > 0) try std.fmt.parseUnsigned(u32, args[0], 10) else 1000;

    try graph.skip.ensureTotalCapacity(@intCast(graph.nodes.items.len));

    for (0..cycles) |_| {
        _ = try graph.connectClosests();
    }

    var part_1: u64 = 1;
    {
        const circuit_sizes = try allocator.alloc(u32, graph.next_id);
        defer allocator.free(circuit_sizes);
        @memset(circuit_sizes, 0);
        for (graph.nodes.items) |*node| {
            circuit_sizes[node.circuit_id] += 1;
        }

        for (0..3) |_| {
            var max_index: usize = 0;
            for (circuit_sizes, 0..) |size, i| {
                if (size > circuit_sizes[max_index]) max_index = i;
            }
            part_1 *= circuit_sizes[max_index];
            circuit_sizes[max_index] = 0;
        }
    }

    const edge: Edge = blk: while (true) {
        const edge = try graph.connectClosests();
        if (!graph.isOneCircuit()) continue;
        break :blk edge;
    };
    // f32 is not precise enough to first multiply it and then convert to int
    const part_2 = @as(u64, @intFromFloat(graph.nodes.items[edge.from].pos[0])) *
        @as(u64, @intFromFloat(graph.nodes.items[edge.to].pos[0]));

    return .{
        .part_1 = @intCast(part_1),
        .part_2 = @intCast(part_2),
    };
}
