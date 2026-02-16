const std = @import("std");

pub const Entry = struct {
    crc: i32,
    ts: u32,

    ksz: u32,
    vsz: u32,
    key: []u8,
    val: []u8,
};
