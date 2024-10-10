const fixed = @import("../calendars/fixed.zig");
const t = @import("../calendars.zig").time;
const assert = @import("std").debug.assert;
const fmt = @import("std").fmt;
const mem = @import("std").mem;

/// Creates a DateTime wrapper for any calendar struct which has the following:
///  - fn validate(self: Date) !void
///     - Runs validation checks to ensure date is valid
///     - generates `fn validate(self: CalendarDateTime(Date)) !void`
///  - compare(self: Date, other: Date) !i32
///     - Compares two dates
///     - generates `fn compare(self: CalendarDateTime(Date), other: CalendareDateTime(Date)) !i32`
///  - fromFixed(fixedDate: fixed.Date) !Date
///     - Creates a new date from a fixed date
///     - generates `fn fromFixed(fixedDateTime: fixed.DateTime) !CalendarDateTime(Date)`
///
/// Note that converting to a fixed.Date with toFixed is not required.
/// If toFixed is ommitted from the Date struct, then it will be omitted from
/// the outputted DateTime struct.
///
/// If you wish to have a toFixed on the DateTime struct, provide the following
/// on your Date struct:
///  - fn toFixed(self) !fixed.Date
///     - Converts date to a fixed date
///     - generates `fn toFixed(CalendarDateTime(Date)) !fixedDateTime: fixed.DateTime`
///
/// If you wish to have a format function on the DateTime struct, just provide
/// one one the calendar struct.
///
/// The reason toFixed is optional is that some calendaring systems don't track
/// absolute dates. Instead, they only track the relative dates in a cycle.
///
/// This is similar to us writing "March 1", "Dec 12", etc. Without the year,
/// we can't convert to a fixed date, and if we can't convert to a fixed date
/// then we can't convert to other calendars. Especially once leap years are
/// involved.
pub fn CalendarDateTime(comptime Cal: type) type {
    const Time = t.Segments;
    comptime assert(@hasDecl(Cal, "toFixed"));
    switch (@typeInfo(@TypeOf(Cal.toFixed))) {
        .Fn => |f| {
            comptime assert(f.params.len == 1);
            comptime assert(f.params[0].type == Cal);
            comptime assert(f.return_type == fixed.Date);
        },
        else => unreachable,
    }

    const hasFormat = if (comptime @hasDecl(Cal, "format"))
        true
    else
        false;

    comptime assert(@hasDecl(Cal, "fromFixed"));
    switch (@typeInfo(@TypeOf(Cal.fromFixed))) {
        .Fn => |f| {
            comptime assert(f.params.len == 1);
            comptime assert(f.params[0].type == fixed.Date);
            comptime assert(f.return_type == Cal);
        },
        else => unreachable,
    }

    comptime assert(@hasDecl(Cal, "compare"));
    switch (@typeInfo(@TypeOf(Cal.compare))) {
        .Fn => |f| {
            comptime assert(f.params.len == 2);
            comptime assert(f.return_type == i32);
            comptime assert(f.params[0].type == Cal);
            comptime assert(f.params[1].type == Cal);
        },
        else => unreachable,
    }

    comptime assert(@hasDecl(Cal, "validate"));
    comptime assert(switch (@typeInfo(@TypeOf(Cal.validate))) {
        .Fn => |f| f.params.len == 1 and f.params[0].type == Cal,
        else => unreachable,
    });

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
        pub fn fromFixed(fdt: fixed.DateTime) CalendarDateTime(Cal) {
            return .{
                .date = Cal.fromFixed(fdt.date),
                .time = fdt.time,
            };
        }

        /// Converts a date time to a fixed date time
        pub fn toFixed(self: CalendarDateTime(Cal)) fixed.DateTime {
            return fixed.DateTime{
                .date = self.date.toFixed(),
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
