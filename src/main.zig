const std = @import("std");
const Io = std.Io;
const Totp = @import("totp");
const Base32 = @import("base32.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    // TODO get secret from file/stdin
    const secret = "SNNYKHMIJBLU4E3M";
    // assumes secret is a string representing a base32 value
    const decoded_secret: []u8 = try Base32.decode(secret, init.gpa);
    defer gpa.free(decoded_secret);

    const now = Io.Timestamp.now(io, .real);
    // TODO get config from file/stdin
    const otp = try Totp.totp(init.gpa, decoded_secret, now, .{});
    defer gpa.free(otp);

    // TODO write to std out without debug
    std.debug.print("{s}\n", .{otp});
    return;
}

// TODO move "integration" level test here
