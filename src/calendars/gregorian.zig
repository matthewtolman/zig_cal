const epochs = @import("./epochs.zig");
const time = @import("../calendars.zig").time;
const math = @import("../utils.zig").math;
const types = @import("../utils.zig").types;
const testing = @import("std").testing;
const assert = @import("std").debug.assert;
const m = @import("std").math;
const fmt = @import("std").fmt;
const mem = @import("std").mem;
const FixedDate = @import("./fixed.zig").Date;
const AstronomicalYear = @import("./core.zig").AstronomicalYear;
const astroToAD = @import("./core.zig").astroToAD;

/// Represents the gregorian months
pub const Month = enum(u8) {
    January = 1,
    February = 2,
    March = 3,
    April = 4,
    May = 5,
    June = 6,
    July = 7,
    August = 8,
    September = 9,
    October = 10,
    November = 11,
    December = 12,
};

/// Gets the Gregorian Year from a fixed date
fn yearFromFixed(fixed: FixedDate) AstronomicalYear {
    // Get our day without leap years
    const d0 = fixed.dayCount - epochs.gregorian;

    const daysPer400Years = 146097;
    const n400 = @divFloor(d0, daysPer400Years);
    const d1 = math.mod(i32, d0, daysPer400Years);

    const daysPer100Years = 36524;
    const n100 = @divFloor(d1, daysPer100Years);
    const d2 = math.mod(i32, d1, daysPer100Years);

    const daysPer4Years = 1461;
    const n4 = @divFloor(d2, daysPer4Years);
    const d3 = math.mod(i32, d2, daysPer4Years);

    const daysPer1Year = 365;
    const n1 = @divFloor(d3, daysPer1Year);

    const years400 = 400 * n400;
    const years100 = 100 * n100;
    const years4 = 4 * n4;
    const year1 = n1;
    const leapAdjustment: i32 = if (n100 == 4 or n1 == 4) 0 else 1;

    const res = years400 + years100 + years4 + year1 + leapAdjustment;
    return @enumFromInt(res);
}

/// Gets a date representing the start of a year
fn yearStart(year: AstronomicalYear) Date {
    return Date{ .year = year, .month = .January, .day = 1 };
}

/// Gets a date representing the end of a year
fn yearEnd(year: AstronomicalYear) Date {
    return Date{ .year = year, .month = .January, .day = 1 };
}

/// Implmentation of isLeapYear
fn leapYear(year: AstronomicalYear) bool {
    const y = @intFromEnum(year);
    if (math.mod(i32, y, 4) != 0) {
        return false;
    }

    const yearMod400 = math.mod(i32, y, 400);
    return yearMod400 != 100 and yearMod400 != 200 and yearMod400 != 300;
}

/// Checks whether a year is a leap year
pub fn isLeapYear(year: AstronomicalYear) bool {
    return leapYear(year);
}

/// Gets the number of days in a month/year combo
fn daysInMonth(month: Month, year: AstronomicalYear) u8 {
    return switch (month) {
        .January, .March, .May, .July, .August, .October, .December => 31,
        .April, .June, .September, .November => 30,
        .February => if (isLeapYear(year)) 29 else 28,
    };
}

/// Gets a gregorian date from a fixed date
/// Used for conversions between date systems
/// Can also be used during long day-based math operations
pub fn fromFixed(fixed: FixedDate) Date {
    const year = yearFromFixed(fixed);
    const yStart = yearStart(year);
    const yearStartFixed = yStart.toFixed();

    assert(yearStartFixed.dayCount <= fixed.dayCount);

    const priorDays = fixed.dayCount - yearStartFixed.dayCount;

    // Used for leap year adjustments
    const marchFirst = Date{ .year = year, .month = .March, .day = 1 };
    const marchFirstFixed = marchFirst.toFixed();
    const correction: i32 = switch (fixed.dayCount < marchFirstFixed.dayCount) {
        true => 0,
        false => if (isLeapYear(year)) 1 else 2,
    };

    const monthVal = @divFloor(12 * (priorDays + correction) + 373, 367);
    assert(monthVal >= 1);
    assert(monthVal <= 12);

    const month: Month = @enumFromInt(monthVal);
    assert(@intFromEnum(month) >= @intFromEnum(Month.January));
    assert(@intFromEnum(month) <= @intFromEnum(Month.December));

    const firstOfMonth = Date{ .year = year, .month = month, .day = 1 };
    const firstOfMonthFixed = firstOfMonth.toFixed();
    assert(firstOfMonthFixed.dayCount <= fixed.dayCount);

    const dayRaw = fixed.dayCount - firstOfMonthFixed.dayCount + 1;
    const day = types.toTypeMath(u8, dayRaw);
    assert(day <= daysInMonth(month, year));

    return Date{ .year = year, .month = month, .day = day };
}

