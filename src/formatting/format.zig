const Format = @import("core.zig").Format;
const convert = @import("../utils/convert.zig").convert;
const std = @import("std");
const core = @import("../calendars/core.zig");
const l10n = @import("l10n.zig");
const gregorian = @import("../calendars/gregorian.zig");
const unix = @import("../calendars/unix_timestamp.zig");
const iso = @import("../calendars/iso.zig");
const zone = @import("../calendars/zone.zig");
const fixed = @import("../calendars/fixed.zig");

pub fn formatDate(
    self: *const Format,
    date: anytype,
    writer: anytype,
    comptime Locale: type,
) (@TypeOf(writer).Error)!void {
    comptime l10n.assertValidLocale(Locale);
    const D = l10n.ZonedDateTimeOf(@TypeOf(date));
    const d = convert(date, D);
    const segs = self._segs[0..self._segs_len];

    for (segs) |seg| {
        switch (seg.type) {
            .Year => try writeUnsignedYear(d, writer, seg.str.len),
            .YearOrdinal => try Locale.ordinal(writer, yearOf(u32, d)),
            .EraDesignatorShort => try eraDesignatorShort(d, writer, Locale),
            .EraDesignatorLong => try eraDesignatorLong(d, writer, Locale),
            .Text => try writeText(seg.str, writer),
            .MonthNum => try writeMonthNum(d, writer, seg.str.len),
            .MonthNameShort => try writeMonthShort(d, writer, Locale),
            .MonthNameLong => try writeMonthLong(d, writer, Locale),
            .MonthNameFirstLetter => try writeMonthInitial(d, writer, Locale),
            .DayOfMonthOrdinal => try Locale.ordinal(writer, dayOfMonthOf(u32, d)),
            .DayOfMonthNum => try writeMonthDay(d, writer, seg.str.len),
            .WeekInYear => try writeWeekYear(d, writer, seg.str.len),
            .WeekInYearOrdinal => try Locale.ordinal(writer, weekOf(u32, d)),
            .SignedYear => try writeSignedYear(d, writer, seg.str.len),
            .QuarterNum => try writeQuarterNum(d, writer, seg.str.len),
            .QuarterOrdinal => try Locale.ordinal(writer, quarterOf(u32, d)),
            .QuarterLong => try Locale.quarterLong(writer, quarterOf(u32, d)),
            .QuarterPrefixed => try Locale.quarterShort(writer, quarterOf(u32, d)),
            .DayofYearNum => try writeDayOfYear(d, writer, seg.str.len),
            .DayOfYearOrdinal => try Locale.ordinal(writer, dayOfYearOf(u32, d)),
            .DayOfWeekNum => try writeDayOfWeekOf(d, writer, seg.str.len),
            .DayOfWeekOrdinal => try Locale.ordinal(writer, dayOfWeekOf(u32, d)),
            .DayOfWeekNameFull => try Locale.dayOfWeekFull(writer, dayOfWeekOf(u32, d)),
            .DayOfWeekNameShort => try Locale.dayOfWeekShort(writer, dayOfWeekOf(u32, d)),
            .DayOfWeekNameFirstLetter => try Locale.dayOfWeekFirstLetter(writer, dayOfWeekOf(u32, d)),
            .DayOfWeekNameFirst2Letters => try Locale.dayOfWeekFirst2Letters(writer, dayOfWeekOf(u32, d)),
            .TimeOfDayLocale => try Locale.timeOfDay(writer, timeOf(d)),
            .TimeOfDayAM, .TimeOfDay_am, .TimeOfDay_ap, .TimeOfDay_a_m => |e| try writeTimeOfDay(d, writer, e),
            .Hour12Num => try writeHour12(d, writer, seg.str.len),
            .Hour12Ordinal => try Locale.ordinal(writer, hour12Of(d)),
            .Hour24Num => try writeHour24(d, writer, seg.str.len),
            .Hour24Ordinal => try Locale.ordinal(writer, hour24Of(d)),
            .MinuteNum => try writeMinute(d, writer, seg.str.len),
            .MinuteOrdinal => try Locale.ordinal(writer, minuteOf(d)),
            .SecondNum => try writeSecond(d, writer, seg.str.len),
            .SecondOrdinal => try Locale.ordinal(writer, secondOf(d)),
            .FractionOfASecond => try writeSecondFraction(d, writer, seg.str.len),
            .GmtOffset => try writeGmtOffset(d, writer),
            .GmtOffsetFull => try writeGmtOffsetFull(d, writer),
            .TimezoneOffset => try writeTz(d, writer, seg.str.len),
            .TimezoneOffsetZ => try writeTzZ(d, writer, seg.str.len),
            .LocalizedLongDate => try writeLocalizedDate(d, writer, seg.str.len, Locale),
            .LocalizedLongTime => try writeLocalizedTime(d, writer, seg.str.len, Locale),
            .LocalizedLongDateTime => try writeLocalizedDateTime(d, writer, seg.str.len, Locale),
            .CalendarSystem => try writeCalendarSystem(d, writer),
        }
    }
}

