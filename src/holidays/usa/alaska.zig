const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn alaskaDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .October, 18) catch unreachable;
}

pub fn sewardsDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .March, 31) catch unreachable;
    return base.lastWeekDay(.Monday);
}

test "alaska" {
    const testing = @import("std").testing;
    const expectEqualDeep = testing.expectEqualDeep;
    const Date = gregorian.Date;

    try expectEqualDeep(try Date.initNums(2024, 10, 18), alaskaDay(@enumFromInt(2024)));
    try expectEqualDeep(try Date.initNums(2025, 3, 31), sewardsDay(@enumFromInt(2025)));
}