/// Represents a date on the Gregorian Calendar system.
/// This calendar uses the Astronomical year counting system which includes 0.
/// Year 0 correspondes to 1 B.C. on the Anno Domini system of counting.
///
/// To make the year system explicit, we have "distinct int types" through
/// non-exhaustive enums.
///
/// If you don't like Year 0, then take a look at how we exclude it with the
/// JulianDate and then make your own version with it excluded.
///
/// Note that the year is a 32-bit signed integer
/// This means we can represent a large chunk of the earth's history, but
/// probably not all of it and definitely not the history of the universe.
/// Which is okay. Usually when needing that kind of timescale you'll be using
/// either the geologic time scale or cosmic calendar rather than the gregorian
/// calendar. Keeping track of the Gregorian leap years is less significant
/// when plotting out the events that happened after the big bang.
pub const Date = struct {
    year: AstronomicalYear = @enumFromInt(0),
    month: Month = .January,
    day: u8 = 1,

    /// Converts date to a Fixed date
    /// Used for calendar conversions
    /// Also used for starting long day-based math sequences
    pub fn toFixed(self: Date) FixedDate {
        const y: i32 = @intFromEnum(self.year);
        const month: i32 = @intFromEnum(self.month);
        const prevYear: i32 = y - 1;
        var sum: i32 = 0;

        const epochAdjustment = epochs.gregorian - 1;
        sum += epochAdjustment;

        const daysPriorYears = 365 * prevYear;
        sum += daysPriorYears;

        const leapDaysPriorYears = @divFloor(prevYear, 4);
        sum += leapDaysPriorYears;

        const overcountedLeapDays = @divFloor(prevYear, 100);
        sum -= overcountedLeapDays;

        const undercountedLeapDays = @divFloor(prevYear, 400);
        sum += undercountedLeapDays;

        const numerator = 367 * @as(i32, @intCast(month)) - 362;
        const daysPassedInYearEstimate = @divFloor(numerator, 12);
        sum += daysPassedInYearEstimate;

        // Leap day adjustement
        if (month <= @intFromEnum(Month.February)) {
            // Do nothing, no leap day adjustment needed
        } else if (self.isLeapYear()) {
            // We overcounted by 1 in our estimate
            sum -= 1;
        } else {
            // We overcounted by 2 in our estimate
            sum -= 2;
        }

        const daysPassedInMonth = self.day;
        sum += daysPassedInMonth;

        return FixedDate{ .dayCount = sum };
    }

    /// Checks whether the gregorian date is a leap year or not
    pub fn isLeapYear(self: Date) bool {
        return leapYear(self.year);
    }

    /// Formats Gregorian Calendar into string form
    /// Format of "s" will do human readable date string with Anno Domini year
    ///     (e.g. March 23, 345 B.C.    April 3, 2023 A.D.)
    /// Default format (for any other format type) will do -?YYYY-MM-DD with
    /// astronomical year.
    /// If year is negative, will prefix date with a "-", otherwise will not
    ///     (e.g. -0344-03-23       2023-04-03)
    pub fn format(
        self: Date,
        comptime f: []const u8,
        options: fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;

        if (mem.eql(u8, f, "s")) {
            const y = @intFromEnum(astroToAD(self.year));
            const month = @tagName(self.month);
            const adOrBc = if (y > 0) "A.D." else "B.C.";
            const yAbs = @as(u32, @intCast(y * m.sign(y)));

            try writer.print("{s} {d}, {d} {s}", .{
                month,
                self.day,
                yAbs,
                adOrBc,
            });
            return;
        }

        const y = @intFromEnum(self.year);
        const month = @intFromEnum(self.month);
        if (y >= 0) {
            try writer.print("{d:0>4}-{d:0>2}-{d:0>2}", .{
                @as(u32, @intCast(y)),
                month,
                self.day,
            });
        } else {
            try writer.print("-{d:0>4}-{d:0>2}-{d:0>2}", .{
                @as(u32, @intCast(m.sign(y) * y)),
                month,
                self.day,
            });
        }
    }

    /// The difference between this date and another date in days
    pub fn dayDifference(self: Date, other: Date) i32 {
        const left = @as(i64, self.toFixed().dayCount);
        const right = @as(i64, other.toFixed().dayCount);
        const res = left - right;
        assert(res >= m.minInt(i32));
        assert(res <= m.maxInt(i32));
        return @as(i32, @intCast(res));
    }

    /// Compares two dates
    pub fn compare(self: Date, other: Date) i32 {
        if (self.year != other.year) {
            if (@intFromEnum(self.year) > @intFromEnum(other.year)) {
                return 1;
            }
            return -1;
        }

        if (self.month != other.month) {
            if (@intFromEnum(self.month) > @intFromEnum(other.month)) {
                return 1;
            }
            return -1;
        }

        if (self.day != other.day) {
            return if (self.day > other.day) 1 else -1;
        }

        return 0;
    }

    // pub fn dayNumber(self: Date) i32 {
    //     const prevYearEnd = Date{
    //         .year = @enumFromInt(@intFromEnum(self.year) - 1),
    //     };
    // }
};

