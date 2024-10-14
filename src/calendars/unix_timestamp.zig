const epochs = @import("./epochs.zig");
const time = @import("../calendars.zig").time;
const math = @import("../utils.zig").math;
const std = @import("std");
const fixed = @import("./fixed.zig");
const wrappers = @import("./wrappers.zig");
const assert = @import("std").debug.assert;
const testing = @import("std").testing;
const core = @import("./core.zig");

const secondsPerDay = 60 * 60 * 24;
const millisecondsPerDay = secondsPerDay * 1000;

/// Represents a unix timestamp in seconds
pub const Timestamp = struct {
    seconds: i64 = 0,

    pub fn init(seconds: i64) Timestamp {
        return Timestamp{ .seconds = seconds };
    }

    pub fn validate(self: @This()) !void {
        _ = self;
    }

    pub fn toFixedDateTime(self: Timestamp) fixed.DateTime {
        const ns = math.mod(u64, self.seconds, secondsPerDay) * @as(u64, 1e9);
        const day = @divFloor(self.seconds, secondsPerDay);
        const nano = time.NanoSeconds{ .nano = ns };

        return fixed.DateTime{
            .date = fixed.Date{ .day = @as(i32, @intCast(day + epochs.unix)) },
            .time = nano.toSegments(),
        };
    }

    pub fn fromFixedDateTime(f: fixed.DateTime) Timestamp {
        const day = @as(i64, f.date.day) - epochs.unix;
        const ns = @as(i64, @intCast(f.time.toNanoSeconds().nano));
        const sec = day * secondsPerDay + @divFloor(ns, @as(i64, 1e9));
        return Timestamp{ .seconds = sec };
    }

    pub fn asFixed(self: @This()) fixed.DateTime {
        return self.toFixedDateTime();
    }

    pub fn fromFixed(fd: fixed.DateTime) @This() {
        return @This().fromFixedDateTime(fd);
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
        self: Timestamp,
        comptime f: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = f;

        self.validate() catch {
            try writer.print("INVALID: ", .{});
        };
        try writer.print("{d} UNIX", .{
            self.seconds,
        });
    }
};

/// Represents a unix timestamp in milliseconds
pub const TimestampMs = struct {
    milliseconds: i64 = 0,

    pub fn init(milliseconds: i64) TimestampMs {
        return TimestampMs{ .milliseconds = milliseconds };
    }
    
    pub fn validate(self: @This()) !void {
        _ = self;
    }

    pub fn toFixedDateTime(self: TimestampMs) fixed.DateTime {
        const ms = math.mod(u64, self.milliseconds, millisecondsPerDay);
        const ns = ms * @as(u64, 1e6);
        const day = @divFloor(self.milliseconds, millisecondsPerDay);
        const nano = time.NanoSeconds{ .nano = ns };

        return fixed.DateTime{
            .date = fixed.Date{ .day = @as(i32, @intCast(day + epochs.unix)) },
            .time = nano.toSegments(),
        };
    }

    pub fn fromFixedDateTime(f: fixed.DateTime) TimestampMs {
        const day = @as(i64, f.date.day) - epochs.unix;
        const ns = @as(i64, @intCast(f.time.toNanoSeconds().nano));
        const ms = day * millisecondsPerDay + @divFloor(ns, @as(i64, 1e6));
        return TimestampMs{ .milliseconds = ms };
    }

    pub fn asFixed(self: @This()) fixed.DateTime {
        return self.toFixedDateTime();
    }

    pub fn fromFixed(fd: fixed.DateTime) @This() {
        return @This().fromFixedDateTime(fd);
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
        self: TimestampMs,
        comptime f: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = f;

        self.validate() catch {
            try writer.print("INVALID: ", .{});
        };
        try writer.print("{d}ms UNIX", .{
            self.milliseconds,
        });
    }
};

test "unix valid" {
    const ts = Timestamp{ .seconds = 1230920 };
    try testing.expect(ts.isValid());
    try testing.expectEqualDeep(ts, ts.nearestValid());
    try ts.validate();

    const tsMs = TimestampMs{ .milliseconds = 1230920000 };
    try testing.expect(tsMs.isValid());
    try testing.expectEqualDeep(tsMs, tsMs.nearestValid());
    try tsMs.validate();
}

test "add days" {
    const startFixedDay = 727274;
    const timeOfDay = 9999;
    const start = Timestamp{ .seconds = 700790400 + timeOfDay };

    var fixedTs = start.toFixedDateTime();
    try testing.expectEqual(
        timeOfDay * @as(u64, 1e9),
        fixedTs.time.toNanoSeconds().nano,
    );
    try testing.expectEqual(startFixedDay, fixedTs.date.day);

    fixedTs = start.addDays(7).toFixedDateTime();
    try testing.expectEqual(
        timeOfDay * @as(u64, 1e9),
        fixedTs.time.toNanoSeconds().nano,
    );
    try testing.expectEqual(startFixedDay + 7, fixedTs.date.day);
}

