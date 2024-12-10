const toTypeMath = @import("../utils.zig").types.toTypeMath;
const m = @import("std").math;
const math = @import("../utils.zig").math;
const assert = @import("std").debug.assert;
const ValidationError = @import("core.zig").ValidationError;
const fmt = @import("std").fmt;
const testing = @import("std").testing;
const mem = @import("std").mem;

const nanoPerSec = @as(comptime_int, @intFromFloat(1e9));
//                 ns/s         s/m  m/h  h/d
const nanoPerDay: comptime_int = nanoPerSec * 60 * 60 * 24;

/// Represents time in Hour, Minut, Second, and Nanosecond fragments
/// Using u32 for nano since I only need to represent 1 billion nanoseconds,
/// and u32 can represent 4 billion nanoseconds
/// Also, at some point I just lose so much precision since we'll be converting
/// to and from Moment for some math, so it's really just a silly system.
/// But, it's also a system most devs are familiar with, and so long as they
/// don't hit one of the (*fun*) conversions that require Moment we'll be
/// good.
/// I'm going to try to replace and avoid Moment conversions wherever possible,
/// unlike in my C++ code where I just YOLO'd it and went with the book.
/// Ideally, nano is just fine.
///
/// And no, I'm not ever going below nano. Go too small and things get weird,
/// both at the hardware precision level and at the whole relativity/quantum
/// level.
pub const Segments = struct {
    /// 0-23
    hour: u8 = 0,
    /// 0-59
    minute: u8 = 0,
    /// 0-59 - we don't do leap seconds
    second: u8 = 0,
    /// 0-99,999,999
    nano: u32 = 0,

    /// Will attempt to initialize
    /// If invalid parameters are provided, will return validation errors
    pub fn init(hour: u8, minute: u8, second: u8, nano: u32) !Segments {
        const res = Segments{
            .hour = hour,
            .minute = minute,
            .second = second,
            .nano = nano,
        };
        try res.validate();
        return res;
    }

    /// Checks whether the current segment is valid
    pub fn validate(self: Segments) !void {
        if (self.hour >= 24) {
            return ValidationError.InvalidHour;
        }

        if (self.minute >= 60) {
            return ValidationError.InvalidMinute;
        }

        if (self.second >= 60) {
            return ValidationError.InvalidSecond;
        }

        if (self.nano >= nanoPerSec) {
            return ValidationError.InvalidNano;
        }
    }

    /// Converts time segments to nanoseconds
    pub fn toNanoSeconds(self: Segments) NanoSeconds {
        self.validate() catch unreachable;
        const hours = toTypeMath(u64, self.hour);
        const minutes = hours * 60 + toTypeMath(u64, self.minute);
        const seconds = minutes * 60 + toTypeMath(u64, self.second);
        const nano = seconds * nanoPerSec + toTypeMath(u64, self.nano);
        const res = NanoSeconds{ .nano = nano };

        res.validate() catch unreachable;
        return res;
    }

    /// Converts time segments to day fraction
    pub fn toDayFraction(self: Segments) DayFraction {
        const nano = self.toNanoSeconds();
        nano.validate() catch unreachable;
        const res = nano.toDayFraction();
        res.validate() catch unreachable;
        return res;
    }

    /// Converts to a raw float representing day fraction
    /// Allows overflowing and underflowing in the event the date is invalid
    /// Note: will need to verify in range [0, 1) before converting to DayFraction
    pub fn toDayFractionRaw(self: Segments) f64 {
        const hours = toTypeMath(u64, self.hour);
        const minutes = hours * 60 + toTypeMath(u64, self.minute);
        const seconds = minutes * 60 + toTypeMath(u64, self.second);
        const nano1 = seconds * nanoPerSec + toTypeMath(u64, self.nano);
        const nano = @as(f64, @floatFromInt(nano1));
        return nano / nanoPerDay;
    }

    /// Compares two segments
    pub fn compare(self: Segments, other: Segments) i32 {
        var res: i32 = 0;

        if (self.hour != other.hour) {
            res = if (self.hour < other.hour) -1 else 1;
        } else if (self.minute != other.minute) {
            res = if (self.minute < other.minute) -1 else 1;
        } else if (self.second != other.second) {
            res = if (self.second < other.second) -1 else 1;
        } else if (self.nano != other.nano) {
            res = if (self.nano < other.nano) -1 else 1;
        }

        assert(res == 1 or res == -1 or res == 0);
        return res;
    }

    pub fn format(
        self: @This(),
        comptime f: []const u8,
        options: fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = f;
        const precision = options.precision orelse 9;
        if (precision <= 1) {
            try writer.print("{d}:{d}:{d}.{d}", .{
                self.hour,
                self.minute,
                self.second,
                self.nano,
            });
        } else if (precision == 2) {
            try writer.print("{d:0>2}:{d:0>2}:{d:0>2}.{d:0>2}", .{
                self.hour,
                self.minute,
                self.second,
                self.nano,
            });
        } else {
            try writer.print("{d:0>2}:{d:0>2}:{d:0>2}.", .{
                self.hour,
                self.minute,
                self.second,
            });

            try fmt.formatIntValue(self.nano, "d", options, writer);
        }
    }
};

