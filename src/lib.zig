const std = @import("std");
const math = @import("./math.zig");

// placeholder stuff for now.
// I'll figure out how to namespace/scope things and get it all properly exported.
// Until then, I'm just relying on tests.

pub fn hello() !void {
    _ = math.mod(i32, 12, 23);
    std.debug.print("Hello!\n", .{});
}

test "hello" {
    try std.testing.expect(true);
}