test "gregorian conversions" {
    const fixedDates = @import("./test_helpers.zig").sampleDates;

    const expected = [_]Date{
        Date{ .year = @enumFromInt(-586), .month = @enumFromInt(7), .day = 24 },
        Date{ .year = @enumFromInt(-168), .month = @enumFromInt(12), .day = 5 },
        Date{ .year = @enumFromInt(70), .month = @enumFromInt(9), .day = 24 },
        Date{ .year = @enumFromInt(135), .month = @enumFromInt(10), .day = 2 },
        Date{ .year = @enumFromInt(470), .month = @enumFromInt(1), .day = 8 },
        Date{ .year = @enumFromInt(576), .month = @enumFromInt(5), .day = 20 },
        Date{ .year = @enumFromInt(694), .month = @enumFromInt(11), .day = 10 },
        Date{ .year = @enumFromInt(1013), .month = @enumFromInt(4), .day = 25 },
        Date{ .year = @enumFromInt(1096), .month = @enumFromInt(5), .day = 24 },
        Date{ .year = @enumFromInt(1190), .month = @enumFromInt(3), .day = 23 },
        Date{ .year = @enumFromInt(1240), .month = @enumFromInt(3), .day = 10 },
        Date{ .year = @enumFromInt(1288), .month = @enumFromInt(4), .day = 2 },
        Date{ .year = @enumFromInt(1298), .month = @enumFromInt(4), .day = 27 },
        Date{ .year = @enumFromInt(1391), .month = @enumFromInt(6), .day = 12 },
        Date{ .year = @enumFromInt(1436), .month = @enumFromInt(2), .day = 3 },
        Date{ .year = @enumFromInt(1492), .month = @enumFromInt(4), .day = 9 },
        Date{ .year = @enumFromInt(1553), .month = @enumFromInt(9), .day = 19 },
        Date{ .year = @enumFromInt(1560), .month = @enumFromInt(3), .day = 5 },
        Date{ .year = @enumFromInt(1648), .month = @enumFromInt(6), .day = 10 },
        Date{ .year = @enumFromInt(1680), .month = @enumFromInt(6), .day = 30 },
        Date{ .year = @enumFromInt(1716), .month = @enumFromInt(7), .day = 24 },
        Date{ .year = @enumFromInt(1768), .month = @enumFromInt(6), .day = 19 },
        Date{ .year = @enumFromInt(1819), .month = @enumFromInt(8), .day = 2 },
        Date{ .year = @enumFromInt(1839), .month = @enumFromInt(3), .day = 27 },
        Date{ .year = @enumFromInt(1903), .month = @enumFromInt(4), .day = 19 },
        Date{ .year = @enumFromInt(1929), .month = @enumFromInt(8), .day = 25 },
        Date{ .year = @enumFromInt(1941), .month = @enumFromInt(9), .day = 29 },
        Date{ .year = @enumFromInt(1943), .month = @enumFromInt(4), .day = 19 },
        Date{ .year = @enumFromInt(1943), .month = @enumFromInt(10), .day = 7 },
        Date{ .year = @enumFromInt(1992), .month = @enumFromInt(3), .day = 17 },
        Date{ .year = @enumFromInt(1996), .month = @enumFromInt(2), .day = 25 },
        Date{ .year = @enumFromInt(2038), .month = @enumFromInt(11), .day = 10 },
        Date{ .year = @enumFromInt(2094), .month = @enumFromInt(7), .day = 18 },
    };

    assert(fixedDates.len == expected.len);

    for (fixedDates, 0..) |fixedDate, index| {
        const e = expected[index];

        // Test convertintg to fixed
        const actualFixed = e.toFixed();
        try testing.expectEqual(fixedDate.dayCount, actualFixed.dayCount);

        // Test converting from fixed
        const actualGreg = fromFixed(fixedDate);
        try testing.expect(0 == actualGreg.compare(e));
    }
}

