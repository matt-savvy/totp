const std = @import("std");
const Io = std.Io;
const Totp = @import("totp");

pub fn main(init: std.process.Init) !void {
    // TODO get secret from file/stdin
    const secret = "12345678901234567890";
    const io = init.io;
    const now = Io.Timestamp.now(io, .real);
    const otp = Totp.totp(secret, now, .{});
    // TODO write to std out without otp
    std.debug.print("otp: {d}\n", .{otp});
    return;
}
