const epochs = @import("epochs.zig");
const time = @import("../calendars.zig").time;
const math = @import("../utils.zig").math;
const types = @import("../utils.zig").types;
const testing = @import("std").testing;
const assert = @import("std").debug.assert;
const fixed = @import("fixed.zig");
const core = @import("core.zig");
const std = @import("std");
const gregorian = @import("gregorian.zig");
const wrappers = @import("wrappers.zig");

const m = std.math;
const fmt = std.fmt;
const mem = std.mem;

const AstronomicalYear = core.AstronomicalYear;
const validateAstroYear = core.validateAstroYear;
const astroToAD = core.astroToAD;
const ValidationError = core.ValidationError;

pub const Date = struct {
    pub const Name = "ISO";
    year: AstronomicalYear = @enumFromInt(0),
    // The iso calendar works on weeks not months
    week: u8 = 1,
    day: u8 = 1,

    pub fn init(year: AstronomicalYear, week: u8, day: u8) !Date {
        const res = Date{ .year = year, .week = week, .day = day };
        try res.validate();
        return res;
    }

    pub fn initNums(year: i32, week: u8, day: u8) !Date {
        const res = Date{ .year = @enumFromInt(year), .week = week, .day = day };
        try res.validate();
        return res;
    }

    pub fn validate(self: Date) !void {
        try core.validateAstroYear(self.year);

        const numWeeks: u8 = if (self.isLongYear()) 53 else 52;
        if (self.week < 1 or self.week > numWeeks) {
            return ValidationError.InvalidWeek;
        }

        if (self.day < 1 or self.day > 7) {
            return ValidationError.InvalidDay;
        }
    }

    pub fn isLongYear(self: Date) bool {
        const jan1 = gregorian.yearStart(self.year);
        const dec31 = gregorian.yearEnd(self.year);

        return jan1.dayOfWeek() == .Thursday or dec31.dayOfWeek() == .Thursday;
    }

    pub fn toFixedDate(self: Date) fixed.Date {
        const year: i32 = @intFromEnum(self.year) - 1;
        const gregorianReference = gregorian.Date{
            .year = @as(AstronomicalYear, @enumFromInt(year)),
            .month = gregorian.Month.December,
            .day = 28,
        };
        assert(gregorianReference.isValid());
        const gregFixed = gregorianReference.toFixedDate();
        return gregFixed.nthWeekDay(self.week, .Sunday).addDays(self.day);
    }

    pub fn fromFixedDate(d: fixed.Date) Date {
        const approx = @intFromEnum(
            gregorian.Date.fromFixedDate(d.subDays(3)).year,
        );
        const approx_iso = Date{
            .year = @enumFromInt(approx + 1),
            .week = 1,
            .day = 1,
        };

        const approx_fixed = approx_iso.toFixedDate();
        const iso_year = if (d.compare(approx_fixed) >= 0) approx + 1 else approx;
        const iso_start = Date{
            .year = @enumFromInt(iso_year),
            .week = 1,
            .day = 1,
        };
        const iso_start_fixed = iso_start.toFixedDate();
        assert(iso_start_fixed.compare(d) <= 0);

        const iso_week = @divFloor(d.day - iso_start_fixed.day, 7) + 1;
        assert(iso_week >= 1 and iso_week <= 53);

        const iso_day = math.amod(u8, d.day, 7);
        assert(iso_day >= 1 and iso_day <= 7);

        const res = Date{
            .year = @enumFromInt(iso_year),
            .week = @as(u8, @intCast(iso_week)),
            .day = iso_day,
        };
        assert(res.isValid());

        return res;
    }

    pub fn asFixed(self: @This()) fixed.Date {
        return self.toFixedDate();
    }

    pub fn fromFixed(fd: fixed.Date) @This() {
        return @This().fromFixedDate(fd);
    }

    pub fn month(self: @This()) gregorian.Month {
        return gregorian.fromFixedDate(self.toFixedDate()).month;
    }

    pub fn dayInYear(self: @This()) gregorian.Month {
        return gregorian.fromFixedDate(self.toFixedDate()).dayInYear();
    }

    pub fn quarter(self: @This()) u32 {
        return gregorian.fromFixedDate(self.toFixedDate()).quarter();
    }

    pub usingnamespace wrappers.CalendarCompare(@This());
    pub usingnamespace wrappers.CalendarDayDiff(@This());
    pub usingnamespace wrappers.CalendarIsValid(@This());
    pub usingnamespace wrappers.CalendarDayMath(@This());
    pub usingnamespace wrappers.CalendarNearestValid(@This());
    pub usingnamespace wrappers.CalendarDayOfWeek(@This());
    pub usingnamespace wrappers.CalendarNthDays(@This());

    /// Formats iso Calendar into string form
    /// Will be in the format YYYY-WW-D ISO with astronomical years
    ///     (e.g. -0344-12-7 ISO       2023-34-3 ISO)
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
        if (y >= 0) {
            try writer.print("{d:0>4}-{d:0>2}-{d} ISO", .{
                @as(u32, @intCast(y)),
                self.week,
                self.day,
            });
        } else {
            try writer.print("-{d:0>4}-{d:0>2}-{d} ISO", .{
                @as(u32, @intCast(m.sign(y) * y)),
                self.week,
                self.day,
            });
        }
    }
};

pub const DateTime = wrappers.CalendarDateTime(Date);
pub const DateTimeZoned = wrappers.CalendarDateTimeZoned(Date);

