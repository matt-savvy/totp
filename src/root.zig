const std = @import("std");
const testing = std.testing;
const Io = std.Io;

const zero_ms = Io.Timestamp.fromNanoseconds(std.time.epoch.unix);

// TODO step size must be non-zero
// TODO secret must be non-empty
// TODO result should be zero padded / return slice of digits

pub fn totp(secret: []const u8, now: Io.Timestamp, config: Config) u32 {
    const t = calcT(now, config.initial_timestamp, config.step_size);
    const t_big = std.mem.nativeToBig(u64, t);
    const t_input = std.mem.asBytes(&t_big);

    const hash = hotp(secret, t_input);
    const otp = truncate(hash, config.n_digits);
    return otp;
}

test totp {
    const secret = "12345678901234567890";
    const io = testing.io;
    const now = Io.Timestamp.now(io, .real);

    const otp_1 = totp(secret, now, .{});
    // six digits
    try testing.expect(otp_1 >= 100_000);
    try testing.expect(otp_1 <= 999_999);

    const otp_2 = totp(secret, now, .{ .n_digits = 3 });
    // six digits
    try testing.expect(otp_2 >= 100);
    try testing.expect(otp_2 <= 999);
}

const Config = struct {
    // TOTP options
    step_size: u64 = 30,
    initial_timestamp: Io.Timestamp = zero_ms,
    // HMAC options
    hash: type = std.crypto.auth.hmac.HmacSha1,
    n_digits: u8 = 6,
};

fn truncate(input: [20]u8, digit: u8) u32 {
    const last_byte = input[19];
    const offset: usize = last_byte & 0x0F;

    const dbc_bytes = input[offset .. offset + 4];
    var dbc: u32 = std.mem.bytesToValue(u32, dbc_bytes);
    dbc = std.mem.bigToNative(u32, dbc);
    dbc &= 0x7FFFFFFF; // mask out the first bit

    const denominator: u32 = @intCast(std.math.pow(u32, 10, digit));
    const result = @mod(dbc, denominator);
    return result;
}

// TODO refactor this so that counter is an int
fn hotp(key: []const u8, counter: []const u8) [20]u8 {
    const hmac = std.crypto.auth.hmac.HmacSha1;

    var buf: [20]u8 = undefined;
    // create(out: *[mac_length]u8, msg: []const u8, key: []const u8) void {
    hmac.create(&buf, counter, key);

    return buf;
}

// TODO add more test cases
// TODO add the outermost function with will get the current time and calculate the steps
// would be nice to have a private fn just for calculating the steps
// Keys SHOULD be of the length of the HMAC output to facilitate
//    interoperability.
// inner-totp
// - receive unix time as an arg
//     - alternatively, receive the number of steps T
//     - T = floor( unix time - initial time) / X) where X is the step size
//         - must support T larger than 32 bit
//
// - receive key
// -
// - call hotp
// -
fn totpInner(key: []const u8, t: u64) u32 {
    const digit = 8;
    // turn t into the message input

    // convert to big endian no matter what
    const t_big = std.mem.nativeToBig(u64, t);
    const t_input_1 = std.mem.asBytes(&t_big);
    const hash = hotp(key, t_input_1);

    return truncate(hash, digit);
}

test totpInner {
    const secret = "12345678901234567890";

    // 59 s
    const t = 1;
    const otp_1 = totpInner(secret, t);
    try testing.expectEqual(94287082, otp_1);
}

fn calcT(now_timestamp: Io.Timestamp, initial_timestamp: Io.Timestamp, step_size: u32) u64 {
    const now = Io.Timestamp.toSeconds(now_timestamp);
    const initial_time = Io.Timestamp.toSeconds(initial_timestamp);
    return @intCast(@divFloor(now - initial_time, step_size));
}

// TODO outer function

