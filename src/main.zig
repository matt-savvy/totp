const std = @import("std");
const Io = std.Io;
const Totp = @import("totp");

pub fn main(init: std.process.Init) !void {
    // TODO get secret from file/stdin
    const secret = "2PKGTJMKCDGE4VQY37Q4NXUQMZKRNXPM";
    const io = init.io;
    const gpa = init.gpa;

    const now = Io.Timestamp.now(io, .real);
    // TODO get config from file/stdin
    const otp = try Totp.totp(init.gpa, secret, now, .{});
    defer gpa.free(otp);

    // TODO write to std out without debug
    std.debug.print("{s}\n", .{otp});
    return;
}

// TODO move "integration" level test here
