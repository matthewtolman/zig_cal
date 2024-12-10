const Gregorian = @import("../calendars.zig").gregorian.DateTimeZoned;
const Wrapper = @import("../calendars/wrappers.zig");
const std = @import("std");
const TimeSegments = @import("../calendars/time.zig").Segments;

pub const SegmentLen = enum {
    Shortest,
    MediumShort,
    MediumLong,
    Longest,
};

pub const DateFormatError = error{
    UnsupportedFormat,
    InvalidDate,
    InvalidTime,
};

pub fn ZonedDateTimeOf(comptime Cal: type) type {
    const unix = @import("../calendars.zig").unix;
    if (Cal == unix.Timestamp or Cal == unix.TimestampMs) {
        return Cal;
    }
    const wrappers = @import("../calendars/wrappers.zig");
    if (@hasDecl(Cal, "Date")) {
        if (@hasDecl(Cal, "Time") and @hasDecl(Cal, "Zone")) {
            return Cal;
        }
        return wrappers.CalendarDateTimeZoned(Cal.Date);
    }
    return wrappers.CalendarDateTimeZoned(Cal);
}

pub fn assertValidLocale(Locale: type) void {
    comptime std.debug.assert(@hasDecl(Locale, "AD_Long"));
    comptime std.debug.assert(@hasDecl(Locale, "AD_Short"));
    comptime std.debug.assert(@hasDecl(Locale, "BC_Long"));
    comptime std.debug.assert(@hasDecl(Locale, "BC_Short"));

    comptime std.debug.assert(@hasDecl(Locale, "date_full"));
    comptime std.debug.assert(@hasDecl(Locale, "date_long"));
    comptime std.debug.assert(@hasDecl(Locale, "date_medium"));
    comptime std.debug.assert(@hasDecl(Locale, "date_short"));

    comptime std.debug.assert(@hasDecl(Locale, "time_full"));
    comptime std.debug.assert(@hasDecl(Locale, "time_long"));
    comptime std.debug.assert(@hasDecl(Locale, "time_medium"));
    comptime std.debug.assert(@hasDecl(Locale, "time_short"));

    comptime std.debug.assert(@hasDecl(Locale, "datetime_full"));
    comptime std.debug.assert(@hasDecl(Locale, "datetime_long"));
    comptime std.debug.assert(@hasDecl(Locale, "datetime_medium"));
    comptime std.debug.assert(@hasDecl(Locale, "datetime_short"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "ordinal"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "quarterShort"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "quarterLong"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "monthShort"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "monthLong"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "monthFirstLetter"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "dayOfWeekShort"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dayOfWeekFull"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dayOfWeekFirstLetter"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dayOfWeekFirst2Letters"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "timeOfDay"));
}

pub const EnUsLocale = struct {
    pub const locale = "en-us";

    pub const AD_Long = "Anno Domini";
    pub const BC_Long = "Before Christ";
    pub const AD_Short = "AD";
    pub const BC_Short = "BC";

    pub const date_full = "EEEE, MMMM d, y G";
    pub const date_long = "MMMM d, y";
    pub const date_medium = "MMM d, y";
    pub const date_short = "M/d/y";

    pub const time_full = "h:mm:ss a xxx";
    pub const time_long = "h:mm:ss a xxx";
    pub const time_medium = "h:mm:ss a";
    pub const time_short = "h:mm a";

    pub const datetime_full = "EEEE, MMMM d, y G, h:mm:ss a xxx";
    pub const datetime_long = "MMMM d, y, h:mm:ss a xxx";
    pub const datetime_medium = "MMM d, y, h:mm:ss a";
    pub const datetime_short = "M/d/y, h:mm a";

    pub fn timeOfDay(writer: anytype, time: TimeSegments) !void {
        if (time.hour < 12) {
            try writer.writeAll("AM");
        } else {
            try writer.writeAll("PM");
        }
    }

    pub fn dayOfWeekFirst2Letters(writer: anytype, day_of_week: u32) !void {
        switch (day_of_week) {
            1 => try writer.writeAll("Su"),
            2 => try writer.writeAll("Mo"),
            3 => try writer.writeAll("Tu"),
            4 => try writer.writeAll("We"),
            5 => try writer.writeAll("Th"),
            6 => try writer.writeAll("Fr"),
            7 => try writer.writeAll("Sa"),
            else => try writer.writeAll("??"),
        }
    }

    pub fn dayOfWeekFirstLetter(writer: anytype, day_of_week: u32) !void {
        switch (day_of_week) {
            1, 7 => try writer.writeAll("S"),
            2 => try writer.writeAll("M"),
            3, 5 => try writer.writeAll("T"),
            4 => try writer.writeAll("W"),
            6 => try writer.writeAll("F"),
            else => try writer.writeAll("?"),
        }
    }

    pub fn dayOfWeekFull(writer: anytype, day_of_week: u32) !void {
        switch (day_of_week) {
            1 => try writer.writeAll("Sunday"),
            2 => try writer.writeAll("Monday"),
            3 => try writer.writeAll("Tuesday"),
            4 => try writer.writeAll("Wednesday"),
            5 => try writer.writeAll("Thurdsay"),
            6 => try writer.writeAll("Friday"),
            7 => try writer.writeAll("Saturday"),
            else => {
                std.debug.print("UNKNOWN: {d}\n", .{day_of_week});
                try writer.writeAll("Unknown");
            },
        }
    }

    pub fn dayOfWeekShort(writer: anytype, day_of_week: u32) !void {
        switch (day_of_week) {
            1 => try writer.writeAll("Sun"),
            2 => try writer.writeAll("Mon"),
            3 => try writer.writeAll("Tue"),
            4 => try writer.writeAll("Wed"),
            5 => try writer.writeAll("Thu"),
            6 => try writer.writeAll("Fri"),
            7 => try writer.writeAll("Sat"),
            else => try writer.writeAll("???"),
        }
    }

    pub fn monthShort(writer: anytype, month: u32) !void {
        switch (month) {
            1 => try writer.writeAll("Jan"),
            2 => try writer.writeAll("Feb"),
            3 => try writer.writeAll("Mar"),
            4 => try writer.writeAll("Apr"),
            5 => try writer.writeAll("May"),
            6 => try writer.writeAll("Jun"),
            7 => try writer.writeAll("Jul"),
            8 => try writer.writeAll("Aug"),
            9 => try writer.writeAll("Sep"),
            10 => try writer.writeAll("Oct"),
            11 => try writer.writeAll("Nov"),
            12 => try writer.writeAll("Dec"),
            else => try writer.writeAll("???"),
        }
    }

    pub fn monthLong(writer: anytype, month: u32) !void {
        switch (month) {
            1 => try writer.writeAll("January"),
            2 => try writer.writeAll("February"),
            3 => try writer.writeAll("March"),
            4 => try writer.writeAll("April"),
            5 => try writer.writeAll("May"),
            6 => try writer.writeAll("June"),
            7 => try writer.writeAll("July"),
            8 => try writer.writeAll("August"),
            9 => try writer.writeAll("September"),
            10 => try writer.writeAll("October"),
            11 => try writer.writeAll("November"),
            12 => try writer.writeAll("December"),
            else => try writer.writeAll("Unknown"),
        }
    }

    pub fn monthFirstLetter(writer: anytype, month: u32) !void {
        switch (month) {
            1 => try writer.writeAll("J"),
            2 => try writer.writeAll("F"),
            3, 5 => try writer.writeAll("M"),
            4, 8 => try writer.writeAll("A"),
            6, 7 => try writer.writeAll("J"),
            9 => try writer.writeAll("S"),
            10 => try writer.writeAll("O"),
            11 => try writer.writeAll("N"),
            12 => try writer.writeAll("D"),
            else => try writer.writeAll("?"),
        }
    }

    pub fn quarterShort(writer: anytype, quarter: u32) !void {
        try writer.print("Q{d}", .{quarter});
    }

    pub fn quarterLong(writer: anytype, quarter: u32) !void {
        try writer.print("Quarter {d}", .{quarter});
    }

    pub fn ordinal(writer: anytype, int: anytype) !void {
        const int_info = @typeInfo(@TypeOf(int));
        if (@hasField(@TypeOf(int_info), "Struct")) {
            comptime std.debug.assert(int_info == .ComptimeInt or int_info == .Int);
        } else {
            comptime std.debug.assert(int_info == .comptime_int or int_info == .int);
        }

        const i: u128 = @intCast(@abs(int));

        const category = i % 10;
        const exception = i % 100;

        if (category == 1 and exception != 11) {
            if (int >= 0) {
                try writer.print("{d}st", .{i});
            } else {
                try writer.print("-{d}st", .{i});
            }
        } else if (category == 2 and exception != 12) {
            if (int >= 0) {
                try writer.print("{d}nd", .{i});
            } else {
                try writer.print("-{d}nd", .{i});
            }
        } else if (category == 3 and exception != 13) {
            if (int >= 0) {
                try writer.print("{d}rd", .{i});
            } else {
                try writer.print("-{d}rd", .{i});
            }
        } else {
            if (int >= 0) {
                try writer.print("{d}th", .{i});
            } else {
                try writer.print("-{d}th", .{i});
            }
        }
    }
};

const _ = assertValidLocale(EnUsLocale);

// test "en-us" {
//     const TestCase = struct {
//         date: Gregorian,
//         len: SegmentLen,
//         expectedDate: []const u8,
//         expectedTime: []const u8,
//         expectedDateTime: []const u8,
//     };
//
//     const test_cases = [_]TestCase{
//         .{
//             date = Gregorian.init(
//             Gregorian.Date.initNums(2024, 12, 1),
//             Gregorian.Time.init(12, 3, 42, 93849),
//             Gregorian.Zone.
//             ,),
//         },
//     };
// }
//
