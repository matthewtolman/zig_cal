const epochs = @import("./epochs.zig");
const time = @import("../calendars.zig").time;
const math = @import("../utils.zig").math;
const types = @import("../utils.zig").types;
const testing = @import("std").testing;
const assert = @import("std").debug.assert;
const fixed = @import("./fixed.zig");
const core = @import("./core.zig");
const CalendarDateTime = @import("./wrappers.zig").CalendarDateTime;
const CalendarMixin = @import("./wrappers.zig").CalendarMixin;
const std = @import("std");

const m = std.math;
const fmt = std.fmt;
const mem = std.mem;

const AstronomicalYear = core.AstronomicalYear;
const validateAstroYear = core.validateAstroYear;
const astroToAD = core.astroToAD;
const ValidationError = core.ValidationError;

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
fn yearFromFixed(fixedDate: fixed.Date) AstronomicalYear {
    // Get our day without leap years
    const d0 = fixedDate.day - epochs.gregorian;

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

    const periodAdjustment: i32 = if (n100 != 4 and n1 != 4) 1 else 0;

    const res = years400 + years100 + years4 + year1 + periodAdjustment;
    return @enumFromInt(res);
}

/// Gets a date representing the start of a year
fn yearStart(year: AstronomicalYear) Date {
    validateAstroYear(year) catch unreachable;
    return Date{ .year = year, .month = .January, .day = 1 };
}

