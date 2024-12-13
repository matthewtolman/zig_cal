const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn lincolnsBirthday(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .February, 12) catch unreachable;
}

test "connecticut" {
    const testing = @import("std").testing;
    const expectEqualDeep = testing.expectEqualDeep;
    const Date = gregorian.Date;
    const y: AstronomicalYear = @enumFromInt(2024);

    try expectEqualDeep(
        try Date.initNums(2024, 2, 12),
        lincolnsBirthday(y),
    );
}
