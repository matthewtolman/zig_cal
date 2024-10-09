pub const calendars = @import("calendars.zig");
pub const utils = @import("utils.zig");

test "calendars" {
    _ = calendars.gregorian.fromFixed(calendars.fixed.Date{ .dayCount = 12 });
}
