const std = @import("std");
const types = @import("types.zig");
const linux = std.os.linux;
const allocator  = std.heap.page_allocator;

const IOError = error{
  UnsupportedIoOperation
};

// The linux IO interface
// designed with IO uring, the core idea is to build on top of IO uring
// still learning by writing
const IO = @This();

ring: linux.IoUring,
completed: std.ArrayList(types.Completion),

pub fn init(entries: u13) !IO {
    const ring = try linux.IoUring.init(entries,  0);

    //TODO maybe different structure, this can potentially do dynamic allocation but should never do
    const completionList = try std.ArrayList(types.Completion).initCapacity(allocator, entries);

    return .{ .ring = ring, .completed = completionList };
}

pub fn deinit(self: *IO) void {
    self.ring.deinit();
}

pub fn Add(self: *IO, completion: *types.Completion) !void {
    const user_data = @intFromPtr(completion);
    switch (completion.op) {
        .read => |*r| self.ring.read(user_data, r.fd, r.buf, r.offset),
        .write => |*w| self.ring.read(user_data, w.fd, w.buf, w.offset),
        else => error.UnsupportedIoOperation
    }
}

pub fn Flush(self: *IO) !void {
    _ = self.ring;
}

pub fn flush_submissions(self: *IO) !u32 {
    return try self.ring.submit();
}

pub fn flush_completions(self: *IO, submitted: u322) !void {
    var i: usize = 0;
    while (i < submitted) : (i+=1){
        const cqe = try self.ring.copy_cqe();

        const completion: *const types.Completion = @ptrFromInt(cqe.user_data);
        completion.result = cqe.res;

        // need to find out and implement ring buffer in zig
        // self.completed.append(gpa: Allocator, item: Completion)
    }
}
