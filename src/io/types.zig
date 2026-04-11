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
    result: i32 = -1,

    //this is mark completion as queueable to linked list, see ../queue.zig
    node: std.DoublyLinkedList.Node = .{ .prev = null, .next = null },

    pub fn prep(self: *Completion, sqe: *linux.io_uring_sqe) void {

        sqe.user_data = @intFromPtr(self);

        switch (self.op) {
            .read => |*r| sqe.prep_read(r.fd, r.buf, r.offset),
            .write => |*w| sqe.prep_write(w.fd, w.buf, w.offset),
        }
    }
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

