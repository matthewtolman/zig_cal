const fixed = @import("./fixed.zig");
const t = @import("./time.zig");
const assert = @import("std").debug.assert;
const fmt = @import("std").fmt;
const mem = @import("std").mem;
const DayOfWeek = @import("./core.zig").DayOfWeek;
const meta = @import("std").meta;
const math = @import("../utils/math.zig");
const epochs = @import("./epochs.zig");

pub fn CalendarDayDiff(comptime Cal: type) type {
    return struct {
        /// Gets the difference between two dates in days
        pub fn dayDifference(self: Cal, right: Cal) i32 {
            return self.asFixed().dayDifference(right.asFixed());
        }
    };
}

pub fn CalendarDayMath(comptime Cal: type) type {
    return struct {
        /// Adds n days to the current date
        pub fn addDays(self: Cal, n: i32) Cal {
            return Cal.fromFixed(self.asFixed().addDays(n));
        }

        /// subtracts n days from the current date
        pub fn subDays(self: Cal, n: i32) Cal {
            return Cal.fromFixed(self.asFixed().subDays(n));
        }
    };
}

pub fn CalendarIsValid(comptime Cal: type) type {
    return struct {
        /// Checks if the current date is valid
        pub fn isValid(self: Cal) bool {
            self.validate() catch return false;
            return true;
        }
    };
}

pub fn CalendarNearestValid(comptime Cal: type) type {
    return struct {
        /// Gets the nearest valid date for the current "date"
        pub fn nearestValid(self: Cal) Cal {
            if (self.isValid()) {
                return self;
            }
            return Cal.fromFixed(self.asFixed());
        }
    };
}

pub fn CalendarDayOfWeek(comptime Cal: type) type {
    return struct {
        /// Gets the day of the week tied to the date
        pub fn dayOfWeek(self: Cal) DayOfWeek {
            return self.asFixed().dayOfWeek();
        }
    };
}

pub fn CalendarNthDays(comptime Cal: type) type {
    return struct {
        /// Returns the nth occurence of a day of week before the current
        /// date (or after if n is negative)
        /// If n is zero, it will return the current date instead
        pub fn nthWeekDay(self: Cal, n: i32, k: DayOfWeek) Cal {
            return Cal.fromFixed(self.asFixed().nthWeekDay(n, k));
        }

        /// Finds the first date before the current date that occurs on the target
        /// day of the week
        /// (from book, same as k_day_before)
        pub fn dayOfWeekBefore(self: Cal, k: DayOfWeek) Cal {
            return Cal.fromFixed(self.AsFixed().dayOfWeekBefore(k));
        }

        /// Finds the first date after the current date that occurs on the target
        /// day of the week
        /// (from book, same as k_day_after)
        pub fn dayOfWeekAfter(self: Cal, k: DayOfWeek) Cal {
            return Cal.fromFixed(self.AsFixed().dayOfWeekAfter(k));
        }

        /// Finds the first date nearest th current date that occurs on the target
        /// day of the week
        /// (from book, same as k_day_neareast)
        pub fn dayOfWeekNearest(self: Cal, k: DayOfWeek) Cal {
            return Cal.fromFixed(self.AsFixed().dayOfWeekNearest(k));
        }

        /// Finds the first date on or before the current date that occurs on the
        /// target day of the week
        /// (from book, same as k_day_on_or_before)
        pub fn dayOfWeekOnOrBefore(self: Cal, k: DayOfWeek) Cal {
            return Cal.fromFixed(self.AsFixed().dayOfWeekOnOrBefore(k));
        }

        /// Finds the first date on or after the current date that occurs on the
        /// target day of the week
        /// (from book, same as k_day_on_or_after)
        pub fn dayOfWeekOnOrAfter(self: Cal, k: DayOfWeek) Cal {
            return Cal.fromFixed(self.AsFixed().dayOfWeekOnOrAfter(k));
        }

        pub fn firstWeekDay(self: Cal, k: DayOfWeek) Cal {
            return Cal.fromFixed(self.AsFixed().firstWeekDay(k));
        }

        pub fn lastWeekDay(self: Cal, k: DayOfWeek) Cal {
            return Cal.fromFixed(self.AsFixed().lastWeekDay(k));
        }
    };
}

/// Mixin to provide generic versions of compare.
/// Requires asFixed and fromFixed to be present.
pub fn CalendarCompare(comptime Cal: type) type {
    return struct {
        /// Compares two dates. 1 if >, 0 if ==, -1 if less
        pub fn compare(self: Cal, right: Cal) i32 {
            return self.asFixed().compare(right.asFixed());
        }
    };
}

/// Creates a DateTime wrapper for any calendar struct which has the following:
///  - fn validate(self: Date) !void
///     - Runs validation checks to ensure date is valid
///     - generates `fn validate(self: CalendarDateTime(Date)) !void`
///  - compare(self: Date, other: Date) i32
///     - Compares two dates
///  - fromFixedDate(fixedDate: fixed.Date) Date
///     - Creates a new date from a fixed date
///  - toFixedDate(self: Date) fixed.Date
///     - Converts a date to a fixed date
///
/// If you wish to have a format function on the DateTime struct, just provide
/// one one the calendar struct.
pub fn CalendarDateTime(comptime Cal: type) type {
    const Time = t.Segments;
    comptime assert(@hasDecl(Cal, "toFixedDate"));

    const hasFormat = if (comptime @hasDecl(Cal, "format"))
        true
    else
        false;

    comptime assert(@hasDecl(Cal, "fromFixedDate"));

    comptime assert(@hasDecl(Cal, "compare"));

    comptime assert(@hasDecl(Cal, "validate"));

    return struct {
        date: Cal,
        time: Time,

        /// Initializes a date time. Will error if inputs are not valid
        pub fn init(date: Cal, time: Time) !CalendarDateTime(Cal) {
            try date.validate();
            try time.validate();
            return .{ .date = date, .time = time };
        }

        /// Validates a date time
        pub fn validate(self: CalendarDateTime(Cal)) !void {
            try self.date.validate();
            try self.time.validate();
        }

        /// Creates a date time from a fixed date time
        pub fn fromFixedDateTime(fdt: fixed.DateTime) CalendarDateTime(Cal) {
            return .{
                .date = Cal.fromFixedDate(fdt.date),
                .time = fdt.time,
            };
        }

        /// Converts a date time to a fixed date time
        pub fn toFixedDateTime(self: CalendarDateTime(Cal)) fixed.DateTime {
            return fixed.DateTime{
                .date = self.date.toFixedDate(),
                .time = self.time,
            };
        }

        /// Compares date times
        pub fn compare(
            self: CalendarDateTime(Cal),
            other: CalendarDateTime(Cal),
        ) i32 {
            const dateCompare = self.date.compare(other.date);
            if (dateCompare != 0) {
                return dateCompare;
            }
            return self.time.compare(other.time);
        }

        /// Formats date times
        pub fn format(
            self: Cal,
            comptime f: []const u8,
            options: fmt.FormatOptions,
            writer: anytype,
        ) !void {
            self.validate() catch {
                try writer.print("<INVALID_DATE_TIME>::", .{});
            };

            if (comptime hasFormat) {
                try self.date.format(f, options, writer);
            } else {
                try writer.print("<DATE>");
            }

            if (mem.eql(u8, f, "s") or mem.eql(u8, f, "u")) {
                try writer.print(" ", .{});
            } else {
                try writer.print("T", .{});
            }
            try self.time.format(f, options, writer);
        }
    };
}
