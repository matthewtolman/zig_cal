const time = @import("./time.zig");
const m = @import("std").math;
const assert = @import("std").debug.assert;
const types = @import("../utils.zig").types;
const core = @import("./core.zig");
const epochs = @import("./epochs.zig");
const math = @import("../utils.zig").math;

// A 32-bit int gives us 11 million years.
// A 64-bit integer can represent way more than 11 million years.
//
// However, past a few hundred thousand years the whole "calendar" concept
// should really be done away with. For one the precision of "Earth days"
// doesn't make any sense when talking about dinosaurs or the Big Bang. Even
// individual years doesn't make much sense at that level. For one, we don't
// even have precise day (or often year) data at that time scale, so there's not
// much point in saying "this dinosaur bone died on this day". Even if we did,
// there's not much point in pinning it to a single day. What benefit do we get
// if the Big Bang happened in what would have been our February or March had
// our earth existed over 14 billion years ago? Why does that even matter?
//
// Because of the ridiculousness of trying to apply calendars past a certain
// threshold, I'm not even going to try to support it. All of our calendars fall
// apart at a large enough timescale. It doesn't matter because our lives are
// not even close to that time scale. Most civilizations collapse either well
// before their calendar system collapses (if it's a really, really good
// calendar), they replace it with a new system once it collapses, or they
// collapse around the same time the calendar system collapses. For really bad
// calendar systems they still are fairly accurate for hundreds of years, and
// even then their "inaccuracy" is with seasonal drift. Hundreds of years is
// long enough for an individual to worry about. This library will support
// millions of years. I can definitely sleep at night with a measly 32-bit
// number.
//
// If you really want a 64-bit int for the FixedDate, see my C++ versions
//      C and C++ APIs: https://gitlab.com/mtolman/calendars
//      C++ constexpr: https://gitlab.com/mtolman/calendar-constexpr
pub const Date = struct {
    day: i32,

    /// Compares two dates to see which is larger
    pub fn compare(self: Date, right: Date) i32 {
        if (self.day != right.day) {
            if (self.day > right.day) {
                return 1;
            }
            return -1;
        }
        return 0;
    }

    /// Returns the current day of the week for a calendar
    pub fn dayOfWeek(self: Date) core.DayOfWeek {
        const d = self.day - epochs.fixed - @intFromEnum(core.DayOfWeek.Sunday);
        const dow = math.mod(u8, d, 7);
        assert(dow >= 0);
        assert(dow < 7);
        return @enumFromInt(dow);
    }

    /// Adds n days to the date
    pub fn addDays(self: Date, days: i32) Date {
        return Date{ .day = self.day + days };
    }

    /// Subtract n days from the date
    pub fn subDays(self: Date, days: i32) Date {
        return Date{ .day = self.day - days };
    }

    /// Gets the difference between two dates
    pub fn dayDifference(self: Date, right: Date) i32 {
        return self.day - right.day;
    }

    /// Returns the nth occurence of a day of week before the current
    /// date (or after if n is negative)
    /// If n is zero, it will return the current date instead
    pub fn nthWeekDay(self: Date, n: i32, k: core.DayOfWeek) Date {
        if (n > 0) {
            return self.dayOfWeekBefore(k).addDays(7 * n);
        } else if (n < 0) {
            // using add days since n is negative
            return self.dayOfWeekAfter(k).addDays(7 * n);
        } else {
            return self;
        }
    }

    /// Finds the first date before the current date that occurs on the target
    /// day of the week
    /// (from book, same as k_day_before)
    pub fn dayOfWeekBefore(self: Date, k: core.DayOfWeek) Date {
        return self.subDays(1).dayOfWeekOnOrBefore(k);
    }

    /// Finds the first date after the current date that occurs on the target
    /// day of the week
    /// (from book, same as k_day_after)
    pub fn dayOfWeekAfter(self: Date, k: core.DayOfWeek) Date {
        return self.addDays(7).dayOfWeekOnOrBefore(k);
    }

    /// Finds the first date nearest th current date that occurs on the target
    /// day of the week
    /// (from book, same as k_day_neareast)
    pub fn dayOfWeekNearest(self: Date, k: core.DayOfWeek) Date {
        return self.addDays(3).dayOfWeekOnOrBefore(k);
    }

    /// Finds the first date on or before the current date that occurs on the
    /// target day of the week
    /// (from book, same as k_day_on_or_before)
    pub fn dayOfWeekOnOrBefore(self: Date, k: core.DayOfWeek) Date {
        const dayOfWeekPrev = (Date{
            .day = self.day - @intFromEnum(k),
        }).dayOfWeek();
        return Date{ .day = self.day - @intFromEnum(dayOfWeekPrev) };
    }

    /// Finds the first date on or after the current date that occurs on the
    /// target day of the week
    /// (from book, same as k_day_on_or_after)
    pub fn dayOfWeekOnOrAfter(self: Date, k: core.DayOfWeek) Date {
        return self.addDays(6).dayOfWeekOnOrBefore(k);
    }

    pub fn firstWeekDay(self: Date, k: core.DayOfWeek) Date {
        return self.nthWeekDay(1, k);
    }

    pub fn lastWeekDay(self: Date, k: core.DayOfWeek) Date {
        return self.nthWeekDay(-1, k);
    }
};

