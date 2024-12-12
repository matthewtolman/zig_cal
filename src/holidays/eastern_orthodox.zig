const julian = @import("../calendars/julian.zig");
const calendars = @import("../calendars.zig");
const utils = @import("../utils.zig");
const gregorianRange = @import("gregorian_range.zig");
const GregorianRange = gregorianRange.GregorianRange(3);

pub const asJulian = struct {
    pub fn christmas(julianYear: calendars.AnnoDominiYear) julian.Date {
        return julian.Date.init(julianYear, .December, 25) catch unreachable;
    }

    pub fn nativityOfTheVirginMary(julianYear: calendars.AnnoDominiYear) julian.Date {
        return julian.Date.init(julianYear, .September, 8) catch unreachable;
    }

    pub fn elevationOfTheLifeGivingCross(julianYear: calendars.AnnoDominiYear) julian.Date {
        return julian.Date.init(julianYear, .September, 14) catch unreachable;
    }

    pub fn presentationOfTheVirginMaryInTheTemple(julianYear: calendars.AnnoDominiYear) julian.Date {
        return julian.Date.init(julianYear, .September, 21) catch unreachable;
    }

    pub fn theophany(julianYear: calendars.AnnoDominiYear) julian.Date {
        return julian.Date.init(julianYear, .January, 6) catch unreachable;
    }

    pub fn presentationOfChristInTheTemple(julianYear: calendars.AnnoDominiYear) julian.Date {
        return julian.Date.init(julianYear, .February, 2) catch unreachable;
    }

    pub fn theAnnunciation(julianYear: calendars.AnnoDominiYear) julian.Date {
        return julian.Date.init(julianYear, .March, 25) catch unreachable;
    }

    pub fn theTransfiguration(julianYear: calendars.AnnoDominiYear) julian.Date {
        return julian.Date.init(julianYear, .August, 6) catch unreachable;
    }

    pub fn theReposeOfTheVirginMary(julianYear: calendars.AnnoDominiYear) julian.Date {
        return julian.Date.init(julianYear, .August, 15) catch unreachable;
    }

    pub fn easter(julianYear: calendars.AnnoDominiYear) julian.Date {
        // For math to work out in BC years, we shift up by 1 so that 1 BC becomes 0
        //  This is important since 0 is not a valid julian year
        const adjustedYear: i32 = @intFromEnum(calendars.annoDominiToAstronomical(julianYear) catch unreachable);
        const shiftedEpact = utils.math.mod(i32, 14 + 11 * utils.math.mod(i32, adjustedYear, 19), 30);
        const paschalMoon = (julian.Date.init(julianYear, .April, 19) catch unreachable).subDays(shiftedEpact);
        return paschalMoon.dayOfWeekAfter(.Sunday);
    }

    pub fn theFastOfTheReposeOfTheVirginMary(julianYear: calendars.AnnoDominiYear) [14]julian.Date {
        return [14]julian.Date{
            julian.Date{ .year = julianYear, .month = .August, .day = 1 },
            julian.Date{ .year = julianYear, .month = .August, .day = 2 },
            julian.Date{ .year = julianYear, .month = .August, .day = 3 },
            julian.Date{ .year = julianYear, .month = .August, .day = 4 },
            julian.Date{ .year = julianYear, .month = .August, .day = 5 },
            julian.Date{ .year = julianYear, .month = .August, .day = 6 },
            julian.Date{ .year = julianYear, .month = .August, .day = 7 },
            julian.Date{ .year = julianYear, .month = .August, .day = 8 },
            julian.Date{ .year = julianYear, .month = .August, .day = 9 },
            julian.Date{ .year = julianYear, .month = .August, .day = 10 },
            julian.Date{ .year = julianYear, .month = .August, .day = 11 },
            julian.Date{ .year = julianYear, .month = .August, .day = 12 },
            julian.Date{ .year = julianYear, .month = .August, .day = 13 },
            julian.Date{ .year = julianYear, .month = .August, .day = 14 },
        };
    }

    pub fn the40DayChristmasFast(julianYear: calendars.AnnoDominiYear) [40]julian.Date {
        var res: [40]julian.Date = undefined;
        const start = julian.Date{
            .year = julianYear,
            .month = .November,
            .day = 15,
        };
        for (res, 0..) |_, i| {
            res[i] = start.addDays(@intCast(i));
        }
        return res;
    }
};