test "add days ms" {
    const startFixedDay = 727274;
    const timeOfDay = 9999;
    const start = TimestampMs{
        .milliseconds = (700790400 + timeOfDay) * 1000,
    };

    var fixedTs = start.toFixedDateTime();
    try testing.expectEqual(
        timeOfDay * @as(u64, 1e9),
        fixedTs.time.toNanoSeconds().nano,
    );
    try testing.expectEqual(startFixedDay, fixedTs.date.day);

    fixedTs = start.addDays(7).toFixedDateTime();
    try testing.expectEqual(
        timeOfDay * @as(u64, 1e9),
        fixedTs.time.toNanoSeconds().nano,
    );
    try testing.expectEqual(startFixedDay + 7, fixedTs.date.day);
}

test "dayOfWeek" {
    const start = Timestamp.init(1728048524);
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

test "dayOfWeek ms" {
    const start = TimestampMs.init(1728048524 * 1000);
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

test "unix convert" {
    const fixed_dates = @import("./test_helpers.zig").sample_dates;

    const expected = [_]Timestamp{
        Timestamp{ .seconds = -80641958400 },
        Timestamp{ .seconds = -67439520000 },
        Timestamp{ .seconds = -59935161600 },
        Timestamp{ .seconds = -57883334400 },
        Timestamp{ .seconds = -47334758400 },
        Timestamp{ .seconds = -43978291200 },
        Timestamp{ .seconds = -40239590400 },
        Timestamp{ .seconds = -30190147200 },
        Timestamp{ .seconds = -27568339200 },
        Timestamp{ .seconds = -24607411200 },
        Timestamp{ .seconds = -23030611200 },
        Timestamp{ .seconds = -21513859200 },
        Timestamp{ .seconds = -21196166400 },
        Timestamp{ .seconds = -18257443200 },
        Timestamp{ .seconds = -16848604800 },
        Timestamp{ .seconds = -15075676800 },
        Timestamp{ .seconds = -13136688000 },
        Timestamp{ .seconds = -12932870400 },
        Timestamp{ .seconds = -10147420800 },
        Timestamp{ .seconds = -9135849600 },
        Timestamp{ .seconds = -7997788800 },
        Timestamp{ .seconds = -6359817600 },
        Timestamp{ .seconds = -4746729600 },
        Timestamp{ .seconds = -4126636800 },
        Timestamp{ .seconds = -2105049600 },
        Timestamp{ .seconds = -1273449600 },
        Timestamp{ .seconds = -891734400 },
        Timestamp{ .seconds = -842745600 },
        Timestamp{ .seconds = -827971200 },
        Timestamp{ .seconds = 700790400 },
        Timestamp{ .seconds = 825206400 },
        Timestamp{ .seconds = 2172960000 },
        Timestamp{ .seconds = 3930249600 },
    };

    assert(fixed_dates.len == expected.len);

    for (fixed_dates, 0..) |fixedDate, index| {
        const e = expected[index];

        // Test convertintg to fixed
        const actualFixed = e.toFixedDateTime();
        try testing.expectEqual(fixedDate.day, actualFixed.date.day);

        // Test converting from fixed
        const actualTs = Timestamp.fromFixedDateTime(
            fixed.DateTime{ .date = fixedDate, .time = time.Segments{} },
        );
        try testing.expect(0 == actualTs.compare(e));

        const actualTsMs = TimestampMs.fromFixedDateTime(
            fixed.DateTime{ .date = fixedDate, .time = time.Segments{} },
        );
        try testing.expect(
            actualTsMs.milliseconds == actualTs.seconds * 1000,
        );
    }

    // Check that time is preserved
    const unixTs = Timestamp{ .seconds = 700790400 + 66 };
    const fixedTs = unixTs.toFixedDateTime();

    try testing.expectEqual(
        66 * @as(u64, 1e9),
        fixedTs.time.toNanoSeconds().nano,
    );
    try testing.expectEqual(727274, fixedTs.date.day);

    const unixTsRes = Timestamp.fromFixedDateTime(fixedTs);
    try testing.expectEqualDeep(unixTs, unixTsRes);
}

test "unix formatting" {
    var list = @import("std").ArrayList(u8).init(testing.allocator);
    defer list.deinit();
    const testCases = [_]struct {
        date: Timestamp,
        expected: []const u8,
    }{
        .{
            .date = Timestamp{},
            .expected = "0 UNIX",
        },
        .{
            .date = Timestamp{.seconds = 1232981273, },
            .expected = "1232981273 UNIX",
        },
        .{
            .date = Timestamp{.seconds = -349829834, },
            .expected = "-349829834 UNIX",
        },
    };

    for (testCases) |testCase| {
        defer list.clearRetainingCapacity();

        try list.writer().print("{}", .{testCase.date});
        try testing.expectEqualStrings(testCase.expected, list.items);
    }
}

test "unix ms formatting" {
    var list = @import("std").ArrayList(u8).init(testing.allocator);
    defer list.deinit();
    const testCases = [_]struct {
        date: TimestampMs,
        expected: []const u8,
    }{
        .{
            .date = TimestampMs{},
            .expected = "0ms UNIX",
        },
        .{
            .date = TimestampMs{.milliseconds = 1232981273, },
            .expected = "1232981273ms UNIX",
        },
        .{
            .date = TimestampMs{.milliseconds = -349829834, },
            .expected = "-349829834ms UNIX",
        },
    };

    for (testCases) |testCase| {
        defer list.clearRetainingCapacity();

        try list.writer().print("{}", .{testCase.date});
        try testing.expectEqualStrings(testCase.expected, list.items);
    }
}