fn writeCalendarSystem(zoned_date: anytype, writer: anytype) !void {
    const Date = @TypeOf(zoned_date);
    if (@hasDecl(Date, "Name")) {
        try writer.writeAll(Date.Name);
    } else if (@hasDecl(Date, "Date") and @hasDecl(Date.Date, "Name")) {
        try writer.writeAll(Date.Date.Name);
    } else {
        try writer.writeAll("UNKNOWN");
    }
}

fn writeLocalizedDate(
    zoned_date: anytype,
    writer: anytype,
    variant: usize,
    Locale: type,
) (@TypeOf(writer).Error)!void {
    const parseFormatStr = @import("../formatting.zig").parseFormatStr;
    const lfs = switch (variant) {
        4 => Locale.date_full,
        3 => Locale.date_long,
        2 => Locale.date_medium,
        else => Locale.date_short,
    };
    const fmt = parseFormatStr(lfs) catch unreachable;
    try formatDate(&fmt, zoned_date, writer, Locale);
}

fn writeLocalizedDateTime(
    zoned_date: anytype,
    writer: anytype,
    variant: usize,
    Locale: type,
) (@TypeOf(writer).Error)!void {
    const parseFormatStr = @import("../formatting.zig").parseFormatStr;
    const lfs = switch (variant) {
        7, 8 => Locale.datetime_full,
        5, 6 => Locale.datetime_long,
        3, 4 => Locale.datetime_medium,
        else => Locale.datetime_short,
    };
    const fmt = parseFormatStr(lfs) catch unreachable;
    try formatDate(&fmt, zoned_date, writer, Locale);
}

fn writeLocalizedTime(
    zoned_date: anytype,
    writer: anytype,
    variant: usize,
    Locale: type,
) (@TypeOf(writer).Error)!void {
    const parseFormatStr = @import("../formatting.zig").parseFormatStr;
    const lfs = switch (variant) {
        4 => Locale.time_full,
        3 => Locale.time_long,
        2 => Locale.time_medium,
        else => Locale.time_short,
    };
    const fmt = parseFormatStr(lfs) catch unreachable;
    try formatDate(&fmt, zoned_date, writer, Locale);
}

fn writeTzZ(zoned_date: anytype, writer: anytype, variant: usize) !void {
    const tz = timezoneOf(zoned_date);

    if (tz.compareOffset(zone.UTC) == 0) {
        try writer.writeByte('Z');
        return;
    }

    const offset = tz.offset();

    const sign: u8 = if (offset.hours < 0) '-' else '+';
    const hour: u32 = @intCast(@abs(offset.hours));

    switch (variant) {
        1 => if (offset.minutes == 0) {
            try writer.print("{c}{d:0>2}", .{ sign, hour });
        } else {
            try writer.print(
                "{c}{d:0>2}{d:0>2}",
                .{ sign, hour, offset.minutes },
            );
        },
        2 => try writer.print(
            "{c}{d:0>2}{d:0>2}",
            .{ sign, hour, offset.minutes },
        ),
        3 => try writer.print(
            "{c}{d:0>2}:{d:0>2}",
            .{ sign, hour, offset.minutes },
        ),
        4 => if (offset.seconds != 0) {
            try writer.print(
                "{c}{d:0>2}{d:0>2}{d:0>2}",
                .{ sign, hour, offset.minutes, offset.seconds },
            );
        } else {
            try writer.print(
                "{c}{d:0>2}{d:0>2}",
                .{ sign, hour, offset.minutes },
            );
        },
        else => if (offset.seconds != 0) {
            try writer.print(
                "{c}{d:0>2}:{d:0>2}:{d:0>2}",
                .{ sign, hour, offset.minutes, offset.seconds },
            );
        } else {
            try writer.print(
                "{c}{d:0>2}:{d:0>2}",
                .{ sign, hour, offset.minutes },
            );
        },
    }
}

fn writeTz(zoned_date: anytype, writer: anytype, variant: usize) !void {
    const tz = timezoneOf(zoned_date);
    const offset = tz.offset();

    const sign: u8 = if (offset.hours < 0) '-' else '+';
    const hour: u32 = @intCast(@abs(offset.hours));

    switch (variant) {
        1 => if (offset.minutes == 0) {
            try writer.print("{c}{d:0>2}", .{ sign, hour });
        } else {
            try writer.print(
                "{c}{d:0>2}{d:0>2}",
                .{ sign, hour, offset.minutes },
            );
        },
        2 => try writer.print(
            "{c}{d:0>2}{d:0>2}",
            .{ sign, hour, offset.minutes },
        ),
        3 => try writer.print(
            "{c}{d:0>2}:{d:0>2}",
            .{ sign, hour, offset.minutes },
        ),
        4 => if (offset.seconds != 0) {
            try writer.print(
                "{c}{d:0>2}{d:0>2}{d:0>2}",
                .{ sign, hour, offset.minutes, offset.seconds },
            );
        } else {
            try writer.print(
                "{c}{d:0>2}{d:0>2}",
                .{ sign, hour, offset.minutes },
            );
        },
        else => if (offset.seconds != 0) {
            try writer.print(
                "{c}{d:0>2}:{d:0>2}:{d:0>2}",
                .{ sign, hour, offset.minutes, offset.seconds },
            );
        } else {
            try writer.print(
                "{c}{d:0>2}:{d:0>2}",
                .{ sign, hour, offset.minutes },
            );
        },
    }
}

