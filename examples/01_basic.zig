const Time = @import("zcalendar").calendars.time.Segments;
const Date = @import("zcalendar").calendars.gregorian.Date;
const DateTime = @import("zcalendar").calendars.gregorian.DateTime;
const std = @import("std");

pub fn main() !void {
    const date = try DateTime.init(
        try Date.initNums(2024, 1, 12),
        try Time.init(20, 34, 45, 0),
    );
    std.debug.print("{}\n", .{date});

    const date2 = date.addDays(34);
    std.debug.print("{}\n", .{date2});

    const date3 = date.subDays(90);
    std.debug.print("{}\n", .{date3});
}
