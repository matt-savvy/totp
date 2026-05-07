const std = @import("std");
const testing = std.testing;
const Io = std.Io;

// totp calls hotp
// hotp needs truncate
// truncate

/// Step 2: Generate a 4-byte string (Dynamic Truncation)
///    Let Sbits = DT(HS)   //  DT, defined below,
///                         //  returns a 31-bit string
///
///    Step 3: Compute an HOTP value
///    Let Snum  = StToNum(Sbits)   // Convert S to a number in
///                                     0...2^{31}-1
///    Return D = Snum mod 10^Digit //  D is a number in the range
///                                     0...10^{Digit}-1
fn truncate(_: [20]u8) [4]u8 {
    const masked_value: u8 = 0x5a & 0xf;
    std.debug.print("{d}\n", .{masked_value});
    // Let OffsetBits be the low-order 4 bits of String[19]
    // const offset_bits = string[0..4];
    // Offset = StToNum(OffsetBits) // 0 <= OffSet <= 15
    // StToNum takes binary and returns a base 10.
    // const offset =
    const output = [4]u8{ 0, 0, 0, 0 };
    return output;
}
//
// test truncate {
//     const input_1 = [20]u8{ 5, 23, 56, 4, 11, 99, 121, 195, 202, 1, 23, 33, 55, 12, 50, 61, 234, 0, 7, 19 };
//     const result_1 = truncate(input_1);
//     try testing.expectEqual(result_1, [4]u8{0, 0, 0, 0});
// }

fn htop(input: [20]u8, digit: u8) u32 {
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

fn stToNum(input: []const u1) u32 {
    var result: u32 = 0;
    var shift_count: u3 = 0;
    for (input) |byte| {
        const casted_byte: u32 = byte;
        result |= (casted_byte << (2 - shift_count));
        shift_count += 1;
    }
    return result;
}

test stToNum {
    const st = [_]u1{ 1, 1, 0 };
    try testing.expectEqual(6, stToNum(&st));
}

// still need to calculate the hmac(key, counter)

test htop {
    // number of digits our final code will be
    const digit: u8 = 6;
    // our hmac_result
    const input = [20]u8{ 0x1f, 0x86, 0x98, 0x69, 0x0e, 0x02, 0xca, 0x16, 0x61, 0x85, 0x50, 0xef, 0x7f, 0x19, 0xda, 0x8e, 0x94, 0x5b, 0x55, 0x5a };
    const result = htop(input, digit);
    try testing.expectEqual(872921, result);
}
