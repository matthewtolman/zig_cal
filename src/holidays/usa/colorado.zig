const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn cabriniDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .October, 1) catch unreachable;
    return base.firstWeekDay(.Monday);
}

test "colorado" {
    const testing = @import("std").testing;
    const expectEqualDeep = testing.expectEqualDeep;
    const Date = gregorian.Date;
    const y: AstronomicalYear = @enumFromInt(2024);

    try expectEqualDeep(
        try Date.initNums(2024, 10, 7),
        cabriniDay(y),
    );
}
