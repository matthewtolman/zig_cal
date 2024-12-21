const p = @import("../parsing.zig");
const Greg = @import("../calendars.zig").gregorian.DateTimeZoned;
const zone = @import("../calendars.zig").zone;
const testing = @import("std").testing;

pub const T = 0;

test "ISO 8601" {
    const fmt = "YYYY-MM-ddTHH:mm:ssX";
    const Test = struct { input: []const u8, out: Greg };
    const tests = [_]Test{
        Test{
            .input = "2024-12-20T22:38:58Z",
            .out = try Greg.init(
                try Greg.Date.initNums(2024, 12, 20),
                try Greg.Time.init(22, 38, 58, 0),
                zone.UTC,
            ),
        },
        Test{
            .input = "-2024-12-20T22:38:58+08:32",
            .out = try Greg.init(
                try Greg.Date.initNums(-2024, 12, 20),
                try Greg.Time.init(22, 38, 58, 0),
                try zone.TimeZone.init(.{ .hours = 8, .minutes = 32 }, null),
            ),
        },
        Test{
            .input = "2024-12-20T22:38:58-1032",
            .out = try Greg.init(
                try Greg.Date.initNums(2024, 12, 20),
                try Greg.Time.init(22, 38, 58, 0),
                try zone.TimeZone.init(.{ .hours = -10, .minutes = 32 }, null),
            ),
        },
    };

    for (tests) |t| {
        try testing.expectEqualDeep(t.out, p.parse(fmt, t.input));
    }
}

test "ISO 8601 Week Weekday" {
    const fmt = "YYYY-WR-e";
    const Test = struct { input: []const u8, out: Greg };
    const tests = [_]Test{
        Test{
            .input = "2024-W51-5",
            .out = try Greg.init(
                try Greg.Date.initNums(2024, 12, 20),
                try Greg.Time.init(0, 0, 0, 0),
                zone.UTC,
            ),
        },
        Test{
            .input = "2024-W51-7",
            .out = try Greg.init(
                try Greg.Date.initNums(2024, 12, 22),
                try Greg.Time.init(0, 0, 0, 0),
                zone.UTC,
            ),
        },
    };

    for (tests) |t| {
        try testing.expectEqualDeep(t.out, p.parse(fmt, t.input));
    }
}

test "ISO 8601 Week" {
    const fmt = "YYYY-WR";
    const Test = struct { input: []const u8, out: Greg };
    const tests = [_]Test{
        Test{
            .input = "2024-W51",
            .out = try Greg.init(
                try Greg.Date.initNums(2024, 12, 16),
                try Greg.Time.init(0, 0, 0, 0),
                zone.UTC,
            ),
        },
    };

    for (tests) |t| {
        try testing.expectEqualDeep(t.out, p.parse(fmt, t.input));
    }
}

test "HTTP Header" {
    const fmt = "eee, dd MMM yyyy HH:mm:ss O";
    const Test = struct { input: []const u8, out: Greg };
    const tests = [_]Test{
        Test{
            .input = "Tue, 29 Oct 2024 16:56:32 GMT",
            .out = try Greg.init(
                try Greg.Date.initNums(2024, 10, 29),
                try Greg.Time.init(16, 56, 32, 0),
                zone.GMT,
            ),
        },
        Test{
            .input = "Wed, 01 Jun 2022 08:00:00 GMT",
            .out = try Greg.init(
                try Greg.Date.initNums(2022, 6, 1),
                try Greg.Time.init(8, 0, 0, 0),
                zone.GMT,
            ),
        },
    };

    for (tests) |t| {
        try testing.expectEqualDeep(t.out, p.parse(fmt, t.input));
    }
}

test "asctime" {
    const fmt = "eee MMM dd HH:mm:ss YYYY";
    const Test = struct { input: []const u8, out: Greg };
    const tests = [_]Test{
        Test{
            .input = "Sun Dec 17 21:34:26 2023",
            .out = try Greg.init(
                try Greg.Date.initNums(2023, 12, 17),
                try Greg.Time.init(21, 34, 26, 0),
                zone.UTC,
            ),
        },
    };

    for (tests) |t| {
        try testing.expectEqualDeep(t.out, p.parse(fmt, t.input));
    }
}
