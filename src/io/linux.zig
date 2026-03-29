const std = @import("std");
const types = @import("../types/types.zig");
const linux = std.os.linux;

// The linux IO interface
// designed with IO uring, the core idea is to build on top of IO uring
// still learning by writing
const IO = @This();

ring: linux.IoUring,

pub fn init(entries: u13) !IO {
    const ring = try linux.IoUring.init(entries,  0);

    return IO{ .ring = ring };
}

pub fn deinit(self: *IO) void {
    self.ring.deinit();
}

pub fn AddIo(self: *IO, op: types.IoOperation) !void {
    switch (op.type) {
        types.IoOpType.read => self.ring.read

    }
}

