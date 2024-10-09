const fixed = @import("../calendars/fixed.zig");
const t = @import("../calendars.zig").time;
const assert = @import("std").debug.assert;

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
/// The reason toFixed is optional is that some calendaring systems don't track
/// absolute dates. Instead, they only track the relative dates in a cycle.
///
/// This is similar to us writing "March 1", "Dec 12", etc. Without the year,
/// we can't convert to a fixed date, and if we can't convert to a fixed date
/// then we can't convert to other calendars. Especially once leap years are
/// involved.
pub fn CalendarDateTime(comptime Cal: type, comptime Time: type) type {
    const hasToFixed = if (comptime @hasDecl(Cal, "toFixed"))
        switch (@typeInfo(@TypeOf(Cal.toFixed))) {
            .Fn => |f| f.params.len == 1 and f.params[0].type == Cal and f.return_type == fixed.Date,
            else => false,
        }
    else
        false;

    comptime assert(@hasDecl(Cal, "fromFixed"));
    comptime assert(switch (@typeInfo(@TypeOf(Cal.fromFixed))) {
        .Fn => |f| f.params.len == 1 and f.params[0].type == fixed.Date and f.return_type == Cal,
        else => unreachable,
    });

    comptime assert(@hasDecl(Cal, "compare"));
    comptime assert(switch (@typeInfo(@TypeOf(Cal.compare))) {
        .Fn => |f| f.params.len == 2 and f.return_type == i32 and f.params[0].type == Cal and f.params[1].type == Cal,
        else => unreachable,
    });

    comptime assert(@hasDecl(Cal, "validate"));
    comptime assert(switch (@typeInfo(@TypeOf(Cal.validate))) {
        .Fn => |f| f.params.len == 1 and f.params[0].type == Cal,
        else => unreachable,
    });

    comptime assert(Time == t.Segments or Time == t.NanoSeconds or Time == t.DayFraction);

    if (hasToFixed) {
        return struct {
            date: Cal,
            time: Time,

            pub fn init(date: Cal, time: Time) !CalendarDateTime(Cal, Time) {
                try date.validate();
                try time.validate();
                return .{ .date = date, .time = time };
            }

            pub fn validate(self: CalendarDateTime(Cal, Time)) !void {
                try self.date.validate();
                try self.time.validate();
            }

            pub fn toFixed(self: CalendarDateTime(Cal, Time)) !fixed.DateTime {
                if (comptime Time == t.Segments) {
                    try self.time.validate();
                    return fixed.DateTime{ .date = self.date.toFixed(), .time = self.time };
                } else {
                    return fixed.DateTime{ .date = self.date.toFixed(), .time = try self.time.toSegments() };
                }
            }

            pub fn fromFixed(fdt: fixed.DateTime) !CalendarDateTime(Cal, Time) {
                if (comptime Time == t.Segments) {
                    try fdt.time.validate();
                    return .{ .date = Cal.fromFixed(fdt.date), .time = fdt.time };
                } else if (comptime Time == t.NanoSeconds) {
                    return .{ .date = Cal.fromFixed(fdt.date), .time = try fdt.time.toNanoSeconds() };
                } else {
                    return .{ .date = Cal.fromFixed(fdt.date), .time = try fdt.time.toDayFraction() };
                }
            }

            pub fn compare(
                self: CalendarDateTime(Cal, Time),
                other: CalendarDateTime(Cal, Time),
            ) i32 {
                const dateCompare = self.date.compare(other.date);
                if (dateCompare != 0) {
                    return dateCompare;
                }
                return self.time.compare(other.time);
            }
        };
    } else {
        return struct {
            date: Cal,
            time: Time,

            pub fn init(date: Cal, time: Time) !CalendarDateTime(Cal, Time) {
                try date.validate();
                try time.validate();
                return .{ .date = date, .time = time };
            }

            pub fn validate(self: CalendarDateTime(Cal, Time)) !void {
                try self.date.validate();
                try self.time.validate();
            }

            pub fn fromFixed(fdt: fixed.DateTime) CalendarDateTime(Cal, Time) {
                return .{
                    .date = Cal.fromFixed(fdt.date),
                    .time = fdt.time,
                };
            }

            pub fn compare(
                self: CalendarDateTime(Cal, Time),
                other: CalendarDateTime(Cal, Time),
            ) i32 {
                const dateCompare = self.date.compare(other.date);
                if (dateCompare != 0) {
                    return dateCompare;
                }
                return self.time.compare(other.time);
            }
        };
    }
}
