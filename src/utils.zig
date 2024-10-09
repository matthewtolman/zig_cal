pub const math = @import("./utils/math.zig");
pub const types = @import("./utils/types.zig");
const builtin = @import("builtin");
const std = @import("std");

pub fn trace(comptime fmt: []const u8, args: anytype) void {
    if (builtin.mode == .Debug) {
        std.log.debug(fmt, args);
    }
}