/// Represents a fixed date plus time
/// Prefer this over Moment whenever possible
pub const DateTime = struct {
    date: Date,
    time: time.Segments,

    /// Checks if we're valid
    pub fn validate(self: DateTime) !void {
        try self.time.validate();
    }

    /// Converts to a moment - avoid if possible
    pub fn toMoment(self: DateTime) Moment {
        assert(self.valid());
        const days = types.toTypeMath(f64, self.date.day);
        const t = self.time.toDayFraction();
        const res = Moment{ .dayAndTime = days + t.frac };
        assert(res.valid());
        return res;
    }

    /// Compares two dates to see which is larger
    pub fn compare(self: DateTime, right: DateTime) i32 {
        const dateCmp = self.date.compare(right.date);
        if (dateCmp != 0) {
            return dateCmp;
        }
        return self.time.compare(right.time);
    }

    /// Returns the current day of the week for a calendar
    pub fn dayOfWeek(self: DateTime) core.DayOfWeek {
        return self.date.dayOfWeek();
    }

    /// Adds n days to the date
    pub fn addDays(self: DateTime, days: i32) DateTime {
        return DateTime{
            .date = self.date.addDays(days),
            .time = self.time,
        };
    }

    /// Subtract n days from the date
    pub fn subDays(self: DateTime, days: i32) DateTime {
        return DateTime{
            .date = self.date.subDays(days),
            .time = self.time,
        };
    }

    /// Gets the difference between two dates
    pub fn dayDifference(self: DateTime, right: DateTime) i32 {
        return self.dayDifference(right);
    }

    /// Returns the nth occurence of a day of week before the current
    /// date (or after if n is negative)
    /// If n is zero, it will return the current date instead
    pub fn nthWeekDay(self: DateTime, n: i32, k: core.DayOfWeek) DateTime {
        return DateTime{
            .date = self.date.nthWeekDay(n, k),
            .time = self.time,
        };
    }

    /// Finds the first date before the current date that occurs on the target
    /// day of the week
    /// (from book, same as k_day_before)
    pub fn dayOfWeekBefore(self: DateTime, k: core.DayOfWeek) DateTime {
        return DateTime{
            .date = self.date.dayOfWeekBefore(k),
            .time = self.time,
        };
    }

    /// Finds the first date after the current date that occurs on the target
    /// day of the week
    /// (from book, same as k_day_after)
    pub fn dayOfWeekAfter(self: DateTime, k: core.DayOfWeek) DateTime {
        return DateTime{
            .date = self.date.dayOfWeekAfter(k),
            .time = self.time,
        };
    }

    /// Finds the first date nearest th current date that occurs on the target
    /// day of the week
    /// (from book, same as k_day_neareast)
    pub fn dayOfWeekNearest(self: DateTime, k: core.DayOfWeek) DateTime {
        return DateTime{
            .date = self.date.dayOfWeekNearest(k),
            .time = self.time,
        };
    }

    /// Finds the first date on or before the current date that occurs on the
    /// target day of the week
    /// (from book, same as k_day_on_or_before)
    pub fn dayOfWeekOnOrBefore(self: DateTime, k: core.DayOfWeek) DateTime {
        return DateTime{
            .date = self.date.dayOfWeekOnOrBefore(k),
            .time = self.time,
        };
    }

    /// Finds the first date on or after the current date that occurs on the
    /// target day of the week
    /// (from book, same as k_day_on_or_after)
    pub fn dayOfWeekOnOrAfter(self: DateTime, k: core.DayOfWeek) DateTime {
        return DateTime{
            .date = self.date.dayOfWeekOnOrAfter(k),
            .time = self.time,
        };
    }

    pub fn firstWeekDay(self: DateTime, k: core.DayOfWeek) DateTime {
        return DateTime{
            .date = self.date.firstWeekDay(k),
            .time = self.time,
        };
    }

    pub fn lastWeekDay(self: DateTime, k: core.DayOfWeek) DateTime {
        return DateTime{
            .date = self.date.lastWeekDay(k),
            .time = self.time,
        };
    }
};

