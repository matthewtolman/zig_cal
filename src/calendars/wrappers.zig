const fixed = @import("fixed.zig");
const t = @import("time.zig");
const std = @import("std");
const assert = std.debug.assert;
const fmt = std.fmt;
const mem = std.mem;
const DayOfWeek = @import("core.zig").DayOfWeek;
const meta = @import("std").meta;
const math = @import("../utils/math.zig");
const epochs = @import("epochs.zig");
const zone = @import("zone.zig");
const TimeZone = zone.TimeZone;

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
///  Optional:
///  - addDays(self: Date, n: i32) Date
///     - Will default to converting to a fixed date, adding days, and converting back
///  - subDays(self: Date, n: i32) Date
///     - Will default to converting to a fixed date, subtracting days, and converting back
///  - dayOfWeek(self: Date) DayOfWeek
///  - nthWeekDay(self: Date, n: i32, k: DayOfWeek)
///  - dayOfWeekBefore(self: Date, k: DayOfWeek)
///  - dayOfWeekAfter(self: Date, k: DayOfWeek)
///  - dayOfWeekNearest(self: Date, k: DayOfWeek)
///  - dayOfWeekOnOrBefore(self: Date, k: DayOfWeek)
///  - dayOfWeekOnOrAfter(self: Date, k: DayOfWeek)
///  - firstWeekDay(self: Date, k: DayOfWeek)
///  - lastWeekDay(self: Date, k: DayOfWeek)
///  - format(self: Date, comptime f: []const u8, options: std.fmt.FormatOptions, writer: anytype) !usize
///
/// If you wish to have a format function on the DateTime struct, just provide
/// one one the calendar struct.
pub fn CalendarDateTime(comptime Cal: type) type {
    const T = t.Segments;
    comptime assert(@hasDecl(Cal, "toFixedDate"));

    const hasFormat = if (comptime @hasDecl(Cal, "format"))
        true
    else
        false;

    comptime assert(@hasDecl(Cal, "fromFixedDate"));

    comptime assert(@hasDecl(Cal, "compare"));

    comptime assert(@hasDecl(Cal, "validate"));

    return struct {
        pub const Date = Cal;
        pub const Time = T;

        date: Cal,
        time: Time,

        /// Initializes a date time. Will error if inputs are not valid
        pub fn init(date: Cal, time: Time) !@This() {
            try date.validate();
            try time.validate();
            return .{ .date = date, .time = time };
        }

        /// Returns a copy n days into the future
        pub fn addDays(self: @This(), n: i32) @This() {
            if (comptime std.meta.hasFn(Cal, "addDays")) {
                return .{ .date = self.date.addDays(n), .time = self.time };
            } else {
                return @This().fromFixedDateTime(self.toFixedDateTime().addDays(n));
            }
        }

        /// Returns a copy n days into the past
        pub fn subDays(self: @This(), n: i32) @This() {
            if (comptime std.meta.hasFn(Cal, "subDays")) {
                return .{ .date = self.date.subDays(n), .time = self.time };
            } else {
                return @This().fromFixedDateTime(self.toFixedDateTime().subDays(n));
            }
        }

        /// Returns whether the date/time is valid
        pub fn isValid(self: @This()) bool {
            self.validate() catch return false;
            return true;
        }

        /// Coerces to nearest valid date time
        pub fn nearestValid(self: @This()) @This() {
            if (self.isValid()) {
                return self;
            }
            return @This().fromFixedDateTime(self.toFixedDateTime());
        }

        /// Returns difference in days
        pub fn dayDifference(self: @This(), right: @This()) i32 {
            if (comptime std.meta.hasFn(Cal, "dayDifference")) {
                return self.date.dayDifference(right.date);
            } else {
                return self.toFixedDateTime().dayDifference(right.toFixedDateTime());
            }
        }

        /// Returns the day of the week
        pub fn dayOfWeek(self: @This()) DayOfWeek {
            if (comptime std.meta.hasFn(Cal, "dayOfWeek")) {
                return self.date.dayOfWeek();
            } else {
                return self.toFixedDateTime().dayOfWeek();
            }
        }

        /// Returns the nth occurence of a day of week before the current
        /// date (or after if n is negative)
        /// If n is zero, it will return the current date instead
        pub fn nthWeekDay(self: @This(), n: i32, k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "nthWeekDay")) {
                return .{
                    .date = self.date.nthWeekDay(n, k),
                    .time = self.time,
                };
            } else {
                return self.toFixedDateTime().nthWeekDay(n, k);
            }
        }

        /// Finds the first date before the current date that occurs on the target
        /// day of the week
        /// (from book, same as k_day_before)
        pub fn dayOfWeekBefore(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "dayOfWeekBefore")) {
                return .{
                    .date = self.date.dayOfWeekBefore(k),
                    .time = self.time,
                };
            } else {
                return self.toFixedDateTime().dayOfWeekBefore(k);
            }
        }

        /// Finds the first date after the current date that occurs on the target
        /// day of the week
        /// (from book, same as k_day_after)
        pub fn dayOfWeekAfer(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "dayOfWeekAfer")) {
                return .{
                    .date = self.date.dayOfWeekAfter(k),
                    .time = self.time,
                };
            } else {
                return self.toFixedDateTime().dayOfWeekAfter(k);
            }
        }

        /// Finds the first date nearest th current date that occurs on the target
        /// day of the week
        /// (from book, same as k_day_neareast)
        pub fn dayOfWeekNearest(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "dayOfWeekNearest")) {
                return .{
                    .date = self.date.dayOfWeekNearest(k),
                    .time = self.time,
                };
            } else {
                return self.toFixedDateTime().dayOfWeekNearest(k);
            }
        }

        /// Finds the first date on or before the current date that occurs on the
        /// target day of the week
        /// (from book, same as k_day_on_or_before)
        pub fn dayOfWeekOnOrBefore(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "dayOfWeekOnOrBefore")) {
                return .{
                    .date = self.date.dayOfWeekOnOrBefore(k),
                    .time = self.time,
                };
            } else {
                return self.toFixedDateTime().dayOfWeekOnOrBefore(k);
            }
        }

        /// Finds the first date on or after the current date that occurs on the
        /// target day of the week
        /// (from book, same as k_day_on_or_after)
        pub fn dayOfWeekOnOrAfter(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "dayOfWeekOnOrAfter")) {
                return .{
                    .date = self.date.dayOfWeekOnOrAfter(k),
                    .time = self.time,
                };
            } else {
                return self.toFixedDateTime().dayOfWeekOnOrAfter(k);
            }
        }

        pub fn firstWeekDay(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "firstWeekDay")) {
                return .{
                    .date = self.date.firstWeekDay(k),
                    .time = self.time,
                };
            } else {
                return self.toFixedDateTime().firstWeekDay(k);
            }
        }

        pub fn lastWeekDay(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "lastWeekDay")) {
                return .{
                    .date = self.date.lastWeekDay(k),
                    .time = self.time,
                };
            } else {
                return self.toFixedDateTime().lastWeekDay(k);
            }
        }

        /// Validates a date time
        pub fn validate(self: @This()) !void {
            try self.date.validate();
            try self.time.validate();
        }

        /// Creates a date time from a fixed date time
        pub fn fromFixedDateTime(fdt: fixed.DateTime) @This() {
            return .{
                .date = Cal.fromFixedDate(fdt.date),
                .time = fdt.time,
            };
        }

        /// Converts a date time to a fixed date time
        pub fn toFixedDateTime(self: @This()) fixed.DateTime {
            var tm = self.time.toDayFractionRaw();
            const d = self.date.toFixedDate();
            const dayOffset: i32 = @as(i32, @intFromFloat(@floor(tm)));
            tm = tm - @as(f64, @floatFromInt(dayOffset));
            assert(tm >= 0);
            assert(tm < 1);
            return fixed.DateTime{
                .date = d.addDays(dayOffset),
                .time = (t.DayFraction.init(tm) catch unreachable).toSegments(),
            };
        }

        /// Compares date times
        pub fn compare(self: @This(), other: @This()) i32 {
            const dateCompare = self.date.compare(other.date);
            if (dateCompare != 0) {
                return dateCompare;
            }
            return self.time.compare(other.time);
        }

        /// Formats date times
        pub fn format(
            self: @This(),
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

/// Creates a DateTimeZoned wrapper for any calendar struct which has the following:
///  - fn validate(self: Date) !void
///     - Runs validation checks to ensure date is valid
///     - generates `fn validate(self: CalendarDateTime(Date)) !void`
///  - compare(self: Date, other: Date) i32
///     - Compares two dates
///  - fromFixedDate(fixedDate: fixed.Date) Date
///     - Creates a new date from a fixed date
///  - toFixedDate(self: Date) fixed.Date
///     - Converts a date to a fixed date
///  Optional:
///  - addDays(self: Date, n: i32) Date
///     - Will default to converting to a fixed date, adding days, and converting back
///  - subDays(self: Date, n: i32) Date
///     - Will default to converting to a fixed date, subtracting days, and converting back
///  - dayOfWeek(self: Date) DayOfWeek
///  - nthWeekDay(self: Date, n: i32, k: DayOfWeek)
///  - dayOfWeekBefore(self: Date, k: DayOfWeek)
///  - dayOfWeekAfter(self: Date, k: DayOfWeek)
///  - dayOfWeekNearest(self: Date, k: DayOfWeek)
///  - dayOfWeekOnOrBefore(self: Date, k: DayOfWeek)
///  - dayOfWeekOnOrAfter(self: Date, k: DayOfWeek)
///  - firstWeekDay(self: Date, k: DayOfWeek)
///  - lastWeekDay(self: Date, k: DayOfWeek)
///  - format(self: Date, comptime f: []const u8, options: std.fmt.FormatOptions, writer: anytype) !usize
///
/// If you wish to have a format function on the DateTimeZone struct, just provide
/// one one the calendar struct.
pub fn CalendarDateTimeZoned(Cal: type) type {
    const DateTimeInner = CalendarDateTime(Cal);
    comptime assert(@hasDecl(Cal, "toFixedDate"));

    const hasFormat = if (comptime @hasDecl(Cal, "format"))
        true
    else
        false;

    comptime assert(@hasDecl(Cal, "fromFixedDate"));

    comptime assert(@hasDecl(Cal, "compare"));

    comptime assert(@hasDecl(Cal, "validate"));

    return struct {
        pub const DateTime = DateTimeInner;
        pub const Date = DateTime.Date;
        pub const Time = DateTime.Time;
        pub const Zone = TimeZone;

        date: DateTime.Date,
        time: DateTime.Time,
        zone: Zone,

        /// Returns a copy n days into the future
        pub fn addDays(self: @This(), n: i32) @This() {
            const dt = DateTime{ .date = self.date, .time = self.time };
            const dt2 = dt.addDays(n);
            return .{
                .date = dt2.date,
                .time = dt2.time,
                .zone = self.zone,
            };
        }

        /// Returns a copy n days into the past
        pub fn subDays(self: @This(), n: i32) @This() {
            const dt = DateTime{ .date = self.date, .time = self.time };
            const dt2 = dt.subDays(n);
            return .{
                .date = dt2.date,
                .time = dt2.time,
                .zone = self.zone,
            };
        }

        /// Returns whether the date/time is valid
        pub fn isValid(self: @This()) bool {
            self.validate() catch return false;
            return true;
        }

        /// Coerces to nearest valid date time
        pub fn nearestValid(self: @This()) @This() {
            if (self.isValid()) {
                return self;
            }
            return @This().fromFixedDateTimeZoned(
                self.toFixedDateTimeZoned(),
            );
        }

        /// Returns difference in days
        pub fn dayDifference(self: @This(), right: @This()) i32 {
            return self.toFixedDateTimeZoned().dayDifference(
                right.toFixedDateTimeZoned(),
            );
        }

        /// Returns the day of the week
        pub fn dayOfWeek(self: @This()) DayOfWeek {
            if (comptime std.meta.hasFn(Cal, "dayOfWeek")) {
                return self.date.dayOfWeek();
            } else {
                return self.toFixedDateTimeZoned().dayOfWeek();
            }
        }

        /// Returns the nth occurence of a day of week before the current
        /// date (or after if n is negative)
        /// If n is zero, it will return the current date instead
        pub fn nthWeekDay(self: @This(), n: i32, k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "nthWeekDay")) {
                return .{
                    .date = self.date.nthWeekDay(n, k),
                    .time = self.time,
                    .zone = self.zone,
                };
            } else {
                return self.toFixedDateTimeZoned().nthWeekDay(n, k);
            }
        }

        /// Finds the first date before the current date that occurs on the target
        /// day of the week
        /// (from book, same as k_day_before)
        pub fn dayOfWeekBefore(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "dayOfWeekBefore")) {
                return .{
                    .date = self.date.dayOfWeekBefore(k),
                    .time = self.time,
                    .zone = self.zone,
                };
            } else {
                return self.toFixedDateTimeZoned().dayOfWeekBefore(k);
            }
        }

        /// Finds the first date after the current date that occurs on the target
        /// day of the week
        /// (from book, same as k_day_after)
        pub fn dayOfWeekAfer(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "dayOfWeekAfer")) {
                return .{
                    .date = self.date.dayOfWeekAfter(k),
                    .time = self.time,
                    .zone = self.zone,
                };
            } else {
                return self.toFixedDateTimeZoned().dayOfWeekAfter(k);
            }
        }

        /// Finds the first date nearest th current date that occurs on the target
        /// day of the week
        /// (from book, same as k_day_neareast)
        pub fn dayOfWeekNearest(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "dayOfWeekNearest")) {
                return .{
                    .date = self.date.dayOfWeekNearest(k),
                    .time = self.time,
                    .zone = self.zone,
                };
            } else {
                return self.toFixedDateTimeZoned().dayOfWeekNearest(k);
            }
        }

        /// Finds the first date on or before the current date that occurs on the
        /// target day of the week
        /// (from book, same as k_day_on_or_before)
        pub fn dayOfWeekOnOrBefore(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "dayOfWeekOnOrBefore")) {
                return .{
                    .date = self.date.dayOfWeekOnOrBefore(k),
                    .time = self.time,
                    .zone = self.zone,
                };
            } else {
                return self.toFixedDateTimeZoned().dayOfWeekOnOrBefore(k);
            }
        }

        /// Finds the first date on or after the current date that occurs on the
        /// target day of the week
        /// (from book, same as k_day_on_or_after)
        pub fn dayOfWeekOnOrAfter(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "dayOfWeekOnOrAfter")) {
                return .{
                    .date = self.date.dayOfWeekOnOrAfter(k),
                    .time = self.time,
                    .zone = self.zone,
                };
            } else {
                return self.toFixedDateTimeZoned().dayOfWeekOnOrAfter(k);
            }
        }

        pub fn firstWeekDay(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "firstWeekDay")) {
                return .{
                    .date = self.date.firstWeekDay(k),
                    .time = self.time,
                    .zone = self.zone,
                };
            } else {
                return self.toFixedDateTimeZoned().firstWeekDay(k);
            }
        }

        pub fn lastWeekDay(self: @This(), k: DayOfWeek) @This() {
            if (comptime std.meta.hasFn(Cal, "lastWeekDay")) {
                return .{
                    .date = self.date.lastWeekDay(k),
                    .time = self.time,
                    .zone = self.zone,
                };
            } else {
                return self.toFixedDateTimeZoned().lastWeekDay(k);
            }
        }

        /// Converts to the UTC timezone
        pub fn toUtc(self: @This()) @This() {
            const timeNs = self.time.toNanoSeconds();
            const offset = self.zone.offsetInNanoSeconds();
            var date = self.date;
            var nano = @as(i64, @intCast(timeNs.nano)) - offset;

            if (nano < 0) {
                date = date.subDays(1);
                nano = t.NanoSeconds.max + nano;
            } else if (nano >= t.NanoSeconds.max) {
                date = date.addDays(1);
                nano = nano - t.NanoSeconds.max;
            }
            assert(nano >= 0);
            assert(nano < t.NanoSeconds.max);

            const dt = (t.NanoSeconds.init(
                @as(u64, @intCast(nano)),
            ) catch unreachable).toSegments();
            return .{
                .date = date,
                .time = dt,
                .zone = zone.UTC,
            };
        }

        /// Converts to another timezone
        pub fn toTimezone(self: @This(), tz: TimeZone) @This() {
            if (tz.compareOffset(zone.UTC) == 0) {
                var res = self.toUtc();
                res.zone = tz;
                return res;
            }

            const utc = if (self.zone.compare(zone.UTC) == 0) self else self.toUtc();
            const timeNs = utc.time.toNanoSeconds();
            const offset = tz.offsetInNanoSeconds();
            var date = utc.date;
            var nano = @as(i64, @intCast(timeNs.nano)) + offset;

            if (nano < 0) {
                date = date.subDays(1);
                nano = t.NanoSeconds.max + nano;
            } else if (nano >= t.NanoSeconds.max) {
                date = date.addDays(1);
                nano = nano - t.NanoSeconds.max;
            }
            assert(nano >= 0);
            assert(nano < t.NanoSeconds.max);

            const dt = (t.NanoSeconds.init(
                @as(u64, @intCast(nano)),
            ) catch unreachable).toSegments();
            return .{
                .date = date,
                .time = dt,
                .zone = tz,
            };
        }

        /// Initializes a date time. Will error if inputs are not valid
        pub fn init(date: Cal, time: Time, tz: TimeZone) !@This() {
            try date.validate();
            try time.validate();
            try tz.validate();
            return .{ .date = date, .time = time, .zone = tz };
        }

        /// Validates a date time
        pub fn validate(self: @This()) !void {
            try self.date.validate();
            try self.time.validate();
            try self.zone.validate();
        }

        /// Creates from a date time
        pub fn fromDateTime(dt: DateTime, tz: TimeZone) @This() {
            const dtv = dt.nearestValid();
            return .{
                .date = dtv.date,
                .time = dtv.time,
                .zone = tz,
            };
        }

        /// Converts to DateTime in terms of target timezone
        pub fn toDateTime(self: @This(), target_tz: TimeZone) DateTime {
            const dtz = self.toTimezone(target_tz);
            return .{ .date = dtz.date, .time = dtz.time };
        }

        /// Creates a date time from a fixed date time
        pub fn fromFixedDateTimeZoned(fdt: fixed.DateTimeZoned) @This() {
            const dt = DateTime.fromFixedDateTime(.{
                .date = fdt.date,
                .time = fdt.time,
            });
            return .{
                .date = dt.date,
                .time = dt.time,
                .zone = fdt.zone,
            };
        }

        /// Converts a date time to a fixed date time
        pub fn toFixedDateTimeZoned(self: @This()) fixed.DateTimeZoned {
            const fdt = (DateTime{
                .date = self.date,
                .time = self.time,
            }).toFixedDateTime();
            return fixed.DateTimeZoned{
                .date = fdt.date,
                .time = fdt.time,
                .zone = self.zone,
            };
        }

        /// Compares date times
        pub fn compare(
            self: @This(),
            other: @This(),
        ) i32 {
            const s = self.toUTC();
            const o = other.toUTC();
            const dateCompare = s.date.compare(o.date);
            if (dateCompare != 0) {
                return dateCompare;
            }
            return s.time.compare(o.time);
        }

        /// Formats date times
        pub fn format(
            self: @This(),
            comptime f: []const u8,
            options: fmt.FormatOptions,
            writer: anytype,
        ) !void {
            self.validate() catch {
                try writer.print("<INVALID_DATE_TIME_ZONE>::", .{});
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
            try writer.writeByte(' ');
            try self.zone.format(f, options, writer);
        }
    };
}
