const std = @import("std");
const fixed = @import("../calendars/fixed.zig");
const DayFraction = @import("../calendars/time.zig").DayFraction;
const zone = @import("../calendars/zone.zig");
const meta = std.meta;

/// Converts a calendar from one date/date time/zoned date time to
/// another date/date time/zoned date time type
/// Note: This will convert to UTC when lozing timezone information
/// Note: This will assume UTC when inferning timezone information
pub fn convert(date_in: anytype, comptime Target: type) Target {
    const From = @TypeOf(date_in);

    if (comptime From == Target) {
        return date_in;
    } else if (comptime meta.hasFn(From, "toFixedDateTimeZoned")) {
        const dtz = date_in.toFixedDateTimeZoned();
        if (comptime meta.hasMethod(Target, "fromFixedDateTimeZoned")) {
            return Target.fromFixedDateTimeZoned(dtz);
        } else if (comptime meta.hasMethod(Target, "fromFixedDateTime")) {
            // Convert to UTC when losing time zones
            const dtzu = dtz.toUtc();
            const dt = fixed.DateTime{
                .date = dtzu.date,
                .time = dtzu.time,
            };
            return Target.fromFixedDateTime(dt);
        } else if (comptime meta.hasMethod(Target, "fromFixedDate")) {
            const dtzu = dtz.toUtc();
            return Target.fromFixedDate(dtzu.date);
        } else {
            unreachable;
        }
    } else if (comptime meta.hasFn(From, "toFixedDateTime")) {
        const dt = date_in.toFixedDateTime();
        if (comptime meta.hasMethod(Target, "fromFixedDateTimeZoned")) {
            const dtz = fixed.DateTimeZoned{
                .date = dt.date,
                .time = dt.time,
                .zone = zone.UTC,
            };
            return Target.fromFixedDateTimeZoned(dtz);
        } else if (comptime meta.hasMethod(Target, "fromFixedDateTime")) {
            return Target.fromFixedDateTime(dt);
        } else if (comptime meta.hasMethod(Target, "fromFixedDate")) {
            return Target.fromFixedDate(dt.date);
        } else {
            unreachable;
        }
    } else if (comptime meta.hasFn(From, "toFixedDate")) {
        if (comptime meta.hasMethod(Target, "fromFixedDateTimeZoned")) {
            const dtz = fixed.DateTimeZoned{
                .date = date_in.toFixedDate(),
                .time = (DayFraction{ .frac = 0 }).toSegments(),
                .zone = zone.UTC,
            };
            return Target.fromFixedDateTimeZoned(dtz);
        } else if (comptime meta.hasMethod(Target, "fromFixedDateTime")) {
            const dt = fixed.DateTime{
                .date = date_in.toFixedDate(),
                .time = (DayFraction{ .frac = 0 }).toSegments(),
            };
            return Target.fromFixedDateTime(dt);
        } else if (comptime meta.hasMethod(Target, "fromFixedDate")) {
            return Target.fromFixedDate(date_in.toFixedDate());
        } else {
            unreachable;
        }
    }
}

test "convert Gregorian <-> Unix Timestamp" {
    const greg = @import("../calendars/gregorian.zig");
    const unix = @import("../calendars/unix_timestamp.zig");

    {
        const date = try greg.Date.initNums(2024, 1, 13);
        const date_u = convert(date, unix.Timestamp);
        try std.testing.expectEqual(1705104000, date_u.seconds);
    }

    {
        const date = try greg.DateTime.init(
            try greg.Date.initNums(2024, 1, 13),
            try greg.DateTime.Time.init(12, 32, 34, 123),
        );
        const date_u = convert(date, unix.Timestamp);
        try std.testing.expectEqual(1705149154, date_u.seconds);
    }

    {
        const date = try greg.DateTimeZoned.init(
            try greg.Date.initNums(2024, 1, 13),
            try greg.DateTime.Time.init(12, 32, 34, 123),
            try zone.TimeZone.init(.{ .hours = -7 }, null),
        );
        const date_u = convert(date, unix.Timestamp);
        try std.testing.expectEqual(1705174354, date_u.seconds);
    }

    {
        const timestamp = unix.Timestamp.init(1705149154);
        const date_g = convert(timestamp, greg.Date);
        const expected = try greg.Date.initNums(2024, 1, 13);
        try std.testing.expectEqualDeep(expected, date_g);
    }

    {
        const timestamp = unix.Timestamp.init(1705149154);
        const date_g = convert(timestamp, greg.DateTime);
        const expected = try greg.DateTime.init(
            try greg.Date.initNums(2024, 1, 13),
            try greg.DateTime.Time.init(12, 32, 34, 0),
        );
        try std.testing.expectEqualDeep(expected, date_g);
    }

    {
        const timestamp = unix.Timestamp.init(1705149154);
        const date_g = convert(timestamp, greg.DateTimeZoned);
        const expected = try greg.DateTimeZoned.init(
            try greg.Date.initNums(2024, 1, 13),
            try greg.DateTime.Time.init(12, 32, 34, 0),
            zone.UTC,
        );
        try std.testing.expectEqualDeep(expected, date_g);
    }
}

test "convert Gregorian <-> ISO" {
    const greg = @import("../calendars/gregorian.zig");
    const iso = @import("../calendars/iso.zig");

    {
        const date = try greg.Date.initNums(2024, 1, 13);
        const date_i = convert(date, iso.Date);
        const date_it = convert(date, iso.DateTime);
        const date_itz = convert(date, iso.DateTimeZoned);
        const expected = try iso.Date.initNums(2024, 2, 6);
        try std.testing.expectEqualDeep(expected, date_i);

        try std.testing.expectEqualDeep(expected, date_it.date);
        try std.testing.expectEqual(0, date_it.time.toDayFraction().frac);

        try std.testing.expectEqualDeep(expected, date_itz.date);
        try std.testing.expectEqual(0, date_itz.time.toDayFraction().frac);
        try std.testing.expectEqual(zone.UTC, date_itz.zone);
    }

    {
        const expectedTime = try greg.DateTime.Time.init(12, 32, 34, 123);
        const date = try greg.DateTime.init(
            try greg.Date.initNums(2024, 1, 13),
            expectedTime,
        );

        const expected = try iso.Date.initNums(2024, 2, 6);
        const date_i = convert(date, iso.Date);
        const date_it = convert(date, iso.DateTime);
        const date_itz = convert(date, iso.DateTimeZoned);
        try std.testing.expectEqualDeep(expected, date_i);

        try std.testing.expectEqualDeep(expected, date_it.date);
        try std.testing.expectEqual(expectedTime, date_it.time);

        try std.testing.expectEqualDeep(expected, date_itz.date);
        try std.testing.expectEqual(expectedTime, date_itz.time);
        try std.testing.expectEqual(zone.UTC, date_itz.zone);
    }
}
