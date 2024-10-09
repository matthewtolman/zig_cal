pub const calendars = @import("calendars.zig");
pub const utils = @import("utils.zig");

// Due to how "pub const ... = @import(...)" works, we do need to dereference
// the code in order to get the test cases to actually run with zig build test

test "calendars" {
    _ = calendars.gregorian.dateFromFixed(calendars.fixed.Date{ .day = 12 });
    _ = calendars.time.NanoSeconds{ .nano = 0 };
}

test "utils" {
    _ = utils.math.mod(i32, 2, 3);
    _ = utils.types.toTypeMath(i32, 2);
}
