const std = @import("std");
const linux = std.os.linux;

// pub const Operation = struct {
//     type: Type,
//     fd: linux.fd_t,
// };
//
// pub const Type = enum(u8) {
// };
//

pub const Completion = struct {
    callback: *const fn (*Completion) void,
    op: Operation,
    result: i32
};

pub const Operation = union(enum) {
    read: struct {
        fd: linux.fd_t,
        buf: []u8,
        offset: u64,
    },
    write: struct {
        fd: linux.fd_t,
        buf: []u8,
        offset: u64,
    }
};


// test "test operation" {
//     const op = Operation{ .read = .{ .fd = 1 }};
// }

