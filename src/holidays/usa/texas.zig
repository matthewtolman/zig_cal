const toGregorian = @import("../gregorian_range.zig").holidayInGregorianYears;
const toGregorianRange = @import("../gregorian_range.zig").holidaysInGregorianYears;
const GregRange = @import("../gregorian_range.zig").GregorianRange;
const Hebrew = @import("../../calendars.zig").hebrew.Date;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;
const Gregorian = @import("../../calendars.zig").gregorian.Date;

pub fn roshHashanah(year: AstronomicalYear) [2]Gregorian {
    const roshHaShanah = @import("../hebrew.zig").asGregorian.roshHaShanah;
    const dates = roshHaShanah(year);
    @import("std").debug.assert(dates.data().len >= 2);
    return [2]Gregorian{
        dates.data()[0],
        dates.data()[1],
    };
}

pub fn yomKippur(year: AstronomicalYear) Gregorian {
    return @import("../hebrew.zig").asGregorian.yomKippur(year).data()[0];
}

pub fn dayAfterThanksgiving(year: AstronomicalYear) Gregorian {
    return @import("../usa.zig").blackFriday(year);
}

pub const dayAfterChristmas = @import("iowa.zig").dayAfterChristmas;

pub fn confederateHeroesDay(year: AstronomicalYear) Gregorian {
    return Gregorian{ .year = year, .month = .January, .day = 19 };
}

pub fn texasIndependenceDay(year: AstronomicalYear) Gregorian {
    return Gregorian{ .year = year, .month = .March, .day = 2 };
}

pub const cesarChavezDay = @import("../usa.zig").cesarChavezDay;

pub const goodFriday = @import("../christian.zig").goodFriday;

pub fn sanJacintoDay(year: AstronomicalYear) Gregorian {
    return Gregorian{ .year = year, .month = .April, .day = 21 };
}

pub const emancipationDay = @import("../usa.zig").juneteenth;

pub fn lbjDay(year: AstronomicalYear) Gregorian {
    return Gregorian{ .year = year, .month = .August, .day = 27 };
}

test "texas" {
    const testing = @import("std").testing;
    const y1: AstronomicalYear = @enumFromInt(2024);
    const y2: AstronomicalYear = @enumFromInt(2025);

    const rh = roshHashanah(y1);
    try testing.expectEqual(try Gregorian.initNums(2024, 10, 3), rh[0]);
    try testing.expectEqual(try Gregorian.initNums(2024, 10, 4), rh[1]);

    const yk = yomKippur(y1);
    try testing.expectEqual(try Gregorian.initNums(2024, 10, 12), yk);

    _ = dayAfterThanksgiving(y1);
    _ = dayAfterChristmas(y1);

    const chd = confederateHeroesDay(y2);
    try testing.expectEqual(try Gregorian.initNums(2025, 1, 19), chd);

    const tid = texasIndependenceDay(y2);
    try testing.expectEqual(try Gregorian.initNums(2025, 3, 2), tid);

    _ = cesarChavezDay(y2);
    _ = goodFriday(y2);

    const sjd = sanJacintoDay(y2);
    try testing.expectEqual(try Gregorian.initNums(2025, 4, 21), sjd);

    _ = emancipationDay(y2);

    const lbjd = lbjDay(y2);
    try testing.expectEqual(try Gregorian.initNums(2025, 8, 27), lbjd);
}