test "gregorian formatting" {
    var list = @import("std").ArrayList(u8).init(testing.allocator);
    defer list.deinit();
    const testCases = [_]struct {
        date: Date,
        expectedS: []const u8,
        expectedAny: []const u8,
    }{
        .{
            .date = Date{},
            .expectedS = "January 1, 1 B.C.",
            .expectedAny = "0000-01-01",
        },
        .{
            .date = Date{
                .year = @enumFromInt(2024),
                .month = .February,
                .day = 29,
            },
            .expectedAny = "2024-02-29",
            .expectedS = "February 29, 2024 A.D.",
        },
        .{
            .date = Date{
                .year = @enumFromInt(202456),
                .month = .February,
                .day = 29,
            },
            .expectedAny = "202456-02-29",
            .expectedS = "February 29, 202456 A.D.",
        },
        .{
            .date = Date{
                .year = @enumFromInt(-2024),
                .month = .February,
                .day = 29,
            },
            .expectedAny = "-2024-02-29",
            .expectedS = "February 29, 2025 B.C.",
        },
    };

    for (testCases) |testCase| {
        {
            defer list.clearRetainingCapacity();

            try list.writer().print("{s}", .{testCase.date});
            try testing.expectEqualStrings(testCase.expectedS, list.items);
        }
        {
            defer list.clearRetainingCapacity();

            try list.writer().print("{any}", .{testCase.date});
            try testing.expectEqualStrings(testCase.expectedAny, list.items);
        }
    }
}

test "gregorian leap year" {
    const adToAstro = @import("./core.zig").adToAstro;
    const AnnoDominiYear = @import("./core.zig").AnnoDominiYear;
    try testing.expect(
        (Date{
            .year = @as(AstronomicalYear, @enumFromInt(0)),
        }).isLeapYear(),
    );
    try testing.expect(
        (Date{
            .year = adToAstro(@as(AnnoDominiYear, @enumFromInt(-1))),
        }).isLeapYear(),
    );
    try testing.expect((Date{ .year = @enumFromInt(4) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(8) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(2000) }).isLeapYear());
    try testing.expect(!(Date{ .year = @enumFromInt(1900) }).isLeapYear());
    try testing.expect(!(Date{ .year = @enumFromInt(1800) }).isLeapYear());
    try testing.expect(!(Date{ .year = @enumFromInt(1700) }).isLeapYear());
    try testing.expect(!(Date{ .year = @enumFromInt(2023) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(2024) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(2020) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(1600) }).isLeapYear());
}

/// Represents a gregorian date and time combination
pub const DateTime = struct {
    date: Date,
    time: time.Segments,
};
