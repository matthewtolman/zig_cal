pub const calendars = @import("calendars.zig");
pub const utils = @import("utils.zig");

// Due to how "pub const ... = @import(...)" works, we do need to dereference
// the code in order to get the test cases to actually run with zig build test

test "calendars" {
    _ = calendars.gregorian.Date.fromFixedDate(calendars.fixed.Date{ .day = 12 });
    _ = try calendars.time.NanoSeconds.init(0);
    _ = calendars.unix.Timestamp.fromFixedDateTime(
        calendars.fixed.DateTime{
            .date = calendars.fixed.Date{ .day = 0 },
            .time = calendars.time.Segments{},
        },
    );
}

test "utils" {
    _ = utils.math.mod(i32, 2, 3);
    _ = utils.types.toTypeMath(i32, 2);
}