test calcT {
    const step_size = 30;
    const initial_unix_time = 0;
    const initial_timestamp = Io.Timestamp.fromNanoseconds(std.time.ns_per_s * initial_unix_time);

    const timestamp_0 = Io.Timestamp.fromNanoseconds(std.time.ns_per_s * 59);
    try testing.expectEqual(0x0000000000000001, calcT(timestamp_0, initial_timestamp, step_size));

    const timestamp_1 = Io.Timestamp.fromNanoseconds(std.time.ns_per_s * 1111111109);
    try testing.expectEqual(0x00000000023523EC, calcT(timestamp_1, initial_timestamp, step_size));

    const timestamp_2 = Io.Timestamp.fromNanoseconds(std.time.ns_per_s * 1111111111);
    try testing.expectEqual(0x00000000023523ED, calcT(timestamp_2, initial_timestamp, step_size));

    const timestamp_3 = Io.Timestamp.fromNanoseconds(std.time.ns_per_s * 1234567890);
    try testing.expectEqual(0x000000000273EF07, calcT(timestamp_3, initial_timestamp, step_size));
}

// TODO
// initialize a struct that includes the time step, starting time/offset time, hashing alg, number of digits, etc
// Q - how to make sure we're not just letting the secret hang out in ram and/or that it's not printable?

test hotp {
    // key as base 32 string
    _ = "3ESAY53ENE6YN6XMGXONNFH5WTAWOZIK";
    const key_decoded_1 = [_]u8{ 217, 36, 12, 119, 100, 105, 61, 134, 250, 236, 53, 220, 214, 148, 253, 180, 193, 103, 101, 10 };
    std.debug.assert(key_decoded_1.len == 20);
    // decoded
    const key_decoded = [_]u8{ 217, 36, 12, 119, 100, 105, 61, 134, 250, 236, 53, 220, 214, 148, 253, 180, 193, 103, 101, 10 };
    try testing.expectEqual(key_decoded, key_decoded_1);
    const counter = [8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 };
    const hash = hotp(&key_decoded, &counter);

    const digit = 6;
    const result = truncate(hash, digit);
    try testing.expectEqual(170824, result);
}

