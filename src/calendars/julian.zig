const epochs = @import("epochs.zig");
const time = @import("../calendars.zig").time;
const math = @import("../utils.zig").math;
const std = @import("std");
const assert = std.debug.assert;
const core = @import("core.zig");
const wrappers = @import("wrappers.zig");
const fixed = @import("fixed.zig");
const testing = std.testing;

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

pub const Date = struct {
    pub const Name = "Julian";
    year: core.AnnoDominiYear = @enumFromInt(1),
    month: Month = .January,
    day: u8 = 1,

    /// Creates a new julian date (and validates the date)
    pub fn init(year: core.AnnoDominiYear, month: Month, day: u8) !Date {
        const res = Date{ .year = year, .month = month, .day = day };
        try res.validate();
        return res;
    }

    /// Creates a new julian date. Will convert numbers to types
    pub fn initNums(year: i32, month: i32, day: i32) !Date {
        const y: core.AnnoDominiYear = @enumFromInt(year);
        try core.validateAdYear(y);

        if (month < 1 or month > 12) {
            return core.ValidationError.InvalidMonth;
        }

        if (day > 31 or day < 1) {
            return core.ValidationError.InvalidDay;
        }

        const res = Date{
            .year = y,
            .month = @enumFromInt(month),
            .day = @intCast(day),
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
            return core.ValidationError.InvalidMonth;
        }

        try core.validateAdYear(self.year);

        const dayMax = self.daysInMonth();
        if (self.day > dayMax or self.day < 1) {
            return core.ValidationError.InvalidDay;
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

    /// Converts from a fixed date
    pub fn fromFixedDate(d: fixed.Date) Date {
        const approx = @divFloor(4 * d.subDays(epochs.julian).day + 1464, 1461);
        const julianYear = if (approx <= 0) approx - 1 else approx;
        assert(julianYear != 0);
        const julianStart = Date{
            .year = @enumFromInt(julianYear),
            .month = .January,
            .day = 1,
        };
        const priorDays = d.dayDifference(julianStart.toFixedDate());
        const marchFirst = Date.init(@enumFromInt(julianYear), .March, 1) catch unreachable;

        var correction: i32 = 0;
        if (d.compare(marchFirst.toFixedDate()) >= 0) {
            if (julianStart.isLeapYear()) {
                correction = 1;
            } else {
                correction = 2;
            }
        }
        const julianMonth = @divFloor(12 * (priorDays + correction) + 373, 367);
        const monthStart = Date.initNums(julianYear, julianMonth, 1) catch unreachable;
        const julianDay = d.dayDifference(monthStart.toFixedDate()) + 1;
        return Date.initNums(julianYear, julianMonth, julianDay) catch unreachable;
    }

    /// Converts to a fixed date
    pub fn toFixedDate(self: Date) fixed.Date {
        const year = @intFromEnum(self.year);
        const y: i32 = if (year < 0) year + 1 else year;
        const epochCorrection = epochs.julian - 1;
        const yearEstimate = 365 * (y - 1);
        const leapYearEstimate = @divFloor(y - 1, 4);
        var sum = epochCorrection + yearEstimate + leapYearEstimate;

        const monthEstimate = @divFloor(
            367 * @as(i32, @intCast(@intFromEnum(self.month))) - 362,
            12,
        );

        sum += monthEstimate;

        // month correction
        if (@intFromEnum(self.month) <= 2) {
            // No correction needed
        } else if (self.isLeapYear()) {
            sum -= 1;
        } else {
            sum -= 2;
        }

        return fixed.Date{ .day = sum + self.day };
    }

    /// Checks whether the julian date is a leap year or not
    pub fn isLeapYear(self: Date) bool {
        const year = @intFromEnum(self.year);
        if (year > 0) {
            return math.mod(i32, year, 4) == 0;
        }
        return math.mod(i32, year, 4) == 3;
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

    /// Formats orian Calendar into string form
    /// Will be in the format Month day, year A.D. JULIAN
    ///     (e.g. March 23, 345 B.C. JULIAN    April 3, 2023 A.D. JULIAN)
    pub fn format(
        self: Date,
        comptime f: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = f;

        self.validate() catch {
            try writer.print("INVALID: ", .{});
        };
        const y = @intFromEnum(self.year);
        const month = @tagName(self.month);
        const adOrBc = if (y > 0) "A.D." else "B.C.";
        const yAbs = @as(u32, @intCast(y * std.math.sign(y)));

        try writer.print("{s} {d}, {d} {s} JULIAN", .{
            month,
            self.day,
            yAbs,
            adOrBc,
        });
    }

    pub fn asFixed(self: @This()) fixed.Date {
        return self.toFixedDate();
    }

    pub fn fromFixed(fd: fixed.Date) @This() {
        return @This().fromFixedDate(fd);
    }

    pub fn week(self: @This()) u32 {
        const approx = @intFromEnum(
            @This().fromFixedDate(self.subDays(3)).year,
        );
        const approxIso = Date{
            .year = @enumFromInt(approx + 1),
            .week = 1,
            .day = 1,
        };

        const approxFixed = approxIso.toFixedDate();
        const year = if (self.compare(approxFixed) >= 0) approx + 1 else approx;
        const start = Date{
            .year = @enumFromInt(year),
            .week = 1,
            .day = 1,
        };
        const startFixed = start.toFixedDate();
        assert(startFixed.compare(self) <= 0);

        const res_week = @divFloor(self.day - startFixed.day, 7) + 1;
        assert(res_week >= 1 and res_week <= 53);
        return res_week;
    }

    pub usingnamespace wrappers.CalendarDayDiff(@This());
    pub usingnamespace wrappers.CalendarIsValid(@This());
    pub usingnamespace wrappers.CalendarDayMath(@This());
    pub usingnamespace wrappers.CalendarNearestValid(@This());
    pub usingnamespace wrappers.CalendarDayOfWeek(@This());
    pub usingnamespace wrappers.CalendarNthDays(@This());
};

test "julian conversions" {
    const fixed_dates = @import("test_helpers.zig").sample_dates;

    const expected = [_]Date{
        Date{ .year = @enumFromInt(-587), .month = @enumFromInt(7), .day = 30 },
        Date{ .year = @enumFromInt(-169), .month = @enumFromInt(12), .day = 8 },
        Date{ .year = @enumFromInt(70), .month = @enumFromInt(9), .day = 26 },
        Date{ .year = @enumFromInt(135), .month = @enumFromInt(10), .day = 3 },
        Date{ .year = @enumFromInt(470), .month = @enumFromInt(1), .day = 7 },
        Date{ .year = @enumFromInt(576), .month = @enumFromInt(5), .day = 18 },
        Date{ .year = @enumFromInt(694), .month = @enumFromInt(11), .day = 7 },
        Date{ .year = @enumFromInt(1013), .month = @enumFromInt(4), .day = 19 },
        Date{ .year = @enumFromInt(1096), .month = @enumFromInt(5), .day = 18 },
        Date{ .year = @enumFromInt(1190), .month = @enumFromInt(3), .day = 16 },
        Date{ .year = @enumFromInt(1240), .month = @enumFromInt(3), .day = 3 },
        Date{ .year = @enumFromInt(1288), .month = @enumFromInt(3), .day = 26 },
        Date{ .year = @enumFromInt(1298), .month = @enumFromInt(4), .day = 20 },
        Date{ .year = @enumFromInt(1391), .month = @enumFromInt(6), .day = 4 },
        Date{ .year = @enumFromInt(1436), .month = @enumFromInt(1), .day = 25 },
        Date{ .year = @enumFromInt(1492), .month = @enumFromInt(3), .day = 31 },
        Date{ .year = @enumFromInt(1553), .month = @enumFromInt(9), .day = 9 },
        Date{ .year = @enumFromInt(1560), .month = @enumFromInt(2), .day = 24 },
        Date{ .year = @enumFromInt(1648), .month = @enumFromInt(5), .day = 31 },
        Date{ .year = @enumFromInt(1680), .month = @enumFromInt(6), .day = 20 },
        Date{ .year = @enumFromInt(1716), .month = @enumFromInt(7), .day = 13 },
        Date{ .year = @enumFromInt(1768), .month = @enumFromInt(6), .day = 8 },
        Date{ .year = @enumFromInt(1819), .month = @enumFromInt(7), .day = 21 },
        Date{ .year = @enumFromInt(1839), .month = @enumFromInt(3), .day = 15 },
        Date{ .year = @enumFromInt(1903), .month = @enumFromInt(4), .day = 6 },
        Date{ .year = @enumFromInt(1929), .month = @enumFromInt(8), .day = 12 },
        Date{ .year = @enumFromInt(1941), .month = @enumFromInt(9), .day = 16 },
        Date{ .year = @enumFromInt(1943), .month = @enumFromInt(4), .day = 6 },
        Date{ .year = @enumFromInt(1943), .month = @enumFromInt(9), .day = 24 },
        Date{ .year = @enumFromInt(1992), .month = @enumFromInt(3), .day = 4 },
        Date{ .year = @enumFromInt(1996), .month = @enumFromInt(2), .day = 12 },
        Date{ .year = @enumFromInt(2038), .month = @enumFromInt(10), .day = 28 },
        Date{ .year = @enumFromInt(2094), .month = @enumFromInt(7), .day = 5 },
    };

    assert(fixed_dates.len == expected.len);

    const timeSegment = try time.Segments.init(12, 0, 0, 0);

    const fd = fixed.Date{ .day = 11321 };
    try testing.expectEqualDeep(fd, Date.fromFixed(fd).toFixedDate());

    for (fixed_dates, expected) |fixedDate, e| {
        // Test convertintg to fixed
        const actualFixed = e.toFixedDate();
        try testing.expectEqual(fixedDate.day, actualFixed.day);

        // Test converting from fixed
        const actual = Date.fromFixedDate(fixedDate);
        try testing.expect(0 == actual.compare(e));

        const fixedDateTime = fixed.DateTime{
            .date = fixedDate,
            .time = timeSegment,
        };
        const actualTime = DateTime.fromFixedDateTime(fixedDateTime);
        try testing.expectEqual(0, actualTime.date.compare(e));

        const actualFixedTime = actualTime.toFixedDateTime();
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

test "julian formatting" {
    var list = @import("std").ArrayList(u8).init(testing.allocator);
    defer list.deinit();
    const testCases = [_]struct {
        date: Date,
        expected: []const u8,
    }{
        .{
            .date = Date{},
            .expected = "January 1, 1 A.D. JULIAN",
        },
        .{
            .date = Date{
                .year = @enumFromInt(2024),
                .month = .February,
                .day = 29,
            },
            .expected = "February 29, 2024 A.D. JULIAN",
        },
        .{
            .date = Date{
                .year = @enumFromInt(202456),
                .month = .February,
                .day = 29,
            },
            .expected = "February 29, 202456 A.D. JULIAN",
        },
        .{
            .date = Date{
                .year = @enumFromInt(-2025),
                .month = .February,
                .day = 29,
            },
            .expected = "February 29, 2025 B.C. JULIAN",
        },
    };

    for (testCases) |testCase| {
        defer list.clearRetainingCapacity();

        try list.writer().print("{}", .{testCase.date});
        try testing.expectEqualStrings(testCase.expected, list.items);
    }
}

test "julian leap year" {
    const AnnoDominiYear = @import("./core.zig").AnnoDominiYear;
    try testing.expect(
        (Date{
            .year = @as(AnnoDominiYear, @enumFromInt(4)),
        }).isLeapYear(),
    );
    try testing.expect(
        (Date{
            .year = try core.astroToAD(@enumFromInt(0)),
        }).isLeapYear(),
    );
    try testing.expect((Date{ .year = @enumFromInt(4) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(8) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(2000) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(1900) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(1800) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(1700) }).isLeapYear());
    try testing.expect(!(Date{ .year = @enumFromInt(2023) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(2024) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(2020) }).isLeapYear());
    try testing.expect((Date{ .year = @enumFromInt(1600) }).isLeapYear());
}

/// Represents a julian date and time combination
pub const DateTime = wrappers.CalendarDateTime(Date);

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
    const start = try Date.initNums(2024, 10, 5);
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
