const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;
const christian = @import("../christian.zig");

pub fn mardiGras(year: AstronomicalYear) gregorian.Date {
    return christian.mardiGras(year);
}

pub fn confederateMemorialDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .April, 1) catch unreachable;
    return base.nthWeekDay(4, .Monday);
}

pub fn jeffersonDavisBirthday(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .June, 1) catch unreachable;
    return base.firstWeekDay(.Monday);
}

pub fn fraternalDay(year: AstronomicalYear) gregorian.Date {
    const usa = @import("../usa.zig");
    return usa.indigenousPeoplesDay(year);
}

pub fn mrsRosaLParksDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date{ .year = year, .month = .December, .day = 1 };
}

pub fn robertELeeBirthday(year: AstronomicalYear) gregorian.Date {
    const usa = @import("../usa.zig");
    return usa.martinLutherKingJrDay(year);
}

test "alabama" {
    const testing = @import("std").testing;
    const expectEqualDeep = testing.expectEqualDeep;
    const Date = gregorian.Date;
    const y: AstronomicalYear = @enumFromInt(2024);
    _ = mardiGras(y);
    _ = robertELeeBirthday(y);
    _ = fraternalDay(y);

    try expectEqualDeep(try Date.initNums(2024, 4, 22), confederateMemorialDay(y));
    try expectEqualDeep(try Date.initNums(2024, 6, 3), jeffersonDavisBirthday(y));
    try expectEqualDeep(try Date.initNums(2024, 12, 1), mrsRosaLParksDay(y));
}
