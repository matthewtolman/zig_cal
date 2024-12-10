const fmt = @import("std").fmt;
const mem = @import("std").mem;

/// Errors related to timezone validation
pub const TimeZoneValidationError = error{
    InvalidTimeZoneSecond,
    InvalidTimeZoneMinute,
    InvalidTimeZoneHour,
};

const nanoPerSec = @as(u64, @intFromFloat(1e9));

/// Represents a timezone
/// May be named
pub const TimeZone = struct {
    /// Struct with discrete pieces for timezone offsets
    pub const OffsetHMS = struct {
        /// Seconds portion of the offset
        seconds: u8 = 0,
        /// Minutes portion of the offset
        minutes: u8 = 0,
        /// Hours portion of the offset
        hours: i8 = 0,
    };

    _offset: OffsetHMS,
    _name: ?[]const u8 = null,

    /// Gets timezone offset in nano seconds
    pub fn offsetInNanoSeconds(self: @This()) i64 {
        const secs = self.offsetInSeconds();
        const nano = @as(i64, @intCast(secs)) * nanoPerSec;
        return nano;
    }

    /// Gets timezone offset in seconds
    pub fn offsetInSeconds(self: @This()) i32 {
        const sign: i32 = if (self._offset.hours >= 0) 1 else -1;
        var total: i32 = @intCast(@abs(self._offset.hours));
        total *= 60;
        total += @intCast(self._offset.minutes);
        total *= 60;
        total += @intCast(self._offset.seconds);
        total *= sign;
        return total;
    }

    /// Gets timezone offset in minutes (and fractions of a minute)
    pub fn offsetInMinutes(self: @This()) f64 {
        return @as(f64, @floatFromInt(self.offsetInSeconds())) / 60;
    }

    /// Gets timezone offset in hours (and fractions of an hour)
    pub fn offsetInHours(self: @This()) f64 {
        return self.offsetInMinutes() / 60;
    }

    /// Gets timezone offset in a struct of individual pieces
    pub fn offset(self: @This()) OffsetHMS {
        return self._offset;
    }

    /// Creates a new timezone
    /// Can optionaly provide a timezone name
    /// Will fail if the timezone offset is invalid
    /// (e.g. hour >= 24, minute >= 60, second >= 60)
    pub fn init(o: OffsetHMS, name: ?[]const u8) !@This() {
        const res = @This(){ ._offset = o, ._name = name };
        try res.validate();
        return res;
    }

    /// Validates a timezone (automatically called by init)
    pub fn validate(self: @This()) !void {
        if (self._offset.seconds < 0 or self._offset.seconds >= 60) {
            return TimeZoneValidationError.InvalidTimeZoneSecond;
        }
        if (self._offset.minutes < 0 or self._offset.minutes >= 60) {
            return TimeZoneValidationError.InvalidTimeZoneMinute;
        }
        if (self._offset.hours < -12 or self._offset.hours > 12) {
            return TimeZoneValidationError.InvalidTimeZoneHour;
        }
    }

    /// Compares the offsets of two timezones
    /// This will ignore the timezone name
    /// Essentially, this tells you if timezones are "equivalent"
    ///     even though the name may differ
    pub fn compareOffset(self: @This(), other: @This()) i32 {
        if (self._offset.hours == other._offset.hours) {
            if (self._offset.minutes == other._offset.minutes) {
                if (self._offset.seconds == other._offset.seconds) {
                    return 0;
                } else {
                    if (self._offset.seconds < other._offset.seconds) return -1;
                    return 1;
                }
            } else {
                if (self._offset.minutes < other._offset.minutes) return -1;
                return 1;
            }
        } else {
            if (self._offset.hours < other._offset.hours) return -1;
            return 1;
        }
    }

    /// Compares all timezone fields (offset and name)
    pub fn compare(self: @This(), other: @This()) i32 {
        const offset_compare = self.compareOffset(other);
        if (offset_compare != 0) return offset_compare;

        if (self._name == null and other._name == null) {
            return 0;
        } else if (self._name == null) {
            return -1;
        } else if (other._name == null) {
            return 1;
        } else {
            if (mem.eql(u8, self._name.?, other._name.?)) {
                return 0;
            } else if (mem.lessThan(u8, self._name.?, other._name.?)) {
                return -1;
            } else {
                return 1;
            }
        }
    }

    /// Formats timezone - used for debug printing
    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try self.validate();

        if (self._name) |name| {
            try writer.writeAll(name);
            try writer.writeByte(' ');
        }

        var ch: u8 = undefined;
        if (self._offset.hours >= 0) {
            ch = '+';
        } else {
            ch = '-';
        }

        try writer.print("{c}{d:0>2}:{d:0>2}:{d:0>2}", .{
            ch,
            @as(u64, @abs(self._offset.hours)),
            self._offset.minutes,
            self._offset.seconds,
        });
    }
};

pub const UTC = TimeZone.init(.{ .seconds = 0, .hours = 0, .minutes = 0 }, "UTC") catch unreachable;
pub const GMT = TimeZone.init(.{ .seconds = 0, .hours = 0, .minutes = 0 }, "GMT") catch unreachable;
