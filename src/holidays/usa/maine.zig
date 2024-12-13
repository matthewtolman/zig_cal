const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub const thanksgivingFriday = @import("../usa.zig").blackFriday;

pub fn patriotsDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .April, 1) catch unreachable;
    return base.nthWeekDay(3, .Monday);
}

test "maine" {
    const testing = @import("std").testing;
    const expectEqualDeep = testing.expectEqualDeep;
    const Date = gregorian.Date;
    const y: AstronomicalYear = @enumFromInt(2025);

    try expectEqualDeep(
        try Date.initNums(2025, 4, 21),
        patriotsDay(y),
    );
}