/// Gets a date representing the end of a year
fn yearEnd(year: AstronomicalYear) Date {
    validateAstroYear(year) catch unreachable;
    return Date{ .year = year, .month = .December, .day = 31 };
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

    /// Creates a new Gregorian date
    pub fn init(year: AstronomicalYear, month: Month, day: u8) !Date {
        const res = Date{ .year = year, .month = month, .day = day };
        try res.validate();
        return res;
    }

    /// Creates a new Gregorian date. Will convert numbers to types
    pub fn initNums(year: i32, month: i32, day: i32) !Date {
        const y: AstronomicalYear = @enumFromInt(year);
        try validateAstroYear(y);

        if (month < 1 or month > 12) {
            return ValidationError.InvalidMonth;
        }

        if (day > 31 or day < 1) {
            return ValidationError.InvalidDay;
        }

        return init(y, @enumFromInt(month), @intCast(day));
    }

    /// Validates a date
    pub fn validate(self: Date) !void {
        if (@intFromEnum(self.month) < 1 or @intFromEnum(self.month) > 12) {
            return ValidationError.InvalidMonth;
        }

        try validateAstroYear(self.year);

        const dayMax = self.daysInMonth();
        if (self.day > dayMax or self.day < 1) {
            return ValidationError.InvalidDay;
        }
    }

    /// Returns the number of days in a month
    pub fn daysInMonth(self: Date) i8 {
        return switch (self.month) {
            .January, .March, .May, .July, .August, .October, .December => 31,
            .April, .June, .September, .November => 30,
            .February => if (self.isLeapYear()) 29 else 28,
        };
    }

    /// Creates a Gregorian date from a fixed date
    pub fn fromFixedDate(fixedDate: fixed.Date) Date {
        const year = yearFromFixed(fixedDate);
        const yStart = yearStart(year);
        const yearStartFixed = yStart.toFixedDate();

        assert(yearStartFixed.day <= fixedDate.day);

        const priorDays = fixedDate.day - yearStartFixed.day;

        // Used for leap year adjustments
        const marchFirst = Date{ .year = year, .month = .March, .day = 1 };
        const marchFirstFixed = marchFirst.toFixedDate();
        const correction: i32 = switch (fixedDate.day < marchFirstFixed.day) {
            true => 0,
            false => if (leapYear(year)) 1 else 2,
        };

        const monthVal = @divFloor(12 * (priorDays + correction) + 373, 367);
        assert(monthVal >= 1);
        assert(monthVal <= 12);

        const month: Month = @enumFromInt(monthVal);
        assert(@intFromEnum(month) >= @intFromEnum(Month.January));
        assert(@intFromEnum(month) <= @intFromEnum(Month.December));

        const firstOfMonth = Date{ .year = year, .month = month, .day = 1 };
        const firstOfMonthFixed = firstOfMonth.toFixedDate();
        assert(firstOfMonthFixed.day <= fixedDate.day);

        const dayRaw = fixedDate.day - firstOfMonthFixed.day + 1;
        const day = types.toTypeMath(u8, dayRaw);
        // A more precise assertion is done in res.isValid()
        assert(day <= 31);
        assert(day >= 1);

        const res = Date{ .year = year, .month = month, .day = day };
        // This is safe since we provide our own validate method
        assert(res.isValid());
        return res;
    }

    /// Converts date to a Fixed date
    /// Used for calendar conversions
    /// Also used for starting long day-based math sequences
    pub fn toFixedDate(self: Date) fixed.Date {
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

        return fixed.Date{ .day = sum };
    }

    /// Checks whether the gregorian date is a leap year or not
    pub fn isLeapYear(self: Date) bool {
        return leapYear(self.year);
    }

    /// Formats Gregorian Calendar into string form
    /// Format of "s" or "u" will do human readable date string with Anno
    /// Domini year.
    ///     (e.g. March 23, 345 B.C.    April 3, 2023 A.D.)
    /// Default format (for any other format type) will do YYYY-MM-DD with
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

        self.validate() catch {
            try writer.print("INVALID: ", .{});
        };

        if (mem.eql(u8, f, "s") or mem.eql(u8, f, "u")) {
            const y = @intFromEnum(try astroToAD(self.year));
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

    /// Gets the day number of the day in the current year (1-366)
    pub fn dayNumber(self: Date) i32 {
        const date = self.nearestValid();
        const prevYearInt = @intFromEnum(date.year) - 1;
        const prevYear: AstronomicalYear = @enumFromInt(prevYearInt);
        const end = yearEnd(prevYear);
        const res = date.dayDifference(end);
        assert(res >= 1);
        assert(if (date.isLeapYear()) res <= 366 else res <= 365);
        return res;
    }

    /// Gets the number of days remaining in the current year (0-365)
    pub fn daysRemaining(self: Date) i32 {
        const date = self.nearestValid();
        const end = yearEnd(date.year);
        const res = end.dayDifference(date);
        assert(res >= 0);
        assert(if (date.isLeapYear()) res <= 365 else res <= 364);
        return res;
    }

    pub usingnamespace CalendarMixin(Date);
};

test "days in year" {
    const testCases = [_]Date{
        try Date.initNums(2020, 12, 28),
        try Date.initNums(-256, 3, 2),
        try Date.initNums(4, 2, 29),
        Date{
            .year = @enumFromInt(2020),
            .month = @enumFromInt(2),
            .day = 38,
        },
    };

    for (testCases) |testCase| {
        const expected: i32 = if (testCase.isLeapYear()) 366 else 365;
        try testing.expectEqual(
            testCase.dayNumber() + testCase.daysRemaining(),
            expected,
        );

        const mismatched = testCase.dayNumber() != testCase.daysRemaining();
        const midPoint = expected == 366 and testCase.dayNumber() == 366 / 2;
        try testing.expect(mismatched or midPoint);
    }
}

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

    const timeSegment = try time.Segments.init(12, 0, 0, 0);

    for (fixedDates, 0..) |fixedDate, index| {
        const e = expected[index];

        // Test convertintg to fixed
        const actualFixed = e.toFixedDate();
        try testing.expectEqual(fixedDate.day, actualFixed.day);

        // Test converting from fixed
        const actualGreg = Date.fromFixedDate(fixedDate);
        try testing.expect(0 == actualGreg.compare(e));

        const fixedDateTime = fixed.DateTime{
            .date = fixedDate,
            .time = timeSegment,
        };
        const actualGregTime = DateTime.fromFixedDateTime(fixedDateTime);
        try testing.expectEqual(0, actualGregTime.date.compare(e));

        const actualFixedTime = actualGregTime.toFixedDateTime();
        try testing.expectEqualDeep(fixedDateTime, actualFixedTime);
    }

    var init = try Date.initNums(2024, 2, 29);
    try testing.expectEqualDeep(init, Date.fromFixedDate(init.toFixedDate()));

    init = try Date.initNums(2000, 2, 29);
    try testing.expectEqualDeep(init, Date.fromFixedDate(init.toFixedDate()));

    init = try Date.initNums(1900, 2, 28);
    try testing.expectEqualDeep(init, Date.fromFixedDate(init.toFixedDate()));

    // This hits a different period adjustment branch in fromFixedDate
    init = try Date.initNums(32, 12, 31);
    try testing.expectEqualDeep(init, Date.fromFixedDate(init.toFixedDate()));

    // We're seeding this manually to make sure the tests are't flaky
    var prng = @import("std").rand.DefaultPrng.init(592941772305693043);
    const rand = prng.random();

    // Run our calculation a lot to make sure it works
    for (0..1000) |_| {
        const start = fixed.Date{ .day = rand.int(i16) };
        const end = Date.fromFixedDate(start).toFixedDate();
        try testing.expectEqualDeep(start, end);
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
            .year = try adToAstro(@as(AnnoDominiYear, @enumFromInt(-1))),
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
pub const DateTime = CalendarDateTime(Date);

test "date time" {
    const dt1 = try DateTime.init(
        try Date.initNums(2022, 2, 15),
        try time.Segments.init(3, 23, 43, 0),
    );

    const dt2 = try DateTime.init(
        try Date.initNums(-432, 2, 15),
        try time.Segments.init(3, 23, 43, 0),
    );

    try testing.expectEqual(1, dt1.compare(dt2));
    try testing.expectEqual(-1, dt2.compare(dt1));
    try testing.expectEqual(0, dt1.compare(dt1));
}

test "day math" {
    const dt1 = try Date.initNums(2022, 2, 15);

    try testing.expectEqual(try Date.initNums(2022, 3, 2), dt1.addDays(15));
    try testing.expectEqual(try Date.initNums(2022, 1, 31), dt1.subDays(15));

    try testing.expectEqual(try Date.initNums(2023, 2, 15), dt1.addDays(365));
    try testing.expectEqual(try Date.initNums(2024, 2, 15), dt1.addDays(365 * 2));
    try testing.expectEqual(try Date.initNums(2025, 2, 14), dt1.addDays(365 * 3));
}

test "dayOfWeek" {
    const start = try Date.initNums(2024, 10, 11);
    var dt = start;

    try testing.expectEqual(core.DayOfWeek.Friday, dt.dayOfWeek());
    dt = start.addDays(1);
    try testing.expectEqual(core.DayOfWeek.Saturday, dt.dayOfWeek());
    dt = start.subDays(1);
    try testing.expectEqual(core.DayOfWeek.Thursday, dt.dayOfWeek());

    dt = start.addDays(2);
    try testing.expectEqual(core.DayOfWeek.Sunday, dt.dayOfWeek());
    dt = start.subDays(2);
    try testing.expectEqual(core.DayOfWeek.Wednesday, dt.dayOfWeek());

    dt = start.addDays(3);
    try testing.expectEqual(core.DayOfWeek.Monday, dt.dayOfWeek());
    dt = start.subDays(3);
    try testing.expectEqual(core.DayOfWeek.Tuesday, dt.dayOfWeek());

    dt = start.addDays(4);
    try testing.expectEqual(core.DayOfWeek.Tuesday, dt.dayOfWeek());
    dt = start.subDays(4);
    try testing.expectEqual(core.DayOfWeek.Monday, dt.dayOfWeek());

    dt = start.addDays(5);
    try testing.expectEqual(core.DayOfWeek.Wednesday, dt.dayOfWeek());
    dt = start.subDays(5);
    try testing.expectEqual(core.DayOfWeek.Sunday, dt.dayOfWeek());

    dt = start.addDays(6);
    try testing.expectEqual(core.DayOfWeek.Thursday, dt.dayOfWeek());
    dt = start.subDays(6);
    try testing.expectEqual(core.DayOfWeek.Saturday, dt.dayOfWeek());

    dt = start.addDays(7);
    try testing.expectEqual(core.DayOfWeek.Friday, dt.dayOfWeek());
    dt = start.subDays(7);
    try testing.expectEqual(core.DayOfWeek.Friday, dt.dayOfWeek());
}
