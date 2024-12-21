const epochs = @import("epochs.zig");
const time = @import("../calendars.zig").time;
const math = @import("../utils.zig").math;
const types = @import("../utils.zig").types;
const testing = @import("std").testing;
const assert = @import("std").debug.assert;
const fixed = @import("fixed.zig");
const core = @import("core.zig");
const wrappers = @import("wrappers.zig");
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

pub const MonthIterResolution = enum { EndOfMonth, DayOfMonth };
pub const MonthIterOptions = struct {
    resolution: MonthIterResolution = .DayOfMonth,
    day: ?u8 = null,
    max: usize = m.maxInt(usize),
    step: i32 = 1,
    include_first: bool = false,
};

pub const MonthIter = struct {
    _opts: MonthIterOptions = .{},
    _start: Date,
    _n: i32 = 0,
    _cycle: usize = 0,

    pub fn next(self: *@This()) ?Date {
        if (self._cycle >= self._opts.max) return null;
        defer self._cycle += 1;

        if (self._cycle == 0 and self._opts.include_first) {
            return self._start;
        }

        self._n += self._opts.step;

        var res = self._start.addMonths(self._n);
        if (self._opts.resolution == .EndOfMonth) {
            res.day = res.daysInMonth();
        } else if (self._opts.day) |d| {
            res.day = @min(d, res.daysInMonth());
        }
        return res;
    }
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
pub fn yearStart(year: AstronomicalYear) Date {
    validateAstroYear(year) catch unreachable;
    return Date{ .year = year, .month = .January, .day = 1 };
}

/// Gets a date representing the end of a year
pub fn yearEnd(year: AstronomicalYear) Date {
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
    pub const Name = "Gregorian";
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

        const res = Date{
            .year = y,
            .month = @enumFromInt(month),
            .day = @as(u8, @intCast(day)),
        };

        const dayMax = res.daysInMonth();
        if (res.day > dayMax or res.day < 1) {
            return core.ValidationError.InvalidDay;
        }
        return res;
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
    pub fn daysInMonth(self: Date) u8 {
        return switch (self.month) {
            .January, .March, .May, .July, .August, .October, .December => 31,
            .April, .June, .September, .November => 30,
            .February => if (self.isLeapYear()) 29 else 28,
        };
    }

    pub fn monthsIter(self: @This(), opts: MonthIterOptions) MonthIter {
        return MonthIter{
            ._start = self,
            ._opts = opts,
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

    /// Returns the quarter the year is in (between 1-4 inclusive)
    pub fn quarter(self: Date) u32 {
        const month: u32 = @intFromEnum(self.month);
        if (month <= 3) {
            return 1;
        } else if (month <= 6) {
            return 2;
        } else if (month <= 9) {
            return 3;
        } else {
            return 4;
        }
    }

    /// Checks whether the gregorian date is a leap year or not
    pub fn isLeapYear(self: Date) bool {
        return leapYear(self.year);
    }

    /// Returns the week in the year based on the ISO calendar
    pub fn week(self: Date) u8 {
        const iso = @import("iso.zig");
        const i = iso.Date.fromFixedDate(self.toFixedDate());
        return i.week;
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
    pub fn dayInYear(self: Date) i32 {
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

    pub usingnamespace wrappers.CalendarDayDiff(@This());
    pub usingnamespace wrappers.CalendarIsValid(@This());
    pub usingnamespace wrappers.CalendarDayMath(@This());
    pub usingnamespace wrappers.CalendarNearestValid(@This());
    pub usingnamespace wrappers.CalendarDayOfWeek(@This());
    pub usingnamespace wrappers.CalendarNthDays(@This());

    /// Adds n months to the current date
    pub fn addMonths(self: @This(), n: i32) @This() {
        var new_date = self;
        const target_month = @intFromEnum(new_date.month) + n;
        const num_years = @divFloor(target_month - 1, 12);
        const month_in_year = math.amod(i32, target_month, 12);
        std.debug.assert(month_in_year >= 1);
        std.debug.assert(month_in_year <= 12);
        new_date.month = @enumFromInt(month_in_year);
        new_date.year = @enumFromInt(@intFromEnum(new_date.year) + num_years);
        new_date.day = @min(new_date.day, new_date.daysInMonth());
        new_date.validate() catch unreachable;
        return new_date;
    }

    /// Subtracts n months to the current date
    pub fn subMonths(self: @This(), n: i32) @This() {
        return self.addMonths(-n);
    }

    /// Adds n weeks to the current date
    pub fn addWeeks(self: @This(), n: i32) @This() {
        return self.addDays(n * 7);
    }
    /// Subtracts n weeks to the current date
    pub fn subWeeks(self: @This(), n: i32) @This() {
        return self.subDays(n * 7);
    }

    /// Adds n years to the current date
    pub fn addYears(self: @This(), n: i32) @This() {
        var new_date = self;
        new_date.year = @enumFromInt(@intFromEnum(self.year) + n);
        // Handle leap year
        new_date.day = @min(new_date.day, new_date.daysInMonth());
        new_date.validate() catch unreachable;
        return new_date;
    }

    /// Subtracts n years to the current date
    pub fn subYears(self: @This(), n: i32) @This() {
        return self.addYears(-n);
    }
};

test "sub months" {
    {
        const start = try Date.initNums(2023, 12, 31);
        try std.testing.expectEqualDeep(try Date.initNums(2023, 11, 30), start.subMonths(1));
        try std.testing.expectEqualDeep(try Date.initNums(2022, 11, 30), start.subMonths(13));
        try std.testing.expectEqualDeep(try Date.initNums(2023, 2, 28), start.subMonths(10));
        try std.testing.expectEqualDeep(try Date.initNums(2020, 2, 29), start.subMonths(46));
        try std.testing.expectEqualDeep(try Date.initNums(2023, 6, 30), start.subMonths(6));
        try std.testing.expectEqualDeep(try Date.initNums(2023, 7, 31), start.subMonths(5));
        try std.testing.expectEqualDeep(try Date.initNums(2022, 12, 31), start.subMonths(12));
        try std.testing.expectEqualDeep(try Date.initNums(2022, 8, 31), start.subMonths(16));
        try std.testing.expectEqualDeep(try Date.initNums(2022, 6, 30), start.subMonths(18));
        try std.testing.expectEqualDeep(try Date.initNums(2021, 12, 31), start.subMonths(24));
        try std.testing.expectEqualDeep(try Date.initNums(2022, 1, 31), start.subMonths(23));
        try std.testing.expectEqualDeep(try Date.initNums(2020, 12, 31), start.subMonths(36));
        try std.testing.expectEqualDeep(try Date.initNums(2018, 12, 31), start.subMonths(60));
    }
}

test "add months" {
    {
        const start = try Date.initNums(2023, 1, 16);
        try std.testing.expectEqualDeep(try Date.initNums(2023, 2, 16), start.addMonths(1));
        try std.testing.expectEqualDeep(try Date.initNums(2024, 2, 16), start.addMonths(13));
        try std.testing.expectEqualDeep(try Date.initNums(2023, 7, 16), start.addMonths(6));
        try std.testing.expectEqualDeep(try Date.initNums(2024, 1, 16), start.addMonths(12));
        try std.testing.expectEqualDeep(try Date.initNums(2024, 5, 16), start.addMonths(16));
        try std.testing.expectEqualDeep(try Date.initNums(2024, 7, 16), start.addMonths(18));
        try std.testing.expectEqualDeep(try Date.initNums(2025, 1, 16), start.addMonths(24));
        try std.testing.expectEqualDeep(try Date.initNums(2025, 12, 16), start.addMonths(35));
        try std.testing.expectEqualDeep(try Date.initNums(2027, 1, 16), start.addMonths(48));
        try std.testing.expectEqualDeep(try Date.initNums(2028, 1, 16), start.addMonths(60));
    }
    {
        const start = try Date.initNums(2023, 1, 31);
        try std.testing.expectEqualDeep(try Date.initNums(2023, 2, 28), start.addMonths(1));
        try std.testing.expectEqualDeep(try Date.initNums(2024, 2, 29), start.addMonths(13));
        try std.testing.expectEqualDeep(try Date.initNums(2023, 2, 28), start.addMonths(1));
        try std.testing.expectEqualDeep(try Date.initNums(2023, 7, 31), start.addMonths(6));
        try std.testing.expectEqualDeep(try Date.initNums(2023, 6, 30), start.addMonths(5));
        try std.testing.expectEqualDeep(try Date.initNums(2024, 1, 31), start.addMonths(12));
        try std.testing.expectEqualDeep(try Date.initNums(2024, 5, 31), start.addMonths(16));
        try std.testing.expectEqualDeep(try Date.initNums(2024, 7, 31), start.addMonths(18));
        try std.testing.expectEqualDeep(try Date.initNums(2025, 1, 31), start.addMonths(24));
        try std.testing.expectEqualDeep(try Date.initNums(2025, 12, 31), start.addMonths(35));
        try std.testing.expectEqualDeep(try Date.initNums(2027, 1, 31), start.addMonths(48));
        try std.testing.expectEqualDeep(try Date.initNums(2028, 1, 31), start.addMonths(60));
    }
}

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
            testCase.dayInYear() + testCase.daysRemaining(),
            expected,
        );

        const mismatched = testCase.dayInYear() != testCase.daysRemaining();
        const midPoint = expected == 366 and testCase.dayInYear() == 366 / 2;
        try testing.expect(mismatched or midPoint);
    }
}

test "gregorian conversions" {
    const fixed_dates = @import("test_helpers.zig").sample_dates;

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

    assert(fixed_dates.len == expected.len);

    const timeSegment = try time.Segments.init(12, 0, 0, 0);

    for (fixed_dates, expected) |fixedDate, e| {
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
    var prng = std.Random.DefaultPrng.init(592941772305693043);
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
    const adToAstro = @import("core.zig").adToAstro;
    const AnnoDominiYear = @import("core.zig").AnnoDominiYear;
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
pub const DateTime = wrappers.CalendarDateTime(Date);
pub const DateTimeZoned = wrappers.CalendarDateTimeZoned(Date);

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
    const UTC = @import("zone.zig").UTC;

    const TestCase = struct {
        day_diff: i32,
        dow: core.DayOfWeek,
    };

    const test_cases = [_]TestCase{
        .{ .day_diff = 0, .dow = .Friday },
        .{ .day_diff = 1, .dow = .Saturday },
        .{ .day_diff = 2, .dow = .Sunday },
        .{ .day_diff = 3, .dow = .Monday },
        .{ .day_diff = 4, .dow = .Tuesday },
        .{ .day_diff = 5, .dow = .Wednesday },
        .{ .day_diff = 6, .dow = .Thursday },
        .{ .day_diff = 7, .dow = .Friday },
        .{ .day_diff = -1, .dow = .Thursday },
        .{ .day_diff = -2, .dow = .Wednesday },
        .{ .day_diff = -3, .dow = .Tuesday },
        .{ .day_diff = -4, .dow = .Monday },
        .{ .day_diff = -5, .dow = .Sunday },
        .{ .day_diff = -6, .dow = .Saturday },
        .{ .day_diff = -7, .dow = .Friday },
    };

    for (test_cases) |tc| {
        const d = start.addDays(tc.day_diff);
        try testing.expectEqual(tc.dow, d.dayOfWeek());

        const dt = DateTime{
            .date = d,
            .time = (try time.DayFraction.init(0.5)).toSegments(),
        };
        try testing.expectEqual(tc.dow, dt.dayOfWeek());

        const dtz = DateTimeZoned{
            .date = d,
            .time = (try time.DayFraction.init(0.5)).toSegments(),
            .zone = UTC,
        };
        try testing.expectEqual(tc.dow, dtz.dayOfWeek());
    }
}

test "timezone safe" {
    const zone = @import("zone.zig");
    const zone1 = try zone.TimeZone.init(.{ .hours = -7, .minutes = 10, .seconds = 4 }, null);
    const zone2 = try zone.TimeZone.init(.{ .hours = 5, .minutes = 10, .seconds = 4 }, null);

    // Test no date rollover
    const time_utc_safe = try DateTimeZoned.init(
        try Date.initNums(2024, 2, 28),
        try DateTime.Time.init(12, 30, 24, 0),
        zone.UTC,
    );
    const time_z1_safe = time_utc_safe.toTimezone(zone1);
    const time_z2_safe = time_utc_safe.toTimezone(zone2);

    try std.testing.expectEqualDeep(time_utc_safe.date, time_z1_safe.date);
    try std.testing.expectEqualDeep(time_utc_safe.date, time_z2_safe.date);

    // Make sure we have the right time
    try std.testing.expectEqual(5, time_z1_safe.time.hour);
    try std.testing.expectEqual(20, time_z1_safe.time.minute);
    try std.testing.expectEqual(20, time_z1_safe.time.second);

    try std.testing.expectEqual(17, time_z2_safe.time.hour);
    try std.testing.expectEqual(40, time_z2_safe.time.minute);
    try std.testing.expectEqual(28, time_z2_safe.time.second);

    try std.testing.expectEqualDeep(time_utc_safe, time_z1_safe.toUtc());
    try std.testing.expectEqualDeep(time_utc_safe, time_z2_safe.toUtc());
}

test "timezone roll back" {
    const zone = @import("zone.zig");
    const zone1 = try zone.TimeZone.init(.{ .hours = -7, .minutes = 10, .seconds = 4 }, null);

    // Test no date rollover
    const time_utc_safe = try DateTimeZoned.init(
        try Date.initNums(2024, 2, 1),
        try DateTime.Time.init(2, 30, 24, 0),
        zone.UTC,
    );
    const time_z1_safe = time_utc_safe.toTimezone(zone1);

    // Make sure we have the right date
    try std.testing.expectEqual(2024, @intFromEnum(time_z1_safe.date.year));
    try std.testing.expectEqual(1, @intFromEnum(time_z1_safe.date.month));
    try std.testing.expectEqual(31, time_z1_safe.date.day);

    // Make sure we have the right time
    try std.testing.expectEqual(19, time_z1_safe.time.hour);
    try std.testing.expectEqual(20, time_z1_safe.time.minute);
    try std.testing.expectEqual(20, time_z1_safe.time.second);

    try std.testing.expectEqualDeep(time_utc_safe, time_z1_safe.toUtc());
}

test "timezone roll forward" {
    const zone = @import("zone.zig");
    const zone2 = try zone.TimeZone.init(.{ .hours = 5, .minutes = 10, .seconds = 4 }, null);

    // Test no date rollover
    const time_utc_safe = try DateTimeZoned.init(
        try Date.initNums(2024, 2, 29),
        try DateTime.Time.init(23, 30, 24, 0),
        zone.UTC,
    );
    const time_z2_safe = time_utc_safe.toTimezone(zone2);

    // Make sure we have the right date
    try std.testing.expectEqual(2024, @intFromEnum(time_z2_safe.date.year));
    try std.testing.expectEqual(3, @intFromEnum(time_z2_safe.date.month));
    try std.testing.expectEqual(1, time_z2_safe.date.day);

    // Make sure we have the right time
    try std.testing.expectEqual(4, time_z2_safe.time.hour);
    try std.testing.expectEqual(40, time_z2_safe.time.minute);
    try std.testing.expectEqual(28, time_z2_safe.time.second);

    try std.testing.expectEqualDeep(time_utc_safe, time_z2_safe.toUtc());
}

test "datenearest valid" {
    // Test no date rollover
    const dt1 = Date{
        .year = @enumFromInt(2024),
        .month = @enumFromInt(2),
        .day = 30,
    };
    const dt2 = Date.fromFixedDate(dt1.toFixedDate());

    // Make sure we have the right date
    try std.testing.expectEqual(2024, @intFromEnum(dt2.year));
    try std.testing.expectEqual(3, @intFromEnum(dt2.month));
    try std.testing.expectEqual(1, dt2.day);
}

test "datetime add seconds" {
    // Test no date rollover
    const dt1 = DateTime{
        .date = .{
            .year = @enumFromInt(2024),
            .month = @enumFromInt(3),
            .day = 2,
        },
        .time = .{ .hour = 23, .minute = 59, .second = 1, .nano = 0 },
    };
    const dt2 = dt1.addSeconds(60);

    // Make sure we have the right date
    try std.testing.expectEqual(2024, @intFromEnum(dt2.date.year));
    try std.testing.expectEqual(3, @intFromEnum(dt2.date.month));
    try std.testing.expectEqual(3, dt2.date.day);

    // Make sure we have the right time
    try std.testing.expectEqual(0, dt2.time.hour);
    try std.testing.expectEqual(0, dt2.time.minute);
    try std.testing.expectEqual(1, dt2.time.second);
}

test "datetime add minutes" {
    // Test no date rollover
    const dt1 = DateTime{
        .date = .{
            .year = @enumFromInt(2024),
            .month = @enumFromInt(3),
            .day = 2,
        },
        .time = .{ .hour = 23, .minute = 2, .second = 0, .nano = 0 },
    };
    const dt2 = dt1.addMinutes(60);

    // Make sure we have the right date
    try std.testing.expectEqual(2024, @intFromEnum(dt2.date.year));
    try std.testing.expectEqual(3, @intFromEnum(dt2.date.month));
    try std.testing.expectEqual(3, dt2.date.day);

    // Make sure we have the right time
    try std.testing.expectEqual(0, dt2.time.hour);
    try std.testing.expectEqual(2, dt2.time.minute);
    try std.testing.expectEqual(0, dt2.time.second);
}

test "datetime add hours" {
    // Test no date rollover
    const dt1 = DateTime{
        .date = .{
            .year = @enumFromInt(2024),
            .month = @enumFromInt(3),
            .day = 2,
        },
        .time = .{ .hour = 20, .minute = 2, .second = 0, .nano = 0 },
    };
    const dt2 = dt1.addHours(5);

    // Make sure we have the right date
    try std.testing.expectEqual(2024, @intFromEnum(dt2.date.year));
    try std.testing.expectEqual(3, @intFromEnum(dt2.date.month));
    try std.testing.expectEqual(3, dt2.date.day);

    // Make sure we have the right time
    try std.testing.expectEqual(1, dt2.time.hour);
    try std.testing.expectEqual(2, dt2.time.minute);
    try std.testing.expectEqual(0, dt2.time.second);
}

test "datetime subtract hours" {
    // Test no date rollover
    const dt1 = DateTime{
        .date = .{
            .year = @enumFromInt(2024),
            .month = @enumFromInt(3),
            .day = 2,
        },
        .time = .{ .hour = 2, .minute = 2, .second = 0, .nano = 0 },
    };
    const dt2 = dt1.subHours(3);

    // Make sure we have the right date
    try std.testing.expectEqual(2024, @intFromEnum(dt2.date.year));
    try std.testing.expectEqual(3, @intFromEnum(dt2.date.month));
    try std.testing.expectEqual(1, dt2.date.day);

    // Make sure we have the right time
    try std.testing.expectEqual(23, dt2.time.hour);
    try std.testing.expectEqual(2, dt2.time.minute);
    try std.testing.expectEqual(0, dt2.time.second);
}

test "datetime nearest valid" {
    // Test no date rollover
    const dt1 = DateTime{
        .date = .{
            .year = @enumFromInt(2024),
            .month = @enumFromInt(2),
            .day = 30,
        },
        .time = .{ .hour = 29, .minute = 61, .second = 61, .nano = 0 },
    };
    const dt2 = dt1.nearestValid();

    // Make sure we have the right date
    try std.testing.expectEqual(2024, @intFromEnum(dt2.date.year));
    try std.testing.expectEqual(3, @intFromEnum(dt2.date.month));
    try std.testing.expectEqual(2, dt2.date.day);

    // Make sure we have the right time
    try std.testing.expectEqual(6, dt2.time.hour);
    try std.testing.expectEqual(2, dt2.time.minute);
    try std.testing.expectEqual(0, dt2.time.second);
}

test "datetimezone nearest valid" {
    const zone = @import("zone.zig");
    // Test no date rollover
    const dt1 = DateTimeZoned{
        .date = .{
            .year = @enumFromInt(2024),
            .month = @enumFromInt(2),
            .day = 30,
        },
        .time = .{ .hour = 29, .minute = 61, .second = 61, .nano = 0 },
        .zone = zone.UTC,
    };
    const dt2 = dt1.nearestValid();

    // Make sure we have the right date
    try std.testing.expectEqual(2024, @intFromEnum(dt2.date.year));
    try std.testing.expectEqual(3, @intFromEnum(dt2.date.month));
    try std.testing.expectEqual(2, dt2.date.day);

    // Make sure we have the right time
    try std.testing.expectEqual(6, dt2.time.hour);
    try std.testing.expectEqual(2, dt2.time.minute);
    try std.testing.expectEqual(0, dt2.time.second);
}

test "gregorian grade" {
    const features = @import("../utils/features.zig");
    const grade = features.gradeDate(Date);
    try std.testing.expectEqual(features.CalendarRating.Recommended, grade.rating);
}

test "gregorian datetime grade" {
    const features = @import("../utils/features.zig");
    const grade = features.gradeDateTime(DateTime);
    try std.testing.expectEqual(features.CalendarRating.Recommended, grade.rating);
}

test "gregorian datetimezoned grade" {
    const features = @import("../utils/features.zig");
    const grade = features.gradeDateTimeZoned(DateTimeZoned);
    try std.testing.expectEqual(features.CalendarRating.Recommended, grade.rating);
}

test "month iteration 1 31" {
    var iter = (try Date.initNums(2024, 1, 31)).monthsIter(.{});
    try std.testing.expectEqualDeep(try Date.initNums(2024, 2, 29), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 3, 31), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 4, 30), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 5, 31), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 6, 30), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 7, 31), iter.next().?);
}

test "month iteration 2 29" {
    var iter = (try Date.initNums(2024, 2, 29)).monthsIter(.{});
    try std.testing.expectEqualDeep(try Date.initNums(2024, 3, 29), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 4, 29), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 5, 29), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 6, 29), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 7, 29), iter.next().?);
}

test "month iteration 2 29 end" {
    var iter = (try Date.initNums(2024, 2, 29)).monthsIter(.{ .resolution = .EndOfMonth });
    try std.testing.expectEqualDeep(try Date.initNums(2024, 3, 31), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 4, 30), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 5, 31), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 6, 30), iter.next().?);
    try std.testing.expectEqualDeep(try Date.initNums(2024, 7, 31), iter.next().?);
}
