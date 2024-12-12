const gregorian = @import("../calendars.zig").gregorian;
const AstronomicalYear = @import("../calendars.zig").AstronomicalYear;
const math = @import("../utils.zig").math;
const std = @import("std");

pub fn christmas(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .December, 25) catch unreachable;
}

pub fn christmasEve(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .December, 24) catch unreachable;
}

pub fn adventSunday(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .November, 30) catch unreachable;
    return base.dayOfWeekNearest(.Sunday);
}

pub fn epiphany(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .January, 2) catch unreachable;
    return base.firstWeekDay(.Sunday);
}

pub fn easter(year: AstronomicalYear) gregorian.Date {
    const y: i32 = @intFromEnum(year);
    const century = @floor(@as(f64, @floatFromInt(y)) / 100.0) + 1;
    const yearMod19 = math.mod(i32, y, 19);
    const shiftedEpact = math.mod(i32, 14 + 11 * yearMod19 - @as(i32, @intFromFloat(@floor(century * 0.75))) + @as(i32, @intFromFloat(@floor((5 + 8 * century) / 25.0))), 30);
    const adjustedEpact = if (shiftedEpact == 0 or (shiftedEpact == 1 and 10 < yearMod19)) shiftedEpact + 1 else shiftedEpact;
    const paschalMoon = (gregorian.Date{ .year = year, .month = .April, .day = 19 }).subDays(adjustedEpact);
    return paschalMoon.dayOfWeekAfter(.Sunday);
}

pub fn setuagesimaSunday(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(63);
}

pub fn sexagesimaSunda(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(56);
}

pub fn shroveSunday(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(49);
}

pub fn shroveMonday(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(48);
}

pub fn shroveTuesday(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(47);
}

pub fn mardiGras(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(47);
}

pub fn ashWednesday(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(46);
}

pub fn passionSunday(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(14);
}

pub fn palmSunday(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(7);
}

pub fn holyThursday(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(3);
}

pub fn maundyThursday(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(3);
}

pub fn goodFriday(year: AstronomicalYear) gregorian.Date {
    return easter(year).subDays(2);
}

pub fn rogationSunday(year: AstronomicalYear) gregorian.Date {
    return easter(year).addDays(35);
}

pub fn ascensionDay(year: AstronomicalYear) gregorian.Date {
    return easter(year).addDays(39);
}

pub fn pentecost(year: AstronomicalYear) gregorian.Date {
    return easter(year).addDays(49);
}

pub fn whitSunday(year: AstronomicalYear) gregorian.Date {
    return easter(year).addDays(49);
}

pub fn whitMonday(year: AstronomicalYear) gregorian.Date {
    return easter(year).addDays(50);
}

pub fn trinitySunday(year: AstronomicalYear) gregorian.Date {
    return easter(year).addDays(56);
}

pub fn corpusChristi(year: AstronomicalYear) gregorian.Date {
    return easter(year).addDays(60);
}

pub fn corpusChristiUsCatholic(year: AstronomicalYear) gregorian.Date {
    return easter(year).addDays(63);
}

pub fn the40DaysOfLent(year: AstronomicalYear) [40]gregorian.Date {
    var res: [40]gregorian.Date = undefined;
    const start = easter(year).subDays(46);
    for (res, 0..) |_, i| {
        res[i] = start.addDays(@intCast(i));
    }
    return res;
}