/// An extremely inprecise way of representing date and time
/// For 90% of use cases it works just fine because anything smaller than
/// seconds is generally not needed
/// But as time progresses, this just gets worse and worse.
/// That said, it does get worse slowly enough for us to build another Y2K.
/// And probably let a few generations retire before the Y2K happens.
///
/// I still don't like it. Used fixed.DateTime whenever possible instead.
pub const Moment = struct {
    dayAndTime: f64,

    /// Checks if we're valid
    pub fn valid(self: Moment) bool {
        return m.isFinite(self);
    }

    /// Converts to a fixed DateTime
    pub fn toFixedDateTime(self: Moment) DateTime {
        assert(self.valid());

        const days = m.floor(self.dayAndTime);
        const t = self.dayAndTime - days;

        const daysInt = types.toTypeMath(i32, days);

        return DateTime{
            .date = Date{ .days = daysInt },
            .time = (time.DayFraction{ .frac = t }).toSegments(),
        };
    }
};

test "nth weekday" {
    const std = @import("std");
    const date = Date{ .day = 38 };
    try std.testing.expectEqual(38, date.nthWeekDay(0, .Wednesday).day);
    try std.testing.expectEqual(39, date.nthWeekDay(1, .Thursday).day);
    try std.testing.expectEqual(37, date.nthWeekDay(-1, .Tuesday).day);
}

test "day of week" {
    const std = @import("std");
    const sample_dates = @import("./test_helpers.zig").sample_dates;

    const expected = [_]core.DayOfWeek{
        .Sunday,
        .Wednesday,
        .Wednesday,
        .Sunday,
        .Wednesday,
        .Monday,
        .Saturday,
        .Sunday,
        .Sunday,
        .Friday,
        .Saturday,
        .Friday,
        .Sunday,
        .Sunday,
        .Wednesday,
        .Saturday,
        .Saturday,
        .Saturday,
        .Wednesday,
        .Sunday,
        .Friday,
        .Sunday,
        .Monday,
        .Wednesday,
        .Sunday,
        .Sunday,
        .Monday,
        .Monday,
        .Thursday,
        .Tuesday,
        .Sunday,
        .Wednesday,
        .Sunday,
    };

    for (sample_dates, expected) |input, e| {
        try std.testing.expectEqual(e, input.dayOfWeek());
    }
}

test "Day of week on or before" {
    const std = @import("std");
    try std.testing.expectEqual((Date{ .day = 0 }).dayOfWeekOnOrBefore(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 1 }).dayOfWeekOnOrBefore(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 2 }).dayOfWeekOnOrBefore(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 3 }).dayOfWeekOnOrBefore(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 4 }).dayOfWeekOnOrBefore(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 5 }).dayOfWeekOnOrBefore(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 6 }).dayOfWeekOnOrBefore(.Sunday), Date{ .day = 0 });
}

test "Day of week before" {
    const std = @import("std");
    try std.testing.expectEqual((Date{ .day = 0 }).dayOfWeekBefore(.Sunday), Date{ .day = -7 });
    try std.testing.expectEqual((Date{ .day = 1 }).dayOfWeekBefore(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 2 }).dayOfWeekBefore(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 3 }).dayOfWeekBefore(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 4 }).dayOfWeekBefore(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 5 }).dayOfWeekBefore(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 6 }).dayOfWeekBefore(.Sunday), Date{ .day = 0 });
}

test "Day of week on or after" {
    const std = @import("std");
    try std.testing.expectEqual((Date{ .day = 0 }).dayOfWeekOnOrAfter(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 1 }).dayOfWeekOnOrAfter(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 2 }).dayOfWeekOnOrAfter(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 3 }).dayOfWeekOnOrAfter(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 4 }).dayOfWeekOnOrAfter(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 5 }).dayOfWeekOnOrAfter(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 6 }).dayOfWeekOnOrAfter(.Sunday), Date{ .day = 7 });
}

test "Day of week after" {
    const std = @import("std");
    try std.testing.expectEqual((Date{ .day = 0 }).dayOfWeekAfter(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 1 }).dayOfWeekAfter(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 2 }).dayOfWeekAfter(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 3 }).dayOfWeekAfter(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 4 }).dayOfWeekAfter(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 5 }).dayOfWeekAfter(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 6 }).dayOfWeekAfter(.Sunday), Date{ .day = 7 });
}

test "Day of week nearest" {
    const std = @import("std");
    try std.testing.expectEqual((Date{ .day = 0 }).dayOfWeekNearest(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 1 }).dayOfWeekNearest(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 2 }).dayOfWeekNearest(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 3 }).dayOfWeekNearest(.Sunday), Date{ .day = 0 });
    try std.testing.expectEqual((Date{ .day = 4 }).dayOfWeekNearest(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 5 }).dayOfWeekNearest(.Sunday), Date{ .day = 7 });
    try std.testing.expectEqual((Date{ .day = 6 }).dayOfWeekNearest(.Sunday), Date{ .day = 7 });
}