// tests from the RFC itself
test "hotp_values" {
    const secret = "12345678901234567890";
    const digit = 6;

    const hash_0 = hotp(secret, &[8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 });
    const expected_0 = [20]u8{ 0xcc, 0x93, 0xcf, 0x18, 0x50, 0x8d, 0x94, 0x93, 0x4c, 0x64, 0xb6, 0x5d, 0x8b, 0xa7, 0x66, 0x7f, 0xb7, 0xcd, 0xe4, 0xb0 };
    try testing.expectEqual(expected_0, hash_0);
    const trunc_0 = truncate(hash_0, digit);
    try testing.expectEqual(755224, trunc_0);

    const hash_1 = hotp(secret, &[8]u8{ 0, 0, 0, 0, 0, 0, 0, 1 });
    const expected_1 = [20]u8{ 0x75, 0xa4, 0x8a, 0x19, 0xd4, 0xcb, 0xe1, 0x00, 0x64, 0x4e, 0x8a, 0xc1, 0x39, 0x7e, 0xea, 0x74, 0x7a, 0x2d, 0x33, 0xab };
    try testing.expectEqual(expected_1, hash_1);
    const trunc_1 = truncate(hash_1, digit);
    try testing.expectEqual(287082, trunc_1);

    const hash_2 = hotp(secret, &[8]u8{ 0, 0, 0, 0, 0, 0, 0, 2 });
    const expected_2 = [20]u8{ 0x0b, 0xac, 0xb7, 0xfa, 0x08, 0x2f, 0xef, 0x30, 0x78, 0x22, 0x11, 0x93, 0x8b, 0xc1, 0xc5, 0xe7, 0x04, 0x16, 0xff, 0x44 };
    try testing.expectEqual(expected_2, hash_2);
    const trunc_2 = truncate(hash_2, digit);
    try testing.expectEqual(359152, trunc_2);

    const hash_3 = hotp(secret, &[8]u8{ 0, 0, 0, 0, 0, 0, 0, 3 });
    const expected_3 = [20]u8{ 0x66, 0xc2, 0x82, 0x27, 0xd0, 0x3a, 0x2d, 0x55, 0x29, 0x26, 0x2f, 0xf0, 0x16, 0xa1, 0xe6, 0xef, 0x76, 0x55, 0x7e, 0xce };
    try testing.expectEqual(expected_3, hash_3);
    const trunc_3 = truncate(hash_3, digit);
    try testing.expectEqual(969429, trunc_3);

    const hash_4 = hotp(secret, &[8]u8{ 0, 0, 0, 0, 0, 0, 0, 4 });
    const expected_4 = [20]u8{ 0xa9, 0x04, 0xc9, 0x00, 0xa6, 0x4b, 0x35, 0x90, 0x98, 0x74, 0xb3, 0x3e, 0x61, 0xc5, 0x93, 0x8a, 0x8e, 0x15, 0xed, 0x1c };
    try testing.expectEqual(expected_4, hash_4);
    const trunc_4 = truncate(hash_4, digit);
    try testing.expectEqual(338314, trunc_4);

    const hash_5 = hotp(secret, &[8]u8{ 0, 0, 0, 0, 0, 0, 0, 5 });
    const expected_5 = [20]u8{ 0xa3, 0x7e, 0x78, 0x3d, 0x7b, 0x72, 0x33, 0xc0, 0x83, 0xd4, 0xf6, 0x29, 0x26, 0xc7, 0xa2, 0x5f, 0x23, 0x8d, 0x03, 0x16 };
    try testing.expectEqual(expected_5, hash_5);
    const trunc_5 = truncate(hash_5, digit);
    try testing.expectEqual(254676, trunc_5);

    const hash_6 = hotp(secret, &[8]u8{ 0, 0, 0, 0, 0, 0, 0, 6 });
    const expected_6 = [20]u8{ 0xbc, 0x9c, 0xd2, 0x85, 0x61, 0x04, 0x2c, 0x83, 0xf2, 0x19, 0x32, 0x4d, 0x3c, 0x60, 0x72, 0x56, 0xc0, 0x32, 0x72, 0xae };
    try testing.expectEqual(expected_6, hash_6);
    const trunc_6 = truncate(hash_6, digit);
    try testing.expectEqual(287922, trunc_6);

    const hash_7 = hotp(secret, &[8]u8{ 0, 0, 0, 0, 0, 0, 0, 7 });
    const expected_7 = [20]u8{ 0xa4, 0xfb, 0x96, 0x0c, 0x0b, 0xc0, 0x6e, 0x1e, 0xab, 0xb8, 0x04, 0xe5, 0xb3, 0x97, 0xcd, 0xc4, 0xb4, 0x55, 0x96, 0xfa };
    try testing.expectEqual(expected_7, hash_7);
    const trunc_7 = truncate(hash_7, digit);
    try testing.expectEqual(162583, trunc_7);

    const hash_8 = hotp(secret, &[8]u8{ 0, 0, 0, 0, 0, 0, 0, 8 });
    const expected_8 = [20]u8{ 0x1b, 0x3c, 0x89, 0xf6, 0x5e, 0x6c, 0x9e, 0x88, 0x30, 0x12, 0x05, 0x28, 0x23, 0x44, 0x3f, 0x04, 0x8b, 0x43, 0x32, 0xdb };
    try testing.expectEqual(expected_8, hash_8);
    const trunc_8 = truncate(hash_8, digit);
    try testing.expectEqual(399871, trunc_8);

    const hash_9 = hotp(secret, &[8]u8{ 0, 0, 0, 0, 0, 0, 0, 9 });
    const expected_9 = [20]u8{ 0x16, 0x37, 0x40, 0x98, 0x09, 0xa6, 0x79, 0xdc, 0x69, 0x82, 0x07, 0x31, 0x0c, 0x8c, 0x7f, 0xc0, 0x72, 0x90, 0xd9, 0xe5 };
    try testing.expectEqual(expected_9, hash_9);
    const trunc_9 = truncate(hash_9, digit);
    try testing.expectEqual(520489, trunc_9);
}

test truncate {
    // number of digits our final code will be
    const digit: u8 = 6;
    // our hmac_result
    const input = [20]u8{ 0x1f, 0x86, 0x98, 0x69, 0x0e, 0x02, 0xca, 0x16, 0x61, 0x85, 0x50, 0xef, 0x7f, 0x19, 0xda, 0x8e, 0x94, 0x5b, 0x55, 0x5a };
    const result = truncate(input, digit);
    try testing.expectEqual(872921, result);
}
