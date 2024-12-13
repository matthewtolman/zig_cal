const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn washingtonsBirthday(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .December, 24) catch unreachable;
}

test "georgia" {
    const testing = @import("std").testing;
    const expectEqualDeep = testing.expectEqualDeep;
    const Date = gregorian.Date;
    const y: AstronomicalYear = @enumFromInt(2024);

    try expectEqualDeep(
        try Date.initNums(2024, 12, 24),
        washingtonsBirthday(y),
    );
}