fn writeGmtOffsetFull(zoned_date: anytype, writer: anytype) !void {
    const tz = timezoneOf(zoned_date);
    const offset = tz.offset();

    const sign: u8 = if (offset.hours < 0) '-' else '+';
    const hour: u32 = @intCast(@abs(offset.hours));

    if (offset.seconds == 0) {
        try writer.print("GMT{c}{d:0>2}:{d:0>2}", .{
            sign,
            hour,
            offset.minutes,
        });
    } else {
        try writer.print("GMT{c}{d:0>2}:{d:0>2}:{d:0>2}", .{
            sign,
            hour,
            offset.minutes,
            offset.seconds,
        });
    }
}

fn writeGmtOffset(zoned_date: anytype, writer: anytype) !void {
    const tz = timezoneOf(zoned_date);
    const offset = tz.offset();

    const sign: u8 = if (offset.hours < 0) '-' else '+';
    const hour: u32 = @intCast(@abs(offset.hours));

    if (offset.seconds == 0) {
        if (offset.minutes == 0) {
            try writer.print("GMT{c}{d}", .{ sign, hour });
        } else {
            try writer.print("GMT{c}{d}:{d:0>2}", .{
                sign,
                hour,
                offset.minutes,
            });
        }
    } else {
        try writer.print("GMT{c}{d}:{d:0>2}:{d:0>2}", .{
            sign,
            hour,
            offset.minutes,
            offset.seconds,
        });
    }
}

fn timezoneOf(zoned_date: anytype) zone.TimeZone {
    const Date = @TypeOf(zoned_date);
    if (Date == unix.Timestamp or Date == unix.TimestampMs) {
        return zone.UTC;
    }

    comptime std.debug.assert(@hasDecl(Date, "Zone"));
    comptime std.debug.assert(@hasField(Date, "zone"));

    return zoned_date.zone;
}

fn writeSecondFraction(zoned_date: anytype, writer: anytype, len: usize) !void {
    var buff: [14]u8 = undefined;

    const str = try nanoSecondStrOf(zoned_date, buff[0..]);
    const subset = str[0..@min(len, str.len)];

    try writer.writeAll(subset);

    if (subset.len < len) {
        try writer.writeByteNTimes('0', len - subset.len);
    }
}

fn writeSecond(zoned_date: anytype, writer: anytype, padding: usize) !void {
    const second = secondOf(zoned_date);
    if (padding <= 1) {
        try writer.print("{d}", .{second});
    } else {
        try writer.print("{d:0>2}", .{second});
    }
}

fn writeMinute(zoned_date: anytype, writer: anytype, padding: usize) !void {
    const minute = minuteOf(zoned_date);
    if (padding <= 1) {
        try writer.print("{d}", .{minute});
    } else {
        try writer.print("{d:0>2}", .{minute});
    }
}

fn writeHour24(zoned_date: anytype, writer: anytype, padding: usize) !void {
    if (padding <= 1) {
        try writer.print("{d}", .{hour24Of(zoned_date)});
    } else {
        try writer.print("{d:0>2}", .{hour24Of(zoned_date)});
    }
}

fn writeHour12(zoned_date: anytype, writer: anytype, padding: usize) !void {
    if (padding <= 1) {
        try writer.print("{d}", .{hour12Of(zoned_date)});
    } else {
        try writer.print("{d:0>2}", .{hour12Of(zoned_date)});
    }
}

fn nanoSecondStrOf(zoned_date: anytype, buffer: []u8) ![]const u8 {
    // Make sure we can write everything needed to the buffer
    std.debug.assert(buffer.len >= 14);

    // Make sure we won't overflow
    const nano = @min(nanoSecondOf(zoned_date), 86_400_000_000_000 - 1);

    var fbs = std.io.fixedBufferStream(buffer);

    try fbs.writer().print("{d:0>14}", .{nano});
    return fbs.getWritten();
}

fn nanoSecondOf(zoned_date: anytype) u32 {
    return timeOf(zoned_date).nano;
}

fn secondOf(zoned_date: anytype) u32 {
    const time = timeOf(zoned_date);
    return time.second;
}

fn minuteOf(zoned_date: anytype) u32 {
    const time = timeOf(zoned_date);
    return time.minute;
}

