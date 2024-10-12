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
const gregorian = @import("./gregorian.zig");

const m = std.math;
const fmt = std.fmt;
const mem = std.mem;

const AstronomicalYear = core.AstronomicalYear;
const validateAstroYear = core.validateAstroYear;
const astroToAD = core.astroToAD;
const ValidationError = core.ValidationError;

pub const Date = struct {
    year: AstronomicalYear,
    // The iso calendar works on weeks not months
    week: u8,
    day: u8,

    pub usingnamespace CalendarMixin(Date);

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

        const numWeeks = if (self.numberWeeksInYear()) 53 else 52;
        if (self.week < 1 or self.week > numWeeks) {
            return ValidationError.InvalidWeek;
        }

        if (self.day < 1 or self.day > 7) {
            return ValidationError.InvalidDay;
        }
    }

    pub fn isLongYear(self: Date) fixed.Date {
        const jan1 = gregorian.yearStart(self.year);
        const dec31 = gregorian.yearEnd(self.year);

        return jan1.dayOfWeek() == .Thursday or dec31.dayOfWeek() == .Thursday;
    }

    pub fn toFixedDate(self: Date) fixed.Date {
        const gregorianReference = gregorian.Date{
            .year = @enumFromInt(@intFromEnum(self.year) - 1),
            .month = gregorian.Month.December,
            .day = 28,
        };
        assert(gregorianReference.isValid());
        return gregorianReference.nthWeekDay(
            self.week,
            .Sunday,
        ).addDays(self.day);
    }

    pub fn fromFixedDate(d: fixed.Date) Date {
        const approx = @intFromEnum(
            gregorian.Date.fromFixedDate(d.subDays(3)).year,
        );
        const approxIso = Date{
            .year = @enumFromInt(approx + 1),
            .week = 1,
            .day = 1,
        };
        const approxFixed = approxIso.toFixedDate();
        const isoYear = if (d.compare(approxFixed) >= 0) approx + 1 else approx;
        const isoStart = Date{
            .year = @enumFromInt(isoYear),
            .week = 1,
            .day = 1,
        };
        const isoStartFixed = isoStart.toFixedDate();
        assert(isoStartFixed.compare(d) <= 0);

        const isoWeek = @divFloor(d.day - isoStartFixed.day, 7) + 1;
        assert(isoWeek >= 1 and isoWeek <= 53);

        const isoDay = math.amod(u8, d.day, 7);
        assert(isoDay >= 1 and isoDay <= 7);

        const res = Date{
            .year = @enumFromInt(isoYear),
            .week = @as(u8, @intCast(isoWeek)),
            .day = isoDay,
        };
        assert(res.isValid());

        return res;
    }
};

pub const DateTime = CalendarDateTime(Date);

test "iso conversions" {
    const fixedDates = @import("./test_helpers.zig").sampleDates;

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
