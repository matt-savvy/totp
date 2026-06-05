const std = @import("std");
const Io = std.Io;
const Totp = @import("totp");
const Base32 = @import("base32.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var input_buf: [256]u8 = undefined;
    var stdin_file_reader = std.Io.File.stdin().reader(init.io, &input_buf);
    var stdin_reader = &stdin_file_reader.interface;
    const n = try stdin_reader.readSliceShort(&input_buf);
    const secret = input_buf[0..n];

    // assumes secret is a string representing a base32 value
    var secret_buf: [1024]u8 = undefined;
    const secret_len = try Base32.decode(secret, &secret_buf, init.gpa);
    const decoded_secret = secret_buf[0..secret_len];

    const now = Io.Timestamp.now(io, .real);
    // TODO get config from file/stdin
    const otp = try Totp.totp(init.gpa, decoded_secret, now, .{});
    defer gpa.free(otp);

    var output_buf: [32]u8 = undefined;
    var stdout_file_writer = std.Io.File.stdout().writer(init.io, &output_buf);
    const stdout_writer = &stdout_file_writer.interface;
    try stdout_writer.print("{s}", .{otp});
    try stdout_writer.flush();

    return;
}

test {
    _ = Base32;
}