fn hour24Of(zoned_date: anytype) u32 {
    const time = timeOf(zoned_date);
    return time.hour;
}

fn hour12Of(zoned_date: anytype) u32 {
    const time = timeOf(zoned_date);
    const hour = time.hour % 12;
    if (hour == 0) {
        return 12;
    }
    return hour;
}

fn writeTimeOfDay(zoned_date: anytype, writer: anytype, t: @import("spec.zig").SegmentType) !void {
    const time = timeOf(zoned_date);

    const morn = if (time.hour < 12) true else false;

    switch (t) {
        .TimeOfDay_a_m => try writer.writeAll(if (morn) "a.m." else "p.m."),
        .TimeOfDay_ap => try writer.writeAll(if (morn) "a" else "p"),
        .TimeOfDay_am => try writer.writeAll(if (morn) "am" else "pm"),
        .TimeOfDayAM => try writer.writeAll(if (morn) "AM" else "PM"),
        else => unreachable,
    }
}

fn timeOf(zoned_date: anytype) @import("../calendars/time.zig").Segments {
    const Date = @TypeOf(zoned_date);

    var res: @import("../calendars/time.zig").Segments = undefined;
    if (!@hasDecl(Date, "Time")) {
        res = convert(zoned_date, gregorian.DateTimeZoned).time;
    } else if (Date.Time != @import("../calendars/time.zig").Segments) {
        res = convert(zoned_date, gregorian.DateTimeZoned).time;
    } else if (!@hasField(Date, "time")) {
        res = convert(zoned_date, gregorian.DateTimeZoned).time;
    } else {
        res = zoned_date.time;
    }

    res.validate() catch unreachable;
    return res;
}

fn writeDayOfWeekOf(zoned_date: anytype, writer: anytype, padding: usize) !void {
    std.debug.assert(padding <= 2);
    const day_of_week = dayOfWeekOf(u32, zoned_date);
    if (padding <= 1) {
        try writer.print("{d}", .{day_of_week});
    } else {
        try writer.print("0{d}", .{day_of_week});
    }
}

fn writeDayOfYear(zoned_date: anytype, writer: anytype, padding: usize) !void {
    const day = dayOfYearOf(u32, zoned_date);

    const out_len: usize = if (day < 10) 1 else if (day < 100) 2 else 3;

    if (out_len < padding) {
        const pad = padding - out_len;
        try writer.writeByteNTimes('0', pad);
    }

    try writer.print("{d}", .{day});
}

fn writeMonthInitial(zoned_date: anytype, writer: anytype, comptime Locale: type) !void {
    const Date = @TypeOf(zoned_date);
    const month = monthOf(u32, zoned_date);

    if (comptime std.meta.hasFn(Date, "monthFirstLetter")) {
        try writer.writeAll(Date.monthFirstLetter(month));
        return;
    }

    try Locale.monthFirstLetter(writer, month);
}

fn writeMonthLong(zoned_date: anytype, writer: anytype, comptime Locale: type) !void {
    const Date = @TypeOf(zoned_date);
    const month = monthOf(u32, zoned_date);

    if (comptime std.meta.hasFn(Date, "monthLong")) {
        try writer.writeAll(Date.monthLong(month));
        return;
    }

    try Locale.monthLong(writer, month);
}

fn writeMonthShort(zoned_date: anytype, writer: anytype, comptime Locale: type) !void {
    const Date = @TypeOf(zoned_date);
    const month = monthOf(u32, zoned_date);

    if (comptime std.meta.hasFn(Date, "monthShort")) {
        try writer.writeAll(Date.monthShort(month));
        return;
    }

    try Locale.monthShort(writer, month);
}

fn writeQuarterNum(zoned_date: anytype, writer: anytype, padding: usize) !void {
    const quarter = quarterOf(u32, zoned_date);
    if (padding <= 1) {
        try writer.print("{d}", .{quarter});
    } else {
        try writer.print("0{d}", .{quarter});
    }
}

fn writeText(text: []const u8, writer: anytype) !void {
    var force_write = false;
    for (text) |c| {
        if (c == '\\') {
            if (force_write) {
                try writer.writeByte(c);
                force_write = false;
            } else {
                force_write = true;
            }
        } else {
            force_write = false;
            try writer.writeByte(c);
        }
    }
}

fn eraDesignatorLong(zoned_date: anytype, writer: anytype, comptime Locale: type) !void {
    const year = yearOf(i32, zoned_date);
    if (year <= 0) {
        try writer.writeAll(Locale.BC_Long);
    } else {
        try writer.writeAll(Locale.AD_Long);
    }
}

fn eraDesignatorShort(zoned_date: anytype, writer: anytype, comptime Locale: type) !void {
    const year = yearOf(i32, zoned_date);
    if (year <= 0) {
        try writer.writeAll(Locale.BC_Short);
    } else {
        try writer.writeAll(Locale.AD_Short);
    }
}

