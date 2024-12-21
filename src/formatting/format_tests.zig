const p = @import("../formatting.zig");
const Greg = @import("../calendars.zig").gregorian.DateTimeZoned;
const zone = @import("../calendars.zig").zone;
const std = @import("std");
const testing = std.testing;

pub const T = 0;

test "ISO 8601" {
    const fmt = "YYYY-MM-ddTHH:mm:ssXXX";
    const Test = struct { output: []const u8, date: Greg };
    const tests = [_]Test{
        Test{
            .output = "2024-12-20T22:38:58Z",
            .date = try Greg.init(
                try Greg.Date.initNums(2024, 12, 20),
                try Greg.Time.init(22, 38, 58, 0),
                zone.UTC,
            ),
        },
        Test{
            .output = "-2024-12-20T22:38:58+08:32",
            .date = try Greg.init(
                try Greg.Date.initNums(-2024, 12, 20),
                try Greg.Time.init(22, 38, 58, 0),
                try zone.TimeZone.init(.{ .hours = 8, .minutes = 32 }, null),
            ),
        },
        Test{
            .output = "2024-12-20T22:38:58-10:32",
            .date = try Greg.init(
                try Greg.Date.initNums(2024, 12, 20),
                try Greg.Time.init(22, 38, 58, 0),
                try zone.TimeZone.init(.{ .hours = -10, .minutes = 32 }, null),
            ),
        },
    };

    for (tests) |t| {
        var buff: [255]u8 = undefined;
        var b = std.io.fixedBufferStream(&buff);
        try p.format(fmt, t.date, b.writer());
        try testing.expectEqualDeep(t.output, b.getWritten());
    }
}

test "ISO 8601 Week Weekday" {
    const fmt = "YYYY-WR-e";
    const Test = struct { output: []const u8, date: Greg };
    const tests = [_]Test{
        Test{
            .output = "2024-W51-5",
            .date = try Greg.init(
                try Greg.Date.initNums(2024, 12, 20),
                try Greg.Time.init(0, 0, 0, 0),
                zone.UTC,
            ),
        },
    };

    for (tests) |t| {
        var buff: [255]u8 = undefined;
        var b = std.io.fixedBufferStream(&buff);
        try p.format(fmt, t.date, b.writer());
        try testing.expectEqualDeep(t.output, b.getWritten());
    }
}

test "ISO 8601 Week" {
    const fmt = "YYYY-WR";
    const Test = struct { output: []const u8, date: Greg };
    const tests = [_]Test{
        Test{
            .output = "2024-W51",
            .date = try Greg.init(
                try Greg.Date.initNums(2024, 12, 16),
                try Greg.Time.init(0, 0, 0, 0),
                zone.UTC,
            ),
        },
    };

    for (tests) |t| {
        var buff: [255]u8 = undefined;
        var b = std.io.fixedBufferStream(&buff);
        try p.format(fmt, t.date, b.writer());
        try testing.expectEqualDeep(t.output, b.getWritten());
    }
}

test "HTTP Header" {
    const fmt = "eee, dd MMM yyyy HH:mm:ss O";
    const Test = struct { output: []const u8, date: Greg };
    const tests = [_]Test{
        Test{
            .output = "Tue, 29 Oct 2024 16:56:32 GMT",
            .date = try Greg.init(
                try Greg.Date.initNums(2024, 10, 29),
                try Greg.Time.init(16, 56, 32, 0),
                zone.GMT,
            ),
        },
        Test{
            .output = "Wed, 01 Jun 2022 08:00:00 GMT",
            .date = try Greg.init(
                try Greg.Date.initNums(2022, 6, 1),
                try Greg.Time.init(8, 0, 0, 0),
                zone.GMT,
            ),
        },
    };

    for (tests) |t| {
        var buff: [255]u8 = undefined;
        var b = std.io.fixedBufferStream(&buff);
        try p.format(fmt, t.date, b.writer());
        try testing.expectEqualDeep(t.output, b.getWritten());
    }
}

test "asctime" {
    const fmt = "eee MMM dd HH:mm:ss YYYY";
    const Test = struct { output: []const u8, date: Greg };
    const tests = [_]Test{
        Test{
            .output = "Sun Dec 17 21:34:26 2023",
            .date = try Greg.init(
                try Greg.Date.initNums(2023, 12, 17),
                try Greg.Time.init(21, 34, 26, 0),
                zone.UTC,
            ),
        },
    };

    for (tests) |t| {
        var buff: [255]u8 = undefined;
        var b = std.io.fixedBufferStream(&buff);
        try p.format(fmt, t.date, b.writer());
        try testing.expectEqualDeep(t.output, b.getWritten());
    }
}
