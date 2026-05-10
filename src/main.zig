const std = @import("std");
const Io = std.Io;
const Totp = @import("totp");

pub fn main(init: std.process.Init) !void {
    // TODO get secret from file/stdin
    const secret = "12345678901234567890";
    const io = init.io;
    const now = Io.Timestamp.now(io, .real);
    // TODO get config from file/stdin
    const otp = Totp.totp(init.gpa, secret, now, .{});

    var buffer: [20]u8 = undefined;
    const end = std.fmt.printInt(&buffer, otp, 10, .lower, .{ .fill = '0', .width = 6 });
    const output = buffer[0..end];

    // TODO write to std out without otp
    std.debug.print("otp: {s}\n", .{output});
    return;
}

// TODO move "integration" level test here
