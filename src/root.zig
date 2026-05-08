const std = @import("std");
const testing = std.testing;
const Io = std.Io;

// totp calls hotp
// hotp needs truncate
// truncate
//
// test truncate {
//     const input_1 = [20]u8{ 5, 23, 56, 4, 11, 99, 121, 195, 202, 1, 23, 33, 55, 12, 50, 61, 234, 0, 7, 19 };
//     const result_1 = truncate(input_1);
//     try testing.expectEqual(result_1, [4]u8{0, 0, 0, 0});
// }


fn truncate(input: [20]u8, digit: u8) u32 {
    const last_byte = input[19];
    const offset: usize = last_byte & 0x0F;

    const dbc_bytes = input[offset..offset+4];
    var dbc: u32 = std.mem.bytesToValue(u32, dbc_bytes);
    dbc = std.mem.bigToNative(u32, dbc);
    dbc &= 0x7FFFFFFF; // mask out the first bit

    const denominator: u32 = @intCast(std.math.pow(u32, 10, digit));
    const result = @mod(dbc, denominator);
    return result;
}

// still need to calculate the hmac(key, counter)

fn hotp(key: []const u8, counter: []const u8) [20]u8 {
    const hmac = std.crypto.auth.hmac.HmacSha1;

    var buf: [20]u8 = undefined;
    // create(out: *[mac_length]u8, msg: []const u8, key: []const u8) void {
    hmac.create(&buf, counter, key);

    return buf;
}

test hotp {
    // key as base 32 string
    _ = "3ESAY53ENE6YN6XMGXONNFH5WTAWOZIK";
    // decoded
    const key_decoded = [_]u8{217, 36, 12, 119, 100, 105, 61, 134, 250, 236, 53, 220, 214, 148, 253, 180, 193, 103, 101, 10};
    const counter = [8]u8{ 0,  0,  0,  0,  0,  0,  0,  0 };
    const hash = hotp(&key_decoded, &counter);

    const digit = 6;
    const result = truncate(hash, digit);
    try testing.expectEqual(170824, result);
}

test truncate {
    // number of digits our final code will be
    const digit: u8 = 6;
    // our hmac_result
    const input = [20]u8{ 0x1f, 0x86, 0x98, 0x69, 0x0e, 0x02, 0xca, 0x16, 0x61, 0x85, 0x50, 0xef, 0x7f, 0x19, 0xda, 0x8e, 0x94, 0x5b, 0x55, 0x5a };
    const result = truncate(input, digit);
    try testing.expectEqual(872921, result);
}
