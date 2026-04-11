// This implementatinon is inspied by TigerBeetle's IO uring implemention
// Essentially taking what this codebase needs.
// https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig

const std = @import("std");
const types = @import("types.zig");
const linux = std.os.linux;
const queue = @import("../queue.zig");

const IOError = error{
  UnsupportedIoOperation
};

// The linux IO interface
// designed with IO uring, the core idea is to build on top of IO uring
// still learning by writingk
const IO = @This();

ring: linux.IoUring,
//will be used later on, i believe it's usefull and simple enough
unqueued: queue.SimpleQueueType(types.Completion) = queue.SimpleQueueType(types.Completion).init(),
completed: queue.SimpleQueueType(types.Completion) = queue.SimpleQueueType(types.Completion).init(),


pub fn init(size: u13) !IO {
    const ring = try linux.IoUring.init(size,  0);

    return .{ .ring = ring };
}

pub fn deinit(self: *IO) void {
    self.ring.deinit();
}

pub fn add(self: *IO, completion: *types.Completion) void {
    const sqe = self.ring.get_sqe() catch |err| switch (err) {
        error.SubmissionQueueFull => {
            self.unqueued.push(completion);
            return;
        },
    };

    completion.prep(sqe);
}

pub fn flush(self: *IO) !void {
    try self.flush_submissions();
    try self.flush_completions();

    // Add the completions, this is potentially a bug,
    // See good implementation at https://github.com/tigerbeetle/tigerbeetle/blob/bdf6da8599da58e14146eb6f2107ffc96360a980/src/io/linux.zig#L173
    // For that we need a queue that can be cleared, which our queue doesn't support for now.
    while (self.unqueued.pop()) |completion| {
        self.add(completion);
    }

    while (self.completed.pop()) |completion| {
        completion.callback(completion);
    }
}

pub fn flush_submissions(self: *IO) !void {
    while (true) {
        _ = self.ring.submit() catch |err| switch (err) {
            error.SignalInterrupt => continue,
            error.CompletionQueueOvercommitted, error.SystemResources => {
                try self.flush_completions();
                continue;
            },
            else => return err,
        };
    }
}

pub fn flush_completions(self: *IO) !void {
    var cqes: [256]linux.io_uring_cqe = undefined;
    while (true) {
        const completed = self.ring.copy_cqes(&cqes, 0) catch |err| switch (err) {
            error.SignalInterrupt => continue,
            else => return err,
        };

        for (cqes[0..completed]) |cqe| {
            const completion: *types.Completion = @ptrFromInt(cqe.user_data);
            completion.result = cqe.res;

            self.completed.push(completion);
        }

        if (completed < cqes.len) break;
    }
}

// -- Tests --

const posix = std.posix;

fn createTmpFile(data: []const u8) !posix.fd_t {
    const fd = try posix.open(
        "/tmp/lkv_test",
        .{ .ACCMODE = .RDWR, .CREAT = true, .TRUNC = true },
        0o644,
    );
    if (data.len > 0) {
        _ = try posix.write(fd, data);
        _ = linux.lseek(fd, 0, 0);
    }
    return fd;
}

fn noop(_: *types.Completion) void {}

test "write via IO layer, verify with posix read" {
    const payload = "hello io_uring";

    const fd = try createTmpFile("");
    defer posix.close(fd);

    var io = try IO.init(64);
    defer io.deinit();

    var buf: [payload.len]u8 = undefined;
    @memcpy(&buf, payload);

    var completion = types.Completion{
        .callback = &noop,
        .op = .{ .write = .{ .fd = fd, .buf = &buf, .offset = 0 } },
    };

    try io.add(&completion);
    try io.flush();

    try std.testing.expectEqual(@as(i32, payload.len), completion.result);

    _ = linux.lseek(fd, 0, 0);
    var readback: [payload.len]u8 = undefined;
    const n = try posix.read(fd, &readback);
    try std.testing.expectEqualStrings(payload, readback[0..n]);
}

test "read via IO layer returns correct data" {
    const expected = "read me back";

    const fd = try createTmpFile(expected);
    defer posix.close(fd);

    var io = try IO.init(64);
    defer io.deinit();

    var buf: [64]u8 = undefined;

    var completion = types.Completion{
        .callback = &noop,
        .op = .{ .read = .{ .fd = fd, .buf = &buf, .offset = 0 } },
    };

    try io.add(&completion);
    try io.flush();

    try std.testing.expect(completion.result > 0);
    const n: usize = @intCast(completion.result);
    try std.testing.expectEqualStrings(expected, buf[0..n]);
}
