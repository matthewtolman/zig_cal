const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;
const christian = @import("../christian.zig");

pub fn kingKamehamehaDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .June, 11) catch unreachable;
}

pub fn princeJonahKuhioKalanianaoleDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .March, 26) catch unreachable;
}

pub fn statehoodDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .August, 1) catch unreachable;
    return base.nthWeekDay(3, .Friday);
}

pub fn goodFriday(year: AstronomicalYear) gregorian.Date {
    return christian.goodFriday(year);
}

test "hawaii" {
    const testing = @import("std").testing;
    const expectEqualDeep = testing.expectEqualDeep;
    const Date = gregorian.Date;
    const y: AstronomicalYear = @enumFromInt(2024);
    _ = goodFriday(y);

    try expectEqualDeep(
        try Date.initNums(2024, 6, 11),
        kingKamehamehaDay(y),
    );

    try expectEqualDeep(
        try Date.initNums(2024, 3, 26),
        princeJonahKuhioKalanianaoleDay(y),
    );
}
