const std = @import("std");
const lkv = @import("lkv");
const IO = @import("io/linux.zig");
const iotypes = @import("io/types.zig");
const linux = std.os.linux;
const posix = std.posix;

const print = std.debug.print;

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.

    const fd = try createTmpFile("hellooo there");
    defer posix.close(fd);

    var io = try IO.init(64);
    defer io.deinit();

    var buf: [4096]u8 = undefined;
    var completion = iotypes.Completion{
        .callback = callback,
        .op = .{ .read = .{
            .buf = &buf,
            .fd = fd,
            .offset = 0,
        }},
    };

    io.add(&completion);
    try io.flush();
}

fn callback(c: *iotypes.Completion) void {
    switch (c.op) {
        .read => |*r| print("IO done, result={s}\n", .{r.buf[0..@intCast(c.result)]}),
        else => print("yey", .{})
    }
}

fn createTmpFile(data: []const u8) !posix.fd_t {
    const fd = try posix.open(
        "test.txt",
        .{ .ACCMODE = .RDWR, .CREAT = true, .TRUNC = true },
        0o644,
    );
    if (data.len > 0) {
        _ = try posix.write(fd, data);
        _ = linux.lseek(fd, 0, 0);
    }
    return fd;
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}

test "how to work with linux io uring" {
    var ring = try linux.IoUring.init(64, 0);
    defer ring.deinit();

    const nop_sqe = try ring.get_sqe();
    nop_sqe.prep_nop();
    nop_sqe.user_data = 1;


    var buf: [128]u8 = undefined;
    const read_sqe = try ring.get_sqe();

    read_sqe.prep_read(std.fs.File.stdout().handle, &buf, 0);
    read_sqe.user_data = 2;

    const submitted = try ring.submit();

    var i: usize = 0;
    while (i<submitted) : (i+=1) {
        const cqe = try ring.copy_cqe();

        std.debug.print("cqe user_data={d} res={d}\n", .{cqe.user_data, cqe.res});
    }
}