fn writeWeekYear(zoned_date: anytype, writer: anytype, padding: usize) !void {
    const week = weekOf(u32, zoned_date);
    std.debug.assert(week < 100);
    const len: usize = if (week >= 10) 2 else 1;

    if (len < padding) {
        const pad = padding - len;
        try writer.writeByteNTimes('0', pad);
    }
    try writer.print("{d}", .{week});
}

fn writeSignedYear(zoned_date: anytype, writer: anytype, padding: usize) !void {
    const year = yearOf(i32, zoned_date);
    const out_len = @as(usize, @intFromFloat(@floor(std.math.log10(@as(f64, @floatFromInt(@abs(year)))))));

    if (year < 0) {
        try writer.writeByte('-');
    }

    if (out_len < padding) {
        const pad = padding - out_len - 1;
        try writer.writeByteNTimes('0', pad);
    }

    try writer.print("{d}", .{@as(u32, @intCast(@abs(year)))});
}

fn writeUnsignedYear(zoned_date: anytype, writer: anytype, padding: usize) !void {
    const year = yearOf(u32, zoned_date);
    const out_len = @as(usize, @intFromFloat(@floor(std.math.log10(@as(f64, @floatFromInt(year))))));

    if (out_len < padding) {
        const pad = padding - out_len - 1;
        try writer.writeByteNTimes('0', pad);
    }

    try writer.print("{d}", .{year});
}

fn writeMonthNum(zoned_date: anytype, writer: anytype, padding: usize) !void {
    std.debug.assert(padding <= 2);
    const month = monthOf(u32, zoned_date);
    if (month >= 10 or padding <= 1) {
        try writer.print("{d}", .{month});
    } else {
        try writer.print("0{d}", .{month});
    }
}

fn writeMonthDay(zoned_date: anytype, writer: anytype, padding: usize) !void {
    std.debug.assert(padding <= 2);
    const day = dayOfMonthOf(u32, zoned_date);
    if (day >= 10 or padding <= 1) {
        try writer.print("{d}", .{day});
    } else {
        try writer.print("0{d}", .{day});
    }
}

fn dayOfYearOf(comptime Out: type, zoned_date: anytype) Out {
    comptime std.debug.assert(Out == i32 or Out == u32);
    const Date = @TypeOf(zoned_date);
    if (Date == unix.Timestamp or Date == unix.TimestampMs) {
        return dayOfYearOf(Out, convert(zoned_date, gregorian.DateTimeZoned));
    }

    comptime std.debug.assert(@hasDecl(Date, "Date"));
    comptime std.debug.assert(@hasField(Date, "date"));

    var day: Out = undefined;
    const toOut = if (comptime Out == u32) toU32 else toI32;
    if (std.meta.hasMethod(Date, "dayNumber")) {
        day = toOut(zoned_date.date.dayNumber());
    } else if (@hasField(Date, "day_number")) {
        day = toOut(zoned_date.date.day_number);
    } else {
        day = toOut(convert(zoned_date, gregorian.Date).dayNumber());
    }
    return day;
}

fn dayOfMonthOf(comptime Out: type, zoned_date: anytype) Out {
    comptime std.debug.assert(Out == i32 or Out == u32);
    const Date = @TypeOf(zoned_date);
    if (Date == unix.Timestamp or Date == unix.TimestampMs) {
        return dayOfMonthOf(Out, convert(zoned_date, gregorian.DateTimeZoned));
    }

    comptime std.debug.assert(@hasDecl(Date, "Date"));
    comptime std.debug.assert(@hasField(Date, "date"));

    var month: Out = undefined;
    const toOut = if (comptime Out == u32) toU32 else toI32;
    if (std.meta.hasMethod(Date, "day")) {
        month = toOut(zoned_date.date.day());
    } else if (@hasField(Date, "day")) {
        month = toOut(zoned_date.date.day);
    } else {
        month = toOut(convert(zoned_date, gregorian.Date).day);
    }
    return month;
}

fn quarterOf(comptime Out: type, zoned_date: anytype) Out {
    comptime std.debug.assert(Out == i32 or Out == u32);
    const Date = @TypeOf(zoned_date);
    if (Date == unix.Timestamp or Date == unix.TimestampMs) {
        return quarterOf(Out, convert(zoned_date, gregorian.DateTimeZoned));
    }

    comptime std.debug.assert(@hasDecl(Date, "Date"));
    comptime std.debug.assert(@hasField(Date, "date"));

    var quarter: Out = undefined;
    const toOut = if (comptime Out == u32) toU32 else toI32;
    if (std.meta.hasMethod(Date, "quarter")) {
        quarter = toOut(zoned_date.date.quarter());
    } else if (@hasField(Date, "quarter")) {
        quarter = toOut(zoned_date.date.quarter);
    } else {
        const month = toOut(convert(zoned_date, gregorian.Date).month);
        if (month <= 3) {
            quarter = 1;
        } else if (month <= 6) {
            quarter = 2;
        } else if (month <= 9) {
            quarter = 3;
        } else {
            quarter = 4;
        }
    }
    return quarter;
}