pub const asGregorian = struct {
    pub fn christmas(gregorianYear: calendars.AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(julian.Date, gregorianYear, asJulian.christmas);
    }

    pub fn nativityOfTheVirginMary(gregorianYear: calendars.AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(julian.Date, gregorianYear, asJulian.nativityOfTheVirginMary);
    }

    pub fn elevationOfTheLifeGivingCross(gregorianYear: calendars.AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(julian.Date, gregorianYear, asJulian.elevationOfTheLifeGivingCross);
    }

    pub fn presentationOfTheVirginMaryInTheTemple(gregorianYear: calendars.AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(julian.Date, gregorianYear, asJulian.presentationOfTheVirginMaryInTheTemple);
    }

    pub fn theophany(gregorianYear: calendars.AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(julian.Date, gregorianYear, asJulian.theophany);
    }

    pub fn presentationOfChristInTheTemple(gregorianYear: calendars.AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(julian.Date, gregorianYear, asJulian.presentationOfChristInTheTemple);
    }

    pub fn theAnnunciation(gregorianYear: calendars.AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(julian.Date, gregorianYear, asJulian.theAnnunciation);
    }

    pub fn theTransfiguration(gregorianYear: calendars.AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(julian.Date, gregorianYear, asJulian.theTransfiguration);
    }

    pub fn theReposeOfTheVirginMary(gregorianYear: calendars.AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(julian.Date, gregorianYear, asJulian.theReposeOfTheVirginMary);
    }

    pub fn easter(gregorianYear: calendars.AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(julian.Date, gregorianYear, asJulian.easter);
    }

    pub fn theFastOfTheReposeOfTheVirginMary(gregorianYear: calendars.AstronomicalYear) gregorianRange.GregorianRange(14 * 2) {
        return gregorianRange.holidaysInGregorianYearsSize(julian.Date, 2, 14, gregorianYear, asJulian.theFastOfTheReposeOfTheVirginMary);
    }

    pub fn the40DayChristmasFast(gregorianYear: calendars.AstronomicalYear) gregorianRange.GregorianRange(40 * 2) {
        return gregorianRange.holidaysInGregorianYearsSize(julian.Date, 2, 40, gregorianYear, asJulian.the40DayChristmasFast);
    }
};

test "christmas julian" {
    const testing = @import("std").testing;
    const res = asJulian.christmas(@enumFromInt(2020));
    const expected = julian.Date{
        .year = @enumFromInt(2020),
        .month = .December,
        .day = 25,
    };
    try testing.expectEqualDeep(expected, res);
}

test "easter" {
    const std = @import("std");
    const testing = std.testing;
    const gregorian = calendars.gregorian;
    const convert = utils.convert;
    const sample_years = @import("test_helpers.zig").sample_years;

    const MonDay = struct { month: gregorian.Month, day: u8 };
    const expected = [_]MonDay{
        MonDay{ .month = @enumFromInt(4), .day = 30 },
        MonDay{ .month = @enumFromInt(4), .day = 15 },
        MonDay{ .month = @enumFromInt(5), .day = 5 },
        MonDay{ .month = @enumFromInt(4), .day = 27 },
        MonDay{ .month = @enumFromInt(4), .day = 11 },
        MonDay{ .month = @enumFromInt(5), .day = 1 },
        MonDay{ .month = @enumFromInt(4), .day = 23 },
        MonDay{ .month = @enumFromInt(4), .day = 8 },
    };
    for (sample_years[0..expected.len], expected) |y, e| {
        const h = asJulian.easter(@enumFromInt(y));
        const ex = convert(
            gregorian.Date{
                .year = @enumFromInt(y),
                .month = e.month,
                .day = e.day,
            },
            julian.Date,
        );
        try testing.expectEqualDeep(ex, h);
    }
}

test "christmas gregorian" {
    const std = @import("std");
    const testing = std.testing;
    const gregorian = calendars.gregorian;
    const res = asGregorian.christmas(@enumFromInt(2020));
    const expected = [_]gregorian.Date{
        gregorian.Date{
            .year = @enumFromInt(2020),
            .month = .January,
            .day = 7,
        },
    };
    try testing.expectEqualSlices(gregorian.Date, expected[0..], res.data());
}

test "build" {
    // Make sure everything at least builds properly
    const std = @import("std");
    const testing = std.testing;

    const y: calendars.AnnoDominiYear = @enumFromInt(2040);
    const yg: calendars.AstronomicalYear = @enumFromInt(2040);

    const cf = asJulian.the40DayChristmasFast(y);
    try testing.expectEqual(40, cf.len);

    const vf = asJulian.theFastOfTheReposeOfTheVirginMary(y);
    try testing.expectEqual(14, vf.len);

    const cf2 = asGregorian.the40DayChristmasFast(yg);
    try testing.expectEqual(40, cf2.data().len);

    const vf2 = asGregorian.theFastOfTheReposeOfTheVirginMary(yg);
    try testing.expectEqual(14, vf2.data().len);

    _ = asJulian.easter(y);
    _ = asJulian.christmas(y);
    _ = asJulian.presentationOfChristInTheTemple(y);
    _ = asJulian.elevationOfTheLifeGivingCross(y);
    _ = asJulian.theophany(y);
    _ = asJulian.presentationOfTheVirginMaryInTheTemple(y);
    _ = asJulian.theAnnunciation(y);
    _ = asJulian.theTransfiguration(y);
    _ = asJulian.nativityOfTheVirginMary(y);
    _ = asJulian.theReposeOfTheVirginMary(y);

    _ = asGregorian.easter(yg);
    _ = asGregorian.christmas(yg);
    _ = asGregorian.presentationOfChristInTheTemple(yg);
    _ = asGregorian.elevationOfTheLifeGivingCross(yg);
    _ = asGregorian.theophany(yg);
    _ = asGregorian.presentationOfTheVirginMaryInTheTemple(yg);
    _ = asGregorian.theAnnunciation(yg);
    _ = asGregorian.theTransfiguration(yg);
    _ = asGregorian.nativityOfTheVirginMary(yg);
    _ = asGregorian.theReposeOfTheVirginMary(yg);
}
