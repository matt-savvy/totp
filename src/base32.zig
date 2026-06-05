const std = @import("std");
const testing = std.testing;

/// Represents 8 x 5-bit that will be decoded into 5 x 8-bit. Use packed struct
/// because its memory layout is well defined and each u5 will take up exactly
/// 5 bits.
const InputGroup = packed struct {
    a: u5,
    b: u5,
    c: u5,
    d: u5,
    e: u5,
    f: u5,
    g: u5,
    h: u5,
};

/// decodes a string representing values in base32 to
/// the bytes. only accepts encoded strings that evenly divide into
/// bytes (as in, no padding characters).
/// Caller owns the memory.
pub fn decode(input: []const u8, output_buf: *[1024]u8, _: std.mem.Allocator) !usize {
    // Proceeding from left to right, a 40-bit input group is formed by
    // concatenating 5 8bit input groups. These 40 bits are then treated as 8
    // concatenated 5-bit groups, each of which is translated into a single
    // character in the base 32 alphabet.  When a bit stream is encoded via
    // the base 32 encoding, the bit stream must be presumed to be ordered
    // with the most-significant- bit first.  That is, the first bit in the
    // stream will be the high- order bit in the first 8bit byte, the eighth
    // bit will be the low- order bit in the first 8bit byte, and so on.

    // Each 5-bit group is used as an index into an array of 32 printable
    // characters.

    // to decode
    // break into groups of 8 base32 chars
    // convert to 8 x u5 indexes
    // reinterpret those 8 x u5 indexes as 5 x u8

    var input_idx: usize = 0;
    var output_idx: usize = 0;

    outer: while (input_idx < input.len) {
        var chunk: [8]u8 = undefined;
        var chunk_idx: usize = 0;
        while (chunk_idx < 8) : (input_idx += 1) {
            if (input_idx >= input.len) {
                if (chunk_idx == 0) {
                    break :outer;
                }
                return error.InvalidBase32;
            }
            const char = input[input_idx];
            // skip spaces, newlines
            const skip = switch (char) {
                ' ' => true,
                '\n' => true,
                else => false,
            };
            if (skip) {
                continue;
            }
            chunk[chunk_idx] = char;
            chunk_idx += 1;
        }

        var chunk_decoded: [8]u5 = undefined;
        for (chunk, 0..) |char, i| {
            chunk_decoded[i] = decodeChar(char);
        }

        const eight_fives: InputGroup = InputGroup{
            .a = chunk_decoded[7],
            .b = chunk_decoded[6],
            .c = chunk_decoded[5],
            .d = chunk_decoded[4],
            .e = chunk_decoded[3],
            .f = chunk_decoded[2],
            .g = chunk_decoded[1],
            .h = chunk_decoded[0],
        };

        var bytes: [5]u8 = @bitCast(eight_fives);
        std.mem.reverse(u8, &bytes);

        @memcpy(output_buf[output_idx .. output_idx + 5], &bytes);
        output_idx += 5;
    }
    return output_idx;
}

test decode {
    var buf: [1024]u8 = undefined;
    const input_1 = "2PKGTJMKCDGE4VQY37Q4NXUQMZKRNXPM";
    const expected_1 = [_]u8{ 211, 212, 105, 165, 138, 16, 204, 78, 86, 24, 223, 225, 198, 222, 144, 102, 85, 22, 221, 236 };
    const len_1 = try decode(input_1, &buf, testing.allocator);
    const result_1 = buf[0..len_1];
    try testing.expectEqualSlices(u8, &expected_1, result_1);

    const input_2 = "SNNYKHMIJBLU4E3M";
    const expected_2 = [_]u8{ 147, 91, 133, 29, 136, 72, 87, 78, 19, 108 };
    const len_2 = try decode(input_2, &buf, testing.allocator);
    const result_2 = buf[0..len_2];
    try testing.expectEqualSlices(u8, &expected_2, result_2);

    // treat lowercase as uppercase
    const input_3 = "snnykhmijblu4e3m";
    const expected_3 = [_]u8{ 147, 91, 133, 29, 136, 72, 87, 78, 19, 108 };
    const len_3 = try decode(input_3, &buf, testing.allocator);
    const result_3 = buf[0..len_3];
    try testing.expectEqualSlices(u8, &expected_3, result_3);

    // discard spaces, newlines
    const input_4 = "SNNY KHMI JBLU 4E3M\n";
    const expected_4 = [_]u8{ 147, 91, 133, 29, 136, 72, 87, 78, 19, 108 };
    const len_4 = try decode(input_4, &buf, testing.allocator);
    const result_4 = buf[0..len_4];
    try testing.expectEqualSlices(u8, &expected_4, result_4);

    // return error for incomplete base32
    const input_5 = "SNNY KHMI JBLU";
    const result_5 = decode(input_5, &buf, testing.allocator);
    try testing.expectError(error.InvalidBase32, result_5);
}

fn decodeChar(char: u8) u5 {
    return decoder: switch (char) {
        'a'...'z' => {
            continue :decoder (char - 0x20);
        },
        'A' => 0,
        'B' => 1,
        'C' => 2,
        'D' => 3,
        'E' => 4,
        'F' => 5,
        'G' => 6,
        'H' => 7,
        'I' => 8,
        'J' => 9,
        'K' => 10,
        'L' => 11,
        'M' => 12,
        'N' => 13,
        'O' => 14,
        'P' => 15,
        'Q' => 16,
        'R' => 17,
        'S' => 18,
        'T' => 19,
        'U' => 20,
        'V' => 21,
        'W' => 22,
        'X' => 23,
        'Y' => 24,
        'Z' => 25,
        '2' => 26,
        '3' => 27,
        '4' => 28,
        '5' => 29,
        '6' => 30,
        '7' => 31,
        else => unreachable,
    };
}
