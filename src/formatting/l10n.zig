const Gregorian = @import("../calendars.zig").gregorian.DateTimeZoned;
const Wrapper = @import("../calendars/wrappers.zig");
const std = @import("std");
const TimeSegments = @import("../calendars/time.zig").Segments;
const features = @import("../utils/features.zig");
const DayOfWeek = @import("../calendars.zig").DayOfWeek;

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
    if (comptime features.isUnixTimestamp(Cal)) {
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
    comptime std.debug.assert(std.meta.hasFn(Locale, "adLong"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "bcLong"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "adShort"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "bcShort"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "dateFull"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dateLong"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dateMedium"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dateShort"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "dateTimeFull"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dateTimeLong"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dateTimeMedium"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dateTimeShort"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "timeFull"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "timeLong"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "timeMedium"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "timeShort"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "ordinal"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "quarterShort"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "quarterLong"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "monthNameShort"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "monthNameLong"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "monthNameFirstLetter"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "dayOfWeekShort"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dayOfWeekFull"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dayOfWeekFirstLetter"));
    comptime std.debug.assert(std.meta.hasFn(Locale, "dayOfWeekFirst2Letters"));

    comptime std.debug.assert(std.meta.hasFn(Locale, "timeOfDay"));
}

pub const EnUsLocale = struct {
    pub const locale = "en-us";

    pub fn adLong(_: @This()) []const u8 {
        return "Anno Domini";
    }
    pub fn bcLong(_: @This()) []const u8 {
        return "Before Christ";
    }
    pub fn adShort(_: @This()) []const u8 {
        return "AD";
    }
    pub fn bcShort(_: @This()) []const u8 {
        return "BC";
    }

    pub fn dateFull(_: @This()) []const u8 {
        return "EEEE, MMMM d, y G";
    }
    pub fn dateLong(_: @This()) []const u8 {
        return "MMMM d, y";
    }
    pub fn dateMedium(_: @This()) []const u8 {
        return "MMM d, y";
    }
    pub fn dateShort(_: @This()) []const u8 {
        return "M/d/y";
    }

    pub fn timeFull(_: @This()) []const u8 {
        return "h:mm:ss a xxx";
    }
    pub fn timeLong(_: @This()) []const u8 {
        return "h:mm:ss a xxx";
    }
    pub fn timeMedium(_: @This()) []const u8 {
        return "h:mm:ss a";
    }
    pub fn timeShort(_: @This()) []const u8 {
        return "h:mm a";
    }

    pub fn dateTimeFull(_: @This()) []const u8 {
        return "EEEE, MMMM d, y G, h:mm:ss a xxx";
    }
    pub fn dateTimeLong(_: @This()) []const u8 {
        return "MMMM d, y, h:mm:ss a xxx";
    }
    pub fn dateTimeMedium(_: @This()) []const u8 {
        return "MMM d, y, h:mm:ss a";
    }
    pub fn dateTimeShort(_: @This()) []const u8 {
        return "M/d/y, h:mm a";
    }

    pub fn timeOfDay(_: @This(), writer: anytype, time: TimeSegments) !void {
        if (time.hour < 12) {
            try writer.writeAll("AM");
        } else {
            try writer.writeAll("PM");
        }
    }

    pub fn dayOfWeekFirst2Letters(_: @This(), writer: anytype, day_of_week: DayOfWeek) !void {
        switch (day_of_week) {
            .Sunday => try writer.writeAll("Su"),
            .Monday => try writer.writeAll("Mo"),
            .Tuesday => try writer.writeAll("Tu"),
            .Wednesday => try writer.writeAll("We"),
            .Thursday => try writer.writeAll("Th"),
            .Friday => try writer.writeAll("Fr"),
            .Saturday => try writer.writeAll("Sa"),
        }
    }

    pub fn dayOfWeekFirstLetter(_: @This(), writer: anytype, day_of_week: DayOfWeek) !void {
        switch (day_of_week) {
            .Sunday, .Saturday => try writer.writeAll("S"),
            .Monday => try writer.writeAll("M"),
            .Tuesday, .Thursday => try writer.writeAll("T"),
            .Wednesday => try writer.writeAll("W"),
            .Friday => try writer.writeAll("F"),
        }
    }

    pub fn dayOfWeekFull(_: @This(), writer: anytype, day_of_week: DayOfWeek) !void {
        switch (day_of_week) {
            .Sunday => try writer.writeAll("Sunday"),
            .Monday => try writer.writeAll("Monday"),
            .Tuesday => try writer.writeAll("Tuesday"),
            .Wednesday => try writer.writeAll("Wednesday"),
            .Thursday => try writer.writeAll("Thursday"),
            .Friday => try writer.writeAll("Friday"),
            .Saturday => try writer.writeAll("Saturday"),
        }
    }

    pub fn dayOfWeekShort(_: @This(), writer: anytype, day_of_week: DayOfWeek) !void {
        switch (day_of_week) {
            .Sunday => try writer.writeAll("Sun"),
            .Monday => try writer.writeAll("Mon"),
            .Tuesday => try writer.writeAll("Tue"),
            .Wednesday => try writer.writeAll("Wed"),
            .Thursday => try writer.writeAll("Thu"),
            .Friday => try writer.writeAll("Fri"),
            .Saturday => try writer.writeAll("Sat"),
        }
    }

    pub fn monthNameShort(_: @This(), writer: anytype, month: u32) !void {
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

    pub fn monthNameLong(_: @This(), writer: anytype, month: u32) !void {
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

    pub fn monthNameFirstLetter(_: @This(), writer: anytype, month: u32) !void {
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

    pub fn quarterShort(_: @This(), writer: anytype, quarter: u32) !void {
        try writer.print("Q{d}", .{quarter});
    }

    pub fn quarterLong(_: @This(), writer: anytype, quarter: u32) !void {
        try writer.print("Quarter {d}", .{quarter});
    }

    pub fn ordinal(_: @This(), writer: anytype, int: anytype) !void {
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