/// Fraction of a day as a float. Makes math easier, makes precision worse.
/// If you need to preserve all nanoseconds while doing a date conversion then
/// feel free to write something better.
///
/// Generally, I avoid using day fraction unless the math really needs it
/// When the math does need it, I try to avoid "Moment" even more
pub const DayFraction = struct {
    /// Fraction of the day (e.g. 0.5 = mid-day or 12pm)
    /// Note: this MUST be a finite number in the range [0..1)
    /// An invalid fraction is "undefined behavior" (i.e. crash in safe mode)
    frac: f64,

    /// Create a new DayFraction
    pub fn init(frac: f64) !DayFraction {
        const res = DayFraction{ .frac = frac };
        try res.validate();
        return res;
    }

    /// Checks if instance is valid
    /// Cannot run other methods if not valid
    pub fn validate(self: DayFraction) !void {
        if (!m.isFinite(self.frac)) {
            return ValidationError.InvalidFraction;
        }
        if (self.frac < 0) {
            return ValidationError.InvalidFraction;
        }
        if (self.frac >= 1) {
            return ValidationError.InvalidFraction;
        }
    }

    /// Converts day fraction to nano seconds
    pub fn toNanoSeconds(self: DayFraction) NanoSeconds {
        self.validate() catch unreachable;
        const nanoSeconds = toTypeMath(u64, m.floor(self.frac * nanoPerDay));
        const res = NanoSeconds{ .nano = nanoSeconds };

        res.validate() catch unreachable;
        return res;
    }

    /// Converts day fraction to segments
    pub fn toSegments(self: DayFraction) Segments {
        const nano = self.toNanoSeconds();
        nano.validate() catch unreachable;
        const res = nano.toSegments();
        res.validate() catch unreachable;
        return res;
    }

    /// Compares two day fractions and returns -1, 0, or 1
    pub fn compare(self: DayFraction, other: DayFraction) i32 {
        var res = 0;
        if (self.frac != other.frac) {
            res = if (self.frac < other.frac) -1 else 1;
        }

        assert(res == 0 or res == -1 or res == 1);
        return res;
    }

    pub fn format(
        self: @This(),
        comptime f: []const u8,
        options: fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = f;
        _ = options;

        try writer.print("{d:.3}%day", .{self.frac * 100.0});
    }
};

