const fixed = @import("../calendars/fixed.zig");
const t = @import("../calendars.zig").time;
const assert = @import("std").debug.assert;
const fmt = @import("std").fmt;
const mem = @import("std").mem;
const ValidationError = @import("./core.zig").ValidationError;
const DayOfWeek = @import("./core.zig").DayOfWeek;
const meta = @import("std").meta;
const math = @import("../utils/math.zig");
const epochs = @import("./epochs.zig");

/// Mixin to provide generic versions of many helpful methods via fixed.Date.
/// These generic methods include converting to and from fixed.Date which may be
/// slower than a specific method. However, many of these methods are usually
/// implemented by casting back and forth anyways, so it can help in many cases.
///
/// If a specific function is already provided on the class, then a generic
/// method will not be provided and the existing method will be used. This is
/// to allow for calendars to provide better optimized versions of methods while
/// still having a generic method for less-used functions.
///
/// Requires the following methods to be present on the calendar system:
///  - fromFixedDate(fixedDate: fixed.Date) Date
///     - Creates a new date from a fixed date
///  - toFixedDate(self: Date) fixed.Date
///     - Converts a date to a fixed date
///
/// IMPORTANT! NONE of the above methods can call ANY of the generated methods.
///            Doing so will cause an infinite recursive loop and blow the stack.
///            This is because all of the generated methods call fromFixedDate
///            and toFixedDate.
///
/// Since this is a mixin, it will not affect the top level scope of the struct.
/// Binding to the mixin is still needed.
///
/// Ensures that the following methods are present:
/// - fn validate(self: Cal) !void
///     Validates a calendar is valid
/// - fn dayDifference(self: Cal, right: Cal) i32
///     Difference (in days) between two calendars
/// - fn compare(self: Cal, right: Cal) i32
///     Compares two calendars. -1 if self < right, 0 if ==, 1 if >
/// - fn isValid(self: Cal) bool
///     Makes sure a calendar is valid
/// - fn nearestValid(self: Cal) Cal
///     Returns a calendar date that is the nearest valid representation to the
///     current date
/// - fn addDays(self: Cal, days: i32) Cal
///     Returns a new calendar with that many days added to it
/// - fn subDays(self: Cal, days: i32) Cal
///     Returns a new calendar with that many days subtracted from it
pub fn CalendarMixin(comptime Cal: type) type {
    comptime assert(@hasDecl(Cal, "toFixedDate"));
    switch (@typeInfo(@TypeOf(Cal.toFixedDate))) {
        .Fn => |f| {
            comptime assert(f.params.len == 1);
            comptime assert(f.params[0].type == Cal);
            comptime assert(f.return_type == fixed.Date);
        },
        else => unreachable,
    }

    comptime assert(@hasDecl(Cal, "fromFixedDate"));
    switch (@typeInfo(@TypeOf(Cal.fromFixedDate))) {
        .Fn => |f| {
            comptime assert(f.params.len == 1);
            comptime assert(f.params[0].type == fixed.Date);
            comptime assert(f.return_type == Cal);
        },
        else => unreachable,
    }

    // Note: we have to do our hasDecl checks all at once
    // Otherwise, the zig compiler gets confused that we're checking a struct
    // that whe're also modifying, and so it complains
    const addDayDiff = !@hasDecl(Cal, "dayDifference");
    const addCompare = !@hasDecl(Cal, "compare");
    const addValid = !@hasDecl(Cal, "isValid");
    const addValidate = !@hasDecl(Cal, "validate");
    const addNearestValid = !@hasDecl(Cal, "nearestValid");
    const addAddDays = !@hasDecl(Cal, "addDays");
    const addSubDays = !@hasDecl(Cal, "subDays");
    const addDayOfWeek = !@hasDecl(Cal, "dayOfWeek");

    return struct {
        pub usingnamespace if (addDayDiff) struct {
            /// Gets the difference between two dates
            /// NOTE: calls toFixedDate()
            pub fn dayDifference(self: Cal, right: Cal) i32 {
                const l = self.toFixedDate().day;
                const r = right.toFixedDate().day;
                return l - r;
            }
        } else struct {};

        pub usingnamespace if (addCompare) struct {
            /// Compares two dates to see which is larger
            /// NOTE: calls toFixedDate()
            pub fn compare(self: Cal, right: Cal) i32 {
                // We don't know the order fields are defined in,
                // so we will just convert to fixed.Date and compare that
                const leftFixed = self.toFixedDate();
                const rightFixed = right.toFixedDate();

                if (leftFixed.day != rightFixed.day) {
                    if (leftFixed.day > rightFixed.day) {
                        return 1;
                    }
                    return -1;
                }
                return 0;
            }
        } else struct {};

        pub usingnamespace if (addDayOfWeek) struct {
            /// Returns the current day of the week for a calendar
            pub fn dayOfWeek(self: Cal) DayOfWeek {
                const f = self.toFixedDate();
                const d = f.day - epochs.fixed - @intFromEnum(DayOfWeek.Sunday);
                const dow = math.mod(u8, d, 7);
                assert(dow >= 0);
                assert(dow < 7);
                return @enumFromInt(dow);
            }
        };

        pub usingnamespace if (addValid) struct {
            /// Checks if a date is valid
            /// NOTE: calls toFixedDate() and fromFixedDate()
            /// (unless validate() is manually provided)
            pub fn isValid(self: Cal) bool {
                if (comptime !addValidate) {
                    self.validate() catch return false;
                    return true;
                }

                // Generally, a "valid" date can convert to and from fixed.Date
                // and have the same feilds
                const actual = self.fromFixedDate(self.toFixedDate());

                // Check all our fields to make sure they're the same
                inline for (meta.fields(@TypeOf(self))) |field| {
                    const orig = @as(field.type, @field(self, field.name));
                    const real = @as(field.type, @field(actual, field.name));

                    if (orig != real) {
                        return false;
                    }
                }
                return true;
            }
        } else struct {};

        pub usingnamespace if (addValidate) struct {
            /// Checks if a date is valid
            /// NOTE: calls toFixedDate() and fromFixedDate()
            /// (unless isValid() is manually provided)
            pub fn validate(self: Cal) !void {
                if (comptime !addValid) {
                    if (!self.isValid()) {
                        return ValidationError.InvalidOther;
                    }
                    return;
                }

                // Generally, a "valid" date can convert to and from fixed.Date
                // and have the same feilds
                const actual = Cal.fromFixedDate(self.toFixedDate());

                // Check all our fields to make sure they're the same
                inline for (meta.fields(@TypeOf(self))) |field| {
                    const orig = @as(field.type, @field(self, field.name));
                    const real = @as(field.type, @field(actual, field.name));

                    if (orig != real) {
                        return ValidationError.InvalidOther;
                    }
                }
            }
        } else struct {};

        pub usingnamespace if (addNearestValid) struct {
            /// Converts a date to the nearest valid date
            /// NOTE: calls toFixedDate and fromFixedDate
            pub fn nearestValid(self: Cal) Cal {
                if (self.isValid()) {
                    return self;
                }
                return Cal.fromFixedDate(self.toFixedDate());
            }
        } else struct {};

        pub usingnamespace if (addAddDays) struct {
            /// Adds n days to the date
            /// NOTE: calls toFixedDate and fromFixedDate
            pub fn addDays(self: Cal, days: i32) Cal {
                var f = self.toFixedDate();
                f.day += days;
                return Cal.fromFixedDate(f);
            }
        };

        pub usingnamespace if (addSubDays) struct {
            /// Removes n days from the date
            /// NOTE: calls toFixedDate and fromFixedDate
            pub fn subDays(self: Cal, days: i32) Cal {
                var f = self.toFixedDate();
                f.day -= days;
                return Cal.fromFixedDate(f);
            }
        };
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
    switch (@typeInfo(@TypeOf(Cal.toFixedDate))) {
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

    comptime assert(@hasDecl(Cal, "fromFixedDate"));
    switch (@typeInfo(@TypeOf(Cal.fromFixedDate))) {
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