test "dayOfWeek ms" {
    const start = try Date.initNums(2024, 41, 5);
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

test "iso conversions" {
    const fixed_dates = @import("./test_helpers.zig").sample_dates;

    const expected = [_]Date{
        Date{ .year = @enumFromInt(-586), .week = 29, .day = 7 },
        Date{ .year = @enumFromInt(-168), .week = 49, .day = 3 },
        Date{ .year = @enumFromInt(70), .week = 39, .day = 3 },
        Date{ .year = @enumFromInt(135), .week = 39, .day = 7 },
        Date{ .year = @enumFromInt(470), .week = 2, .day = 3 },
        Date{ .year = @enumFromInt(576), .week = 21, .day = 1 },
        Date{ .year = @enumFromInt(694), .week = 45, .day = 6 },
        Date{ .year = @enumFromInt(1013), .week = 16, .day = 7 },
        Date{ .year = @enumFromInt(1096), .week = 21, .day = 7 },
        Date{ .year = @enumFromInt(1190), .week = 12, .day = 5 },
        Date{ .year = @enumFromInt(1240), .week = 10, .day = 6 },
        Date{ .year = @enumFromInt(1288), .week = 14, .day = 5 },
        Date{ .year = @enumFromInt(1298), .week = 17, .day = 7 },
        Date{ .year = @enumFromInt(1391), .week = 23, .day = 7 },
        Date{ .year = @enumFromInt(1436), .week = 5, .day = 3 },
        Date{ .year = @enumFromInt(1492), .week = 14, .day = 6 },
        Date{ .year = @enumFromInt(1553), .week = 38, .day = 6 },
        Date{ .year = @enumFromInt(1560), .week = 9, .day = 6 },
        Date{ .year = @enumFromInt(1648), .week = 24, .day = 3 },
        Date{ .year = @enumFromInt(1680), .week = 26, .day = 7 },
        Date{ .year = @enumFromInt(1716), .week = 30, .day = 5 },
        Date{ .year = @enumFromInt(1768), .week = 24, .day = 7 },
        Date{ .year = @enumFromInt(1819), .week = 31, .day = 1 },
        Date{ .year = @enumFromInt(1839), .week = 13, .day = 3 },
        Date{ .year = @enumFromInt(1903), .week = 16, .day = 7 },
        Date{ .year = @enumFromInt(1929), .week = 34, .day = 7 },
        Date{ .year = @enumFromInt(1941), .week = 40, .day = 1 },
        Date{ .year = @enumFromInt(1943), .week = 16, .day = 1 },
        Date{ .year = @enumFromInt(1943), .week = 40, .day = 4 },
        Date{ .year = @enumFromInt(1992), .week = 12, .day = 2 },
        Date{ .year = @enumFromInt(1996), .week = 8, .day = 7 },
        Date{ .year = @enumFromInt(2038), .week = 45, .day = 3 },
        Date{ .year = @enumFromInt(2094), .week = 28, .day = 7 },
    };

    assert(fixed_dates.len == expected.len);

    const timeSegment = try time.Segments.init(12, 0, 0, 0);

    for (fixed_dates, 0..) |fixedDate, index| {
        const e = expected[index];

        // Test converting from fixed
        const actual = Date.fromFixedDate(fixedDate);
        try testing.expect(0 == actual.compare(e));

        // Test convertintg to fixed
        const actualFixed = e.toFixedDate();
        try testing.expectEqual(fixedDate.day, actualFixed.day);

        const fixedDateTime = fixed.DateTime{
            .date = fixedDate,
            .time = timeSegment,
        };
        const actualTime = DateTime.fromFixedDateTime(fixedDateTime);
        try testing.expectEqual(0, actualTime.date.compare(e));

        const actualFixedTime = actualTime.toFixedDateTime();
        try testing.expectEqualDeep(fixedDateTime, actualFixedTime);
    }

    var init = try Date.initNums(2024, 9, 6);
    try testing.expectEqualDeep(init, Date.fromFixedDate(init.toFixedDate()));

    init = try Date.initNums(2000, 9, 1);
    try testing.expectEqualDeep(init, Date.fromFixedDate(init.toFixedDate()));

    init = try Date.initNums(1900, 9, 3);
    try testing.expectEqualDeep(init, Date.fromFixedDate(init.toFixedDate()));

    // This hits a different period adjustment branch in fromFixedDate
    init = try Date.initNums(32, 52, 7);
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

test "iso formatting" {
    var list = @import("std").ArrayList(u8).init(testing.allocator);
    defer list.deinit();
    const testCases = [_]struct {
        date: Date,
        expected: []const u8,
    }{
        .{
            .date = Date{},
            .expected = "0000-01-1 ISO",
        },
        .{
            .date = Date{
                .year = @enumFromInt(2024),
                .week = 11,
                .day = 7,
            },
            .expected = "2024-11-7 ISO",
        },
        .{
            .date = Date{
                .year = @enumFromInt(202456),
                .week = 2,
                .day = 3,
            },
            .expected = "202456-02-3 ISO",
        },
        .{
            .date = Date{
                .year = @enumFromInt(-2025),
                .week = 29,
                .day = 2,
            },
            .expected = "-2025-29-2 ISO",
        },
    };

    for (testCases) |testCase| {
        defer list.clearRetainingCapacity();

        try list.writer().print("{}", .{testCase.date});
        try testing.expectEqualStrings(testCase.expected, list.items);
    }
}

test "iso date grade" {
    const features = @import("../utils/features.zig");
    const grade = features.gradeDate(Date);
    try std.testing.expectEqual(features.CalendarRating.Recommended, grade.rating);
}

test "iso datetime grade" {
    const features = @import("../utils/features.zig");
    const grade = features.gradeDateTime(DateTime);
    try std.testing.expectEqual(features.CalendarRating.Recommended, grade.rating);
}

test "iso datetimezoned grade" {
    const features = @import("../utils/features.zig");
    const grade = features.gradeDateTimeZoned(DateTimeZoned);
    try std.testing.expectEqual(features.CalendarRating.Recommended, grade.rating);
}
