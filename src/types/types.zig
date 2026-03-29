// This file contains public types used that is passed accross modules
// Like whole projects knows these
//
const std = @import("std");
const linux = std.os.linux;

pub const IoOperation = struct {
    type: IoOpType,
    fd: linux.fd_t,
};

pub const IoOpType = enum(u8) {
    read,
    write
};