test "sample data" {
    const sample_years = @import("test_helpers.zig").sample_years;

    // christmas
    for (sample_years) |y| {
        const year: AstronomicalYear = @enumFromInt(y);
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(year, .December, 25),
            christmas(year),
        );
    }

    // christmas eve
    for (sample_years) |y| {
        const year: AstronomicalYear = @enumFromInt(y);
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(year, .December, 24),
            christmasEve(year),
        );
    }

    // easter
    const MonDay = struct { month: u8, day: u8 };
    const expected_easter = [_]MonDay{
        .{ .month = 4, .day = 23 }, .{ .month = 4, .day = 15 }, .{ .month = 3, .day = 31 }, .{ .month = 4, .day = 20 }, .{ .month = 4, .day = 11 }, .{ .month = 3, .day = 27 }, .{ .month = 4, .day = 16 }, .{ .month = 4, .day = 8 },  .{ .month = 3, .day = 23 }, .{ .month = 4, .day = 12 }, .{ .month = 4, .day = 4 },  .{ .month = 4, .day = 24 }, .{ .month = 4, .day = 8 },  .{ .month = 3, .day = 31 },
        .{ .month = 4, .day = 20 }, .{ .month = 4, .day = 5 },  .{ .month = 3, .day = 27 }, .{ .month = 4, .day = 16 }, .{ .month = 4, .day = 1 },  .{ .month = 4, .day = 21 }, .{ .month = 4, .day = 12 }, .{ .month = 4, .day = 4 },  .{ .month = 4, .day = 17 }, .{ .month = 4, .day = 9 },  .{ .month = 3, .day = 31 }, .{ .month = 4, .day = 20 }, .{ .month = 4, .day = 5 },  .{ .month = 3, .day = 28 },
        .{ .month = 4, .day = 16 }, .{ .month = 4, .day = 1 },  .{ .month = 4, .day = 21 }, .{ .month = 4, .day = 13 }, .{ .month = 3, .day = 28 }, .{ .month = 4, .day = 17 }, .{ .month = 4, .day = 9 },  .{ .month = 3, .day = 25 }, .{ .month = 4, .day = 13 }, .{ .month = 4, .day = 5 },  .{ .month = 4, .day = 25 }, .{ .month = 4, .day = 10 }, .{ .month = 4, .day = 1 },  .{ .month = 4, .day = 21 },
        .{ .month = 4, .day = 6 },  .{ .month = 3, .day = 29 }, .{ .month = 4, .day = 17 }, .{ .month = 4, .day = 9 },  .{ .month = 3, .day = 25 }, .{ .month = 4, .day = 14 }, .{ .month = 4, .day = 5 },  .{ .month = 4, .day = 18 }, .{ .month = 4, .day = 10 }, .{ .month = 4, .day = 2 },  .{ .month = 4, .day = 21 }, .{ .month = 4, .day = 6 },  .{ .month = 3, .day = 29 }, .{ .month = 4, .day = 18 },
    };
    for (sample_years[0..expected_easter.len], expected_easter) |y, e| {
        const year: AstronomicalYear = @enumFromInt(y);
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(year, @enumFromInt(e.month), e.day),
            easter(year),
        );
    }

    // epiphany
    const expected_days = [_]u8{
        2, 7, 6, 5, 4, 2, 8, 7, 6, 4, 3, 2, 8, 6, 5, 4, 3, 8, 7, 6, 5, 3, 2, 8, 7, 5, 4, 3, 2, 7, 6, 5,
    };

    for (sample_years[0..expected_days.len], expected_days) |y, d| {
        const year: AstronomicalYear = @enumFromInt(y);
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(year, .January, d),
            epiphany(year),
        );
    }

    // advent sunday
    const MonthDay = struct { month: gregorian.Month, day: u8 };
    const expected_advent_sunday = [_]MonthDay{
        MonthDay{ .month = .December, .day = 3 },  MonthDay{ .month = .December, .day = 2 },  MonthDay{ .month = .December, .day = 1 },  MonthDay{ .month = .November, .day = 30 },
        MonthDay{ .month = .November, .day = 28 }, MonthDay{ .month = .November, .day = 27 }, MonthDay{ .month = .December, .day = 3 },  MonthDay{ .month = .December, .day = 2 },
        MonthDay{ .month = .November, .day = 30 }, MonthDay{ .month = .November, .day = 29 }, MonthDay{ .month = .November, .day = 28 }, MonthDay{ .month = .November, .day = 27 },
        MonthDay{ .month = .December, .day = 2 },  MonthDay{ .month = .December, .day = 1 },  MonthDay{ .month = .November, .day = 30 }, MonthDay{ .month = .November, .day = 29 },
        MonthDay{ .month = .November, .day = 27 }, MonthDay{ .month = .December, .day = 3 },  MonthDay{ .month = .December, .day = 2 },  MonthDay{ .month = .December, .day = 1 },
        MonthDay{ .month = .November, .day = 29 }, MonthDay{ .month = .November, .day = 28 }, MonthDay{ .month = .November, .day = 27 }, MonthDay{ .month = .December, .day = 3 },
        MonthDay{ .month = .December, .day = 1 },  MonthDay{ .month = .November, .day = 30 }, MonthDay{ .month = .November, .day = 29 }, MonthDay{ .month = .November, .day = 28 },
        MonthDay{ .month = .December, .day = 3 },  MonthDay{ .month = .December, .day = 2 },  MonthDay{ .month = .December, .day = 1 },  MonthDay{ .month = .November, .day = 30 },
    };

    for (sample_years[0..expected_advent_sunday.len], expected_advent_sunday) |y, e| {
        const year: AstronomicalYear = @enumFromInt(y);
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(year, e.month, e.day),
            adventSunday(year),
        );
    }
}

test "build" {
    const year: AstronomicalYear = @enumFromInt(2020);

    _ = christmas(year);
    _ = christmasEve(year);
    _ = adventSunday(year);
    _ = epiphany(year);
    _ = easter(year);
    _ = setuagesimaSunday(year);
    _ = sexagesimaSunda(year);
    _ = shroveSunday(year);
    _ = shroveMonday(year);
    _ = shroveTuesday(year);
    _ = mardiGras(year);
    _ = ashWednesday(year);
    _ = passionSunday(year);
    _ = palmSunday(year);
    _ = holyThursday(year);
    _ = maundyThursday(year);
    _ = goodFriday(year);
    _ = rogationSunday(year);
    _ = ascensionDay(year);
    _ = pentecost(year);
    _ = whitSunday(year);
    _ = whitMonday(year);
    _ = trinitySunday(year);
    _ = corpusChristi(year);
    _ = corpusChristiUsCatholic(year);
    _ = the40DaysOfLent(year);
}