/// Time of day in nanoseconds. This struct goes brrrrrr.
pub const NanoSeconds = struct {
    pub const max = nanoPerDay;
    /// The number of nanoseconds
    /// Must be in the range [0..nanoPerDay)
    nano: u64,

    /// Create a new DayFraction
    pub fn init(nano: u64) !NanoSeconds {
        const res = NanoSeconds{ .nano = nano };
        try res.validate();
        return res;
    }

    /// Checks if instance is valid
    /// Cannot run other methods if not valid
    pub fn validate(self: NanoSeconds) !void {
        if (self.nano >= nanoPerDay) {
            return ValidationError.InvalidNano;
        }
    }

    /// Converts nano seconds to day fraction
    pub fn toDayFraction(self: NanoSeconds) DayFraction {
        self.validate() catch unreachable;
        // yay precision loss!
        const nano = @as(f64, @floatFromInt(self.nano));
        const res = DayFraction{ .frac = nano / nanoPerDay };
        res.validate() catch unreachable;
        return res;
    }

    /// Converts nano seconds to segments
    pub fn toSegments(self: NanoSeconds) Segments {
        self.validate() catch unreachable;

        var val: u64 = self.nano;

        const nano = math.mod(u32, val, nanoPerSec);
        assert(nano < nanoPerSec);
        val = val / nanoPerSec;

        const seconds = math.mod(u8, val, 60);
        assert(seconds < 60);
        val = val / 60;

        const minutes = math.mod(u8, val, 60);
        assert(minutes < 60);
        val = val / 60;

        assert(val < 24);
        const res = Segments{
            .hour = toTypeMath(u8, val),
            .minute = minutes,
            .second = seconds,
            .nano = nano,
        };

        res.validate() catch unreachable;
        return res;
    }

    /// Compares two day fractions and returns -1, 0, or 1
    pub fn compare(self: NanoSeconds, other: NanoSeconds) i32 {
        var res = 0;
        if (self.nano != other.nano) {
            res = if (self.nano < other.nano) -1 else 1;
        }

        assert(res == 0 or res == -1 or res == 1);
        return res;
    }

    /// Formats nanoseconds
    pub fn format(
        self: @This(),
        comptime f: []const u8,
        options: fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = f;
        try fmt.formatIntValue(self.nano, "d", options, writer);
        try writer.print("ns", .{});
    }
};

test "time conversions" {
    // From Segments
    try testing.expectEqualDeep(try DayFraction.init(
        0.5,
    ), (try Segments.init(
        12,
        0,
        0,
        0,
    )).toDayFraction());

    try testing.expectEqual(try NanoSeconds.init(
        nanoPerDay / 2,
    ), (try Segments.init(
        12,
        0,
        0,
        0,
    )).toNanoSeconds());

    // From DayFraction
    try testing.expectEqualDeep(try Segments.init(
        12,
        0,
        0,
        0,
    ), (try DayFraction.init(0.5)).toSegments());

    try testing.expectEqualDeep(try NanoSeconds.init(
        nanoPerDay / 2,
    ), (try DayFraction.init(0.5)).toNanoSeconds());

    // From NanoSeconds
    try testing.expectEqualDeep(try Segments.init(
        12,
        0,
        0,
        0,
    ), (try NanoSeconds.init(nanoPerDay / 2)).toSegments());

    try testing.expectEqualDeep(try DayFraction.init(
        0.5,
    ), (try NanoSeconds.init(nanoPerDay / 2)).toDayFraction());
}

test "time formatting" {
    var list = @import("std").ArrayList(u8).init(testing.allocator);
    defer list.deinit();
    const testCases = [_]struct {
        time: union(enum) {
            segments: Segments,
            nano: NanoSeconds,
            frac: DayFraction,
        },
        expected: []const u8,
    }{
        .{
            .time = .{ .segments = try Segments.init(12, 32, 45, 1239238) },
            .expected = "12:32:45.1239238",
        },
        .{
            .time = .{ .nano = try NanoSeconds.init(1234599) },
            .expected = "1234599ns",
        },
        .{
            .time = .{ .frac = try DayFraction.init(0.4231) },
            .expected = "42.310%day",
        },
    };

    for (testCases) |testCase| {
        {
            defer list.clearRetainingCapacity();

            switch (testCase.time) {
                .segments => |t| try list.writer().print("{s}", .{t}),
                .frac => |t| try list.writer().print("{s}", .{t}),
                .nano => |t| try list.writer().print("{s}", .{t}),
            }

            try testing.expectEqualStrings(testCase.expected, list.items);
        }
    }
}