fn monthOf(comptime Out: type, zoned_date: anytype) Out {
    comptime std.debug.assert(Out == i32 or Out == u32);
    const Date = @TypeOf(zoned_date);
    if (Date == unix.Timestamp or Date == unix.TimestampMs) {
        return monthOf(Out, convert(zoned_date, gregorian.DateTimeZoned));
    }

    comptime std.debug.assert(@hasDecl(Date, "Date"));
    comptime std.debug.assert(@hasField(Date, "date"));

    var month: Out = undefined;
    const toOut = if (comptime Out == u32) toU32 else toI32;
    if (std.meta.hasMethod(Date, "month")) {
        month = toOut(zoned_date.date.month());
    } else if (@hasField(Date, "month")) {
        month = toOut(zoned_date.date.month);
    } else {
        month = toOut(convert(zoned_date, gregorian.Date).month);
    }
    return month;
}

fn dayOfWeekOf(comptime Out: type, zoned_date: anytype) Out {
    comptime std.debug.assert(Out == i32 or Out == u32);
    const Date = @TypeOf(zoned_date);
    if (Date == unix.Timestamp or Date == unix.TimestampMs) {
        return dayOfWeekOf(Out, convert(zoned_date, gregorian.DateTimeZoned));
    }

    comptime std.debug.assert(@hasDecl(Date, "Date"));
    comptime std.debug.assert(@hasField(Date, "date"));

    var week_day: Out = undefined;
    const toOut = if (comptime Out == u32) toU32 else toI32;
    if (std.meta.hasMethod(Date, "dayOfWeek")) {
        week_day = toOut(zoned_date.date.dayOfWeek()) + 1;
    } else if (@hasField(Date, "dayOfWeek")) {
        week_day = toOut(zoned_date.date.dayOfWeek) + 1;
    } else {
        const c = convert(zoned_date, gregorian.DateTimeZoned);
        week_day = toOut(c.dayOfWeek()) + 1;
    }
    return week_day;
}

fn weekOf(comptime Out: type, zoned_date: anytype) Out {
    comptime std.debug.assert(Out == i32 or Out == u32);
    const Date = @TypeOf(zoned_date);
    if (Date == unix.Timestamp or Date == unix.TimestampMs) {
        return weekOf(Out, convert(zoned_date, iso.DateTimeZoned));
    }

    comptime std.debug.assert(@hasDecl(Date, "Date"));
    comptime std.debug.assert(@hasField(Date, "date"));

    var week: Out = undefined;
    const toOut = if (comptime Out == u32) toU32 else toI32;
    if (std.meta.hasMethod(Date, "week")) {
        week = toOut(zoned_date.date.week());
    } else if (@hasField(Date, "week")) {
        week = toOut(zoned_date.date.week);
    } else {
        week = toOut(convert(zoned_date, iso.Date).week);
    }
    return week;
}

fn yearOf(comptime Out: type, zoned_date: anytype) Out {
    comptime std.debug.assert(Out == i32 or Out == u32);
    const Date = @TypeOf(zoned_date);
    if (Date == unix.Timestamp or Date == unix.TimestampMs) {
        return yearOf(Out, convert(zoned_date, gregorian.DateTimeZoned));
    }

    comptime std.debug.assert(@hasDecl(Date, "Date"));
    comptime std.debug.assert(@hasField(Date, "date"));

    var year: Out = undefined;
    const toOut = if (comptime Out == u32) toU32 else toI32;
    if (std.meta.hasMethod(Date, "year")) {
        year = toOut(zoned_date.date.year());
    } else if (@hasField(Date, "year")) {
        year = toOut(zoned_date.date.year);
    } else {
        year = toOut(convert(zoned_date, gregorian.Date).year);
    }
    return year;
}

fn toI32(val: anytype) i32 {
    const FieldType = @TypeOf(val);
    const field_type_info = @typeInfo(FieldType);

    // Zig 0.13.0 use UpperCase
    // Zig 0.14.0-dev use snake_case
    // These if statements are to support both the latest stable and nightly
    if (@hasField(@TypeOf(field_type_info), "Struct")) {
        switch (field_type_info) {
            .ComptimeInt, .Int => {
                return @as(i32, @intCast(val));
            },
            .ComptimeFloat, .Float => {
                return @as(i32, @intFromFloat(val));
            },
            .Optional => {
                if (val) |v| {
                    return toI32(v);
                } else {
                    return 0;
                }
            },
            .Enum => {
                if (@TypeOf(val) == core.AstronomicalYear) {
                    return @as(i32, @intCast(
                        @intFromEnum(core.astroToAD(val) catch return 0),
                    ));
                }
                return @as(i32, @intCast(@as(i64, @intFromEnum(val))));
            },
            .Pointer => |ptr_info| switch (ptr_info.size) {
                .One => return toI32(ptr_info.child),
                else => return 0,
            },
            else => return 0,
        }
    } else {
        switch (field_type_info) {
            .comptime_int, .int => {
                return @as(i32, @intCast(val));
            },
            .comptime_float, .float => {
                return @as(i32, @intFromFloat(val));
            },
            .optional => {
                if (val) |v| {
                    return toI32(v);
                } else {
                    return 0;
                }
            },
            .@"enum" => {
                // Usually we do signed years with the astronomical system
                if (@TypeOf(val) == core.AnnoDominiYear) {
                    return @as(i32, @intCast(
                        @intFromEnum(core.adToAstro(val) catch return 0),
                    ));
                }
                return @as(i32, @intFromEnum(val));
            },
            .pointer => |ptr_info| switch (ptr_info.size) {
                .One => return toI32(ptr_info.child),
                else => return 0,
            },
            else => return 0,
        }
    }
}

fn toU32(val: anytype) u32 {
    const FieldType = @TypeOf(val);
    const field_type_info = @typeInfo(FieldType);

    // Zig 0.13.0 use UpperCase
    // Zig 0.14.0-dev use snake_case
    // These if statements are to support both the latest stable and nightly
    if (@hasField(@TypeOf(field_type_info), "Struct")) {
        switch (field_type_info) {
            .ComptimeInt, .Int => {
                return @as(u32, @intCast(@abs(val)));
            },
            .ComptimeFloat, .Float => {
                return @as(u32, @intFromFloat(@abs(val)));
            },
            .Optional => {
                if (val) |v| {
                    return toU32(v);
                } else {
                    return 0;
                }
            },
            .Enum => {
                // Usually we do unsigned years with the AD/BC system
                if (@TypeOf(val) == core.AstronomicalYear) {
                    return @as(u32, @intCast(
                        @abs(@intFromEnum(core.astroToAD(val) catch return 0)),
                    ));
                }
                return @as(u32, @intCast(@abs(@as(i64, @intFromEnum(val)))));
            },
            .Pointer => |ptr_info| switch (ptr_info.size) {
                .One => return toU32(ptr_info.child),
                else => return 0,
            },
            else => return 0,
        }
    } else {
        switch (field_type_info) {
            .comptime_int, .int => {
                return @as(u32, @intCast(@abs(val)));
            },
            .comptime_float, .float => {
                return @as(u32, @intFromFloat(@abs(val)));
            },
            .optional => {
                if (val) |v| {
                    return toU32(v);
                } else {
                    return 0;
                }
            },
            .@"enum" => {
                if (@TypeOf(val) == core.AstronomicalYear) {
                    return @as(u32, @intCast(
                        @abs(@intFromEnum(core.astroToAD(val) catch return 0)),
                    ));
                }
                return @as(u32, @intCast(@abs(@as(i64, @intFromEnum(val)))));
            },
            .pointer => |ptr_info| switch (ptr_info.size) {
                .One => return toU32(ptr_info.child),
                else => return 0,
            },
            else => return 0,
        }
    }
}

test "formatting Gregorian/Unix A.D." {
    var out: [512]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&out);
    const parseFormatStr = @import("../formatting.zig").parseFormatStr;
    const Gregorian = @import("../calendars.zig").gregorian.DateTimeZoned;
    const Unix = @import("../calendars.zig").unix.Timestamp;
    const Locale = @import("l10n.zig").EnUsLocale;

    const date = try Gregorian.init(
        try Gregorian.Date.initNums(80, 8, 24),
        try Gregorian.Time.init(16, 53, 23, 4893),
        try zone.TimeZone.init(.{ .hours = 6, .minutes = 3 }, null),
    );

    // This will be converted to UTC timezone
    const unix_date = convert(date, Unix);

    const TestCase = struct {
        format_str: []const u8,
        expected: []const u8,
        // when converting to a unix timestamp we also do a timezone conversion
        utc_expected: ?[]const u8 = null,
    };

    const tcs = [_]TestCase{
        .{ .format_str = "d-MM-YYYY G", .expected = "24-08-0080 AD" },
        .{ .format_str = "dd/YY/MM GGGG", .expected = "24/80/08 Anno Domini" },
        .{ .format_str = "y.M.dGG", .expected = "80.8.24AD" },
        .{ .format_str = "uuuuu.M.dGG", .expected = "00080.8.24AD" },
        .{
            .format_str = "ho h hh Ho H HH mo m mm so s ss",
            .expected = "4th 4 04 16th 16 16 53rd 53 53 23rd 23 23",
            .utc_expected = "10th 10 10 10th 10 10 50th 50 50 23rd 23 23",
        },
        .{ .format_str = "u Q QQ Qo D DDDD Do", .expected = "80 3 03 3rd 237 0237 237th" },
        .{
            .format_str = "O OO OOO OOOO",
            // Direct formatting gregorian should have custom timezone
            .expected = "GMT+6:03 GMT+6:03 GMT+6:03 GMT+06:03",
            // Formatting unix timestamp will be in UTC timezone
            .utc_expected = "GMT+0 GMT+0 GMT+0 GMT+00:00",
        },
        .{
            .format_str = "x xx xxx xxxx xxxxx",
            // Direct formatting gregorian should have custom timezone
            .expected = "+0603 +0603 +06:03 +0603 +06:03",
            // Formatting unix timestamp will be in UTC timezone
            .utc_expected = "+00 +0000 +00:00 +0000 +00:00",
        },
        .{
            .format_str = "P | PP | PPP | PPPP",
            .expected = "8/24/80 | Aug 24, 80 | August 24, 80 | Saturday, August 24, 80 AD",
        },
        .{
            .format_str = "p | pp | ppp | pppp",
            .expected = "4:53 PM | 4:53:23 PM | 4:53:23 PM +06:03 | 4:53:23 PM +06:03",
            .utc_expected = "10:50 AM | 10:50:23 AM | 10:50:23 AM +00:00 | 10:50:23 AM +00:00",
        },
        .{
            .format_str = "C",
            .expected = "Gregorian",
            .utc_expected = "Unix Timestamp",
        },
    };

    for (tcs) |tc| {
        {
            // gregorian
            fbs.reset();
            const fmt = try parseFormatStr(tc.format_str);
            try formatDate(&fmt, date, fbs.writer(), Locale);
            try std.testing.expectEqualStrings(tc.expected, fbs.getWritten());
        }

        {
            // unix
            fbs.reset();
            const fmt = try parseFormatStr(tc.format_str);
            try formatDate(&fmt, unix_date, fbs.writer(), Locale);
            try std.testing.expectEqualStrings(
                tc.utc_expected orelse tc.expected,
                fbs.getWritten(),
            );
        }
    }
}

test "formatting Gregorian B.C." {
    var out: [512]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&out);
    const parseFormatStr = @import("../formatting.zig").parseFormatStr;
    const Gregorian = @import("../calendars.zig").gregorian.DateTimeZoned;
    const Locale = @import("l10n.zig").EnUsLocale;

    const date = try Gregorian.init(
        try Gregorian.Date.initNums(-79, 8, 7),
        try Gregorian.Time.init(4, 53, 23, 4893),
        try zone.TimeZone.init(.{ .hours = -5, .minutes = 9, .seconds = 2 }, null),
    );
    const TestCase = struct {
        format_str: []const u8,
        expected: []const u8,
    };

    const tcs = [_]TestCase{
        .{ .format_str = "yo Yo YYYY-MM-dd G MMM MMMM MMMMM", .expected = "80th 80th 0080-08-07 BC Aug August A" },
        .{ .format_str = "do/MM/YY GG", .expected = "7th/08/80 BC" },
        .{ .format_str = "d.M.yGGGG", .expected = "7.8.80Before Christ" },
        .{ .format_str = "uuuuu.M.dGG", .expected = "-00079.8.7BC" },
        .{ .format_str = "A AA AAA AAAA AAAAA", .expected = "AM AM am a.m. a" },
        .{ .format_str = "u Q QQ Qo e ee eo aa", .expected = "-79 3 03 3rd 1 01 1st AM" },
        .{ .format_str = "eee eeee eeeee eeeeee", .expected = "Sun Sunday S Su" },
        .{
            .format_str = "SSS SSSSSSSSSSSSSS SSSSSSSSSSSSSSSSSS",
            .expected = "000 00000000004893 000000000048930000",
        },
        .{
            .format_str = "O OO OOO OOOO",
            .expected = "GMT-5:09:02 GMT-5:09:02 GMT-5:09:02 GMT-05:09:02",
        },
        .{
            .format_str = "x xx xxx xxxx xxxxx",
            .expected = "-0509 -0509 -05:09 -050902 -05:09:02",
        },
        .{
            .format_str = "P | PP | PPP | PPPP",
            .expected = "8/7/80 | Aug 7, 80 | August 7, 80 | Sunday, August 7, 80 BC",
        },
        .{
            .format_str = "p | pp | ppp | pppp",
            .expected = "4:53 AM | 4:53:23 AM | 4:53:23 AM -05:09 | 4:53:23 AM -05:09",
        },
        .{
            .format_str = "Pp | PPpp | PPPppp | PPPPpppp",
            .expected = "8/7/80, 4:53 AM | Aug 7, 80, 4:53:23 AM | August 7, 80, 4:53:23 AM -05:09 | Sunday, August 7, 80 BC, 4:53:23 AM -05:09",
        },
    };

    for (tcs) |tc| {
        fbs.reset();
        const fmt = try parseFormatStr(tc.format_str);
        try formatDate(&fmt, date, fbs.writer(), Locale);
        try std.testing.expectEqualStrings(tc.expected, fbs.getWritten());
    }
}
