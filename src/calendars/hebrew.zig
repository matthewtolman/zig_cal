const epochs = @import("epochs.zig");
const time = @import("../calendars.zig").time;
const math = @import("../utils.zig").math;
const types = @import("../utils.zig").types;
const testing = @import("std").testing;
const assert = @import("std").debug.assert;
const fixed = @import("fixed.zig");
const core = @import("core.zig");
const wrappers = @import("wrappers.zig");
const std = @import("std");

const fmt = std.fmt;
const mem = std.mem;

const AstronomicalYear = core.AstronomicalYear;
const validateAstroYear = core.validateAstroYear;
const astroToAD = core.astroToAD;
const ValidationError = core.ValidationError;

/// Represents the Hebrew months
pub const Month = enum(u8) {
    Nisan = 1,
    Iyyar = 2,
    Sivan = 3,
    Tammuz = 4,
    Av = 5,
    Elul = 6,
    Tishri = 7,
    Marheshvan = 8,
    Kislev = 9,
    Tevet = 10,
    Shevat = 11,
    Adar = 12,
    Adar_II = 13,
};

/// Represents a date on the Hebrew Calendar system.
/// This calendar is an approximation as the actual calendar is subject to
/// changes determined by religious authorities.
pub const Date = struct {
    pub const Name = "Hebrew";
    pub const Approximate = true;

    year: AstronomicalYear = @enumFromInt(0),
    month: Month = .Nisan,
    day: u8 = 1,

    /// Creates a new Hebrew date
    pub fn init(year: AstronomicalYear, month: Month, day: u8) !Date {
        const res = Date{ .year = year, .month = month, .day = day };
        try res.validate();
        return res;
    }

    /// Creates a new Hebrew date. Will convert numbers to types
    pub fn initNums(year: i32, month: i32, day: i32) !Date {
        const y: AstronomicalYear = @enumFromInt(year);
        try validateAstroYear(y);

        if (month < 1 or month > 13) {
            return ValidationError.InvalidMonth;
        }

        if (day > 30 or day < 1) {
            return ValidationError.InvalidDay;
        }

        const res = Date{
            .year = y,
            .month = @enumFromInt(month),
            .day = @as(u8, @intCast(day)),
        };

        try res.validate();
        return res;
    }

    /// Validates a date
    pub fn validate(self: Date) !void {
        if (@intFromEnum(self.month) < 1 or @intFromEnum(self.month) > 13) {
            return ValidationError.InvalidMonth;
        }

        try validateAstroYear(self.year);

        const day_max = self.daysInMonth();
        if (self.day > day_max or self.day < 1) {
            return ValidationError.InvalidDay;
        }

        const month_max = @This().lastMonthOfYear(self.year);
        if (@intFromEnum(self.month) > @intFromEnum(month_max)) {
            return ValidationError.InvalidMonth;
        }
    }

    /// Returns the number of days in a month
    fn lastDayInMonth(year: AstronomicalYear, month: Month) u8 {
        const short_days = 29;
        const long_days = 30;
        const fixed_short_month =
            month == .Iyyar or month == .Tammuz or month == .Elul or month == .Tevet or month == .Adar_II;
        if (fixed_short_month) {
            return short_days;
        }

        const short_adar = month == .Adar and !@This().leapYear(year);
        if (short_adar) {
            return short_days;
        }

        const is_long_marheshvan = month == .Marheshvan and !@This().longMarheshvanY(year);
        if (is_long_marheshvan) {
            return short_days;
        }

        const is_short_kislev = month == .Kislev and @This().shortKislevY(year);
        if (is_short_kislev) {
            return short_days;
        }

        return long_days;
    }

    /// Returns the number of days in a month
    pub fn daysInMonth(self: Date) u8 {
        return @This().lastDayInMonth(self.year, self.month);
    }

    pub fn leapYear(year: AstronomicalYear) bool {
        return math.mod(i32, 7 * @intFromEnum(year) + 1, 19) < 7;
    }

    pub fn isLeapYear(self: @This()) bool {
        return @This().leapYear(self.year);
    }

    pub fn isSabbaticalYear(self: @This()) bool {
        return math.mod(i32, @intFromEnum(self.year), 7) == 0;
    }

    pub fn molad(self: @This()) f64 {
        const month = @intFromEnum(self.month);
        const month_f: f64 = @floatFromInt(month);
        const tishri = @intFromEnum(Month.Tishri);
        const tishri_f: f64 = @floatFromInt(tishri);
        const year = self.year;
        const y = if (month < tishri) year + 1 else year;
        const y_f: f64 = @floatFromInt(y);
        const months_elapsed = month_f - tishri_f + @floor((235 * y_f - 234) / 19);
        const epoch_f: f64 = @floatFromInt(epochs.hebrew);
        return epoch_f - (876.0 / 25920.0) + months_elapsed * (29 + 12.0 / 24.0 + 793.0 / 25920.0);
    }

    pub fn daysInYears(year: AstronomicalYear) i32 {
        const nextYear = @This().newYear(@enumFromInt(@intFromEnum(year) + 1));
        const thisYear = @This().newYear(year);
        return nextYear.dayDifference(thisYear);
    }

    pub fn longMarheshvanY(year: AstronomicalYear) bool {
        const days = @This().daysInYears(year);
        return days == 355 or days == 385;
    }

    pub fn shortKislevY(year: AstronomicalYear) bool {
        const days = @This().daysInYears(year);
        return days == 353 or days == 383;
    }

    pub fn longMarheshvan(self: @This()) bool {
        return @This().longMarheshvanY(self.year);
    }

    pub fn shortKislev(self: @This()) bool {
        return @This().shortKislevY(self.year);
    }

    fn newYear(year: AstronomicalYear) fixed.Date {
        const y: i32 = @intFromEnum(year);
        const d = epochs.hebrew + @This().elapsedDays(y) + @This().yearLengthCorrection(y);
        return fixed.Date{ .day = d };
    }

    pub fn daysInYear(self: @This()) i32 {
        return @This().daysInYears(self.year);
    }

    fn elapsedDays(year: i32) i32 {
        const months_elapsed: i32 = @intFromFloat(@floor((235 * @as(f64, @floatFromInt(year)) - 234) / 19.0));
        const parts_elapsed = 204 + 793 * math.mod(i32, months_elapsed, 1080);
        const he_p1 = @as(i32, @intFromFloat(@floor(@as(f64, @floatFromInt(months_elapsed)) / 1080.0)));
        const he_p2 = 11 + 12 * months_elapsed + 793 * he_p1;
        const he_p3 = @as(i32, @intFromFloat(@floor(@as(f64, @floatFromInt(parts_elapsed)) / 1080)));
        const hours_elapsed = he_p2 + he_p3;
        const days = 29 * months_elapsed + @as(i32, @intFromFloat(@floor(@as(f64, @floatFromInt(hours_elapsed)) / 24)));
        return if (math.mod(i32, 3 * (days + 1), 7) < 3) days + 1 else days;
    }

    fn yearLengthCorrection(year: i32) i32 {
        const ny0 = @This().elapsedDays(year - 1);
        const ny1 = @This().elapsedDays(year);
        const ny2 = @This().elapsedDays(year + 1);
        if (ny2 - ny1 == 356) {
            return 2;
        } else if (ny1 - ny0 == 382) {
            return 1;
        } else {
            return 0;
        }
    }

    pub fn lastMonthOfYear(year: AstronomicalYear) Month {
        return if (@This().leapYear(year)) Month.Adar_II else Month.Adar;
    }

    pub fn fromFixedDate(date: fixed.Date) @This() {
        const approx = @as(i32, @intFromFloat(@floor((98496 * @as(f64, @floatFromInt(date.day - epochs.hebrew))) / 35975351.0))) + 1;
        var hebrew_year = approx - 1;

        var adj: i32 = 0;
        while (adj < 2 and
            //
            @This().newYear(@enumFromInt(approx + adj)).day <= date.day) : (adj += 1)
        {
            hebrew_year = approx + adj;
        }
        const hyear: AstronomicalYear = @enumFromInt(hebrew_year);

        const start = if (date.compare((@This(){ .year = hyear, .month = .Nisan, .day = 1 }).toFixedDate()) < 0) Month.Tishri else Month.Nisan;
        var hebrew_month = start;

        adj = 0;
        while (adj < 14 and
            date.day > (@This(){
            .year = hyear,
            .month = hebrew_month,
            .day = @This().lastDayInMonth(hyear, hebrew_month),
        }).toFixedDate().day) : (adj += 1) {
            hebrew_month = @enumFromInt(@as(i32, @intFromEnum(start)) + adj);
        }

        const hebrew_day = date.dayDifference((@This(){ .year = hyear, .month = hebrew_month, .day = 1 }).toFixedDate()) + 1;

        return @This(){ .year = hyear, .month = hebrew_month, .day = @intCast(hebrew_day) };
    }

    pub fn toFixedDate(self: @This()) fixed.Date {
        var calc_month: i32 = 0;
        if (@intFromEnum(self.month) < @intFromEnum(Month.Tishri)) {
            const last_month: i32 = @intFromEnum(@This().lastMonthOfYear(self.year));
            var m: i32 = @intFromEnum(Month.Tishri);
            while (m <= last_month and m > 0) : (m += 1) {
                calc_month += @intCast(lastDayInMonth(self.year, @enumFromInt(m)));
            }
            m = @intFromEnum(Month.Nisan);
            while (m < @intFromEnum(self.month) and m > 0) : (m += 1) {
                calc_month += @intCast(lastDayInMonth(self.year, @enumFromInt(m)));
            }
        } else {
            var m: i32 = @intFromEnum(Month.Tishri);
            while (m < @intFromEnum(self.month) and m > 0) : (m += 1) {
                calc_month += @intCast(lastDayInMonth(self.year, @enumFromInt(m)));
            }
        }
        return newYear(self.year).addDays(self.day - 1 + calc_month);
    }

    /// Formats Hebrew Calendar into string form
    /// Format of "s" or "u" will do human readable date string with Anno
    /// Domini year.
    ///     (e.g. March 23, 345 B.C.    April 3, 2023 A.D.)
    /// Default format (for any other format type) will do YYYY-MM-DD with
    /// astronomical year.
    /// If year is negative, will prefix date with a "-", otherwise will not
    ///     (e.g. -0344-03-23       2023-04-03)
    pub fn format(
        self: Date,
        comptime f: []const u8,
        options: fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;

        self.validate() catch {
            try writer.print("INVALID: ", .{});
        };

        if (mem.eql(u8, f, "s") or mem.eql(u8, f, "u")) {
            const y = @intFromEnum(try astroToAD(self.year));
            const month = if (self.month == .Adar_II) "Adar II" else @tagName(self.month);
            const adOrBc = if (y > 0) "A.D." else "B.C.";
            const yAbs = @as(u32, @intCast(y * std.math.sign(y)));

            try writer.print("{s} {d}, {d} {s}", .{
                month,
                self.day,
                yAbs,
                adOrBc,
            });
            return;
        }

        const y = @intFromEnum(self.year);
        const month = @intFromEnum(self.month);
        if (y >= 0) {
            try writer.print("{d:0>4}-{d:0>2}-{d:0>2}", .{
                @as(u32, @intCast(y)),
                month,
                self.day,
            });
        } else {
            try writer.print("-{d:0>4}-{d:0>2}-{d:0>2}", .{
                @as(u32, @intCast(std.math.sign(y) * y)),
                month,
                self.day,
            });
        }
    }

    /// Compares two dates
    pub fn compare(self: Date, other: Date) i32 {
        if (self.year != other.year) {
            if (@intFromEnum(self.year) > @intFromEnum(other.year)) {
                return 1;
            }
            return -1;
        }

        if (self.month != other.month) {
            if (@intFromEnum(self.month) > @intFromEnum(other.month)) {
                return 1;
            }
            return -1;
        }

        if (self.day != other.day) {
            return if (self.day > other.day) 1 else -1;
        }

        return 0;
    }

    pub fn dayInYear(self: @This()) i32 {
        const cur = @This().newYear(self.year).subDays(1);
        return self.toFixedDate().dayDifference(cur);
    }

    pub fn quarter(self: @This()) i32 {
        const dn: f64 = @floatFromInt(self.dayInYear());
        const dy: f64 = @floatFromInt(self.daysInYear());
        const year_ratio = dn / dy;
        if (year_ratio <= 0.25) {
            return 1;
        } else if (year_ratio <= 0.5) {
            return 2;
        } else if (year_ratio <= 0.75) {
            return 3;
        } else {
            return 4;
        }
    }

    pub fn week(self: @This()) i32 {
        const day = self.dayInYear();
        const s = @This().newYear(self.year);
        const adj = s.dayOfWeekOnOrBefore(.Monday).dayDifference(s);
        const d = day - adj;
        return @divFloor(d, 7) + 1;
    }

    pub usingnamespace wrappers.CalendarDayDiff(@This());
    pub usingnamespace wrappers.CalendarIsValid(@This());
    pub usingnamespace wrappers.CalendarDayMath(@This());
    pub usingnamespace wrappers.CalendarNearestValid(@This());
    pub usingnamespace wrappers.CalendarDayOfWeek(@This());
    pub usingnamespace wrappers.CalendarNthDays(@This());

    pub fn monthNameLong(self: @This()) []const u8 {
        return switch (self.month) {
            .Nisan => "נִיסָן",
            .Iyyar => "אִייָר",
            .Sivan => "סיוון",
            .Tammuz => "תַּמּוּז",
            .Av => "אָב",
            .Elul => "אֱלוּל",
            .Tishri => "תִּשׁרִי",
            .Marheshvan => "מרחשוון",
            .Kislev => "כסליו",
            .Tevet => "טֵבֵת",
            .Shevat => "שְׁבָט",
            .Adar => "אֲדָר א׳",
            .Adar_II => "אֲדָר ב׳",
        };
    }

    pub fn monthNameShort(self: @This()) []const u8 {
        return switch (self.month) {
            .Nisan => "Nisan",
            .Iyyar => "Iyyar",
            .Sivan => "Sivan",
            .Tammuz => "Tammuz",
            .Av => "Av",
            .Elul => "Elul",
            .Tishri => "Tishri",
            .Marheshvan => "Marheshvan",
            .Kislev => "Kislev",
            .Tevet => "Tevet",
            .Shevat => "Shevat",
            .Adar => "Adar I",
            .Adar_II => "Adar II",
        };
    }

    pub fn monthNameFirstLetter(self: @This()) []const u8 {
        return switch (self.month) {
            .Nisan => "N",
            .Iyyar => "I",
            .Sivan => "S",
            .Tammuz => "T",
            .Av => "A",
            .Elul => "E",
            .Tishri => "T",
            .Marheshvan => "M",
            .Kislev => "K",
            .Tevet => "T",
            .Shevat => "S",
            .Adar => "A",
            .Adar_II => "A",
        };
    }

    /// Checks if there is a dayOfWeekNameFirstLetter method
    pub fn dayOfWeekNameFirstLetter(self: @This()) bool {
        return switch (self.dayOfWeek()) {
            .Sunday, .Wednesday => "R",
            .Monday, .Tuesday, .Friday, .Saturday => "S",
            .Thursday => "H",
        };
    }

    /// Checks if there is a dayOfWeekNameFirst2Letters method
    pub fn dayOfWeekNameFirst2Letters(self: @This()) bool {
        return switch (self.dayOfWeek()) {
            .Sunday => "Ri",
            .Monday, .Tuesday, .Friday, .Saturday => "Sh",
            .Wednesday => "Re",
            .Thursday => "Ha",
        };
    }

    /// Checks if there is a dayOfWeekNameFirst2Letters method
    pub fn dayOfWeekNameShort(self: @This()) bool {
        return switch (self.dayOfWeek()) {
            .Sunday => "Rishon",
            .Monday => "Sheni",
            .Tuesday => "Shlishi",
            .Wednesday => "Revi'i",
            .Thursday => "Hamishi",
            .Friday => "Shishi",
            .Saturday => "Shabbat",
        };
    }

    /// Checks if there is a dayOfWeekNameFull method
    pub fn dayOfWeekNameFull(self: @This()) bool {
        return switch (self.dayOfWeek()) {
            .Sunday => "ראשון",
            .Monday => "שני",
            .Tuesday => "שלישי",
            .Wednesday => "רביעי",
            .Thursday => "חמישי",
            .Friday => "שישי",
            .Saturday => "שבת",
        };
    }
};

/// Represents a hebrew date and time combination
pub const DateTime = wrappers.CalendarDateTime(Date);
pub const DateTimeZoned = wrappers.CalendarDateTimeZoned(Date);

test "hebrew conversions" {
    const fixed_dates = @import("test_helpers.zig").sample_dates;

    const expected = [_]Date{
        Date{ .year = @enumFromInt(3174), .month = @enumFromInt(5), .day = 10 },
        Date{ .year = @enumFromInt(3593), .month = @enumFromInt(9), .day = 25 },
        Date{ .year = @enumFromInt(3831), .month = @enumFromInt(7), .day = 3 },
        Date{ .year = @enumFromInt(3896), .month = @enumFromInt(7), .day = 9 },
        Date{ .year = @enumFromInt(4230), .month = @enumFromInt(10), .day = 18 },
        Date{ .year = @enumFromInt(4336), .month = @enumFromInt(3), .day = 4 },
        Date{ .year = @enumFromInt(4455), .month = @enumFromInt(8), .day = 13 },
        Date{ .year = @enumFromInt(4773), .month = @enumFromInt(2), .day = 6 },
        Date{ .year = @enumFromInt(4856), .month = @enumFromInt(2), .day = 23 },
        Date{ .year = @enumFromInt(4950), .month = @enumFromInt(1), .day = 7 },
        Date{ .year = @enumFromInt(5000), .month = @enumFromInt(13), .day = 8 },
        Date{ .year = @enumFromInt(5048), .month = @enumFromInt(1), .day = 21 },
        Date{ .year = @enumFromInt(5058), .month = @enumFromInt(2), .day = 7 },
        Date{ .year = @enumFromInt(5151), .month = @enumFromInt(4), .day = 1 },
        Date{ .year = @enumFromInt(5196), .month = @enumFromInt(11), .day = 7 },
        Date{ .year = @enumFromInt(5252), .month = @enumFromInt(1), .day = 3 },
        Date{ .year = @enumFromInt(5314), .month = @enumFromInt(7), .day = 1 },
        Date{ .year = @enumFromInt(5320), .month = @enumFromInt(12), .day = 27 },
        Date{ .year = @enumFromInt(5408), .month = @enumFromInt(3), .day = 20 },
        Date{ .year = @enumFromInt(5440), .month = @enumFromInt(4), .day = 3 },
        Date{ .year = @enumFromInt(5476), .month = @enumFromInt(5), .day = 5 },
        Date{ .year = @enumFromInt(5528), .month = @enumFromInt(4), .day = 4 },
        Date{ .year = @enumFromInt(5579), .month = @enumFromInt(5), .day = 11 },
        Date{ .year = @enumFromInt(5599), .month = @enumFromInt(1), .day = 12 },
        Date{ .year = @enumFromInt(5663), .month = @enumFromInt(1), .day = 22 },
        Date{ .year = @enumFromInt(5689), .month = @enumFromInt(5), .day = 19 },
        Date{ .year = @enumFromInt(5702), .month = @enumFromInt(7), .day = 8 },
        Date{ .year = @enumFromInt(5703), .month = @enumFromInt(1), .day = 14 },
        Date{ .year = @enumFromInt(5704), .month = @enumFromInt(7), .day = 8 },
        Date{ .year = @enumFromInt(5752), .month = @enumFromInt(13), .day = 12 },
        Date{ .year = @enumFromInt(5756), .month = @enumFromInt(12), .day = 5 },
        Date{ .year = @enumFromInt(5799), .month = @enumFromInt(8), .day = 12 },
        Date{ .year = @enumFromInt(5854), .month = @enumFromInt(5), .day = 5 },
    };

    assert(fixed_dates.len == expected.len);

    const timeSegment = try time.Segments.init(12, 0, 0, 0);

    for (fixed_dates, expected) |fixedDate, e| {
        // Test convertintg to fixed
        const actualFixed = e.toFixedDate();
        try testing.expectEqual(fixedDate.day, actualFixed.day);

        // Test converting from fixed
        const actualGreg = Date.fromFixedDate(fixedDate);
        try testing.expect(0 == actualGreg.compare(e));

        const fixedDateTime = fixed.DateTime{
            .date = fixedDate,
            .time = timeSegment,
        };
        const actualGregTime = DateTime.fromFixedDateTime(fixedDateTime);
        try testing.expectEqual(0, actualGregTime.date.compare(e));

        const actualFixedTime = actualGregTime.toFixedDateTime();
        try testing.expectEqualDeep(fixedDateTime, actualFixedTime);
    }
}

test "hebrew day of year" {
    for (0..300) |i| {
        const y: AstronomicalYear = @enumFromInt(i);
        const d1 = Date.fromFixedDate(Date.newYear(y));
        try std.testing.expectEqual(1, d1.dayInYear());
        try std.testing.expectEqual(1, Date.fromFixedDate(Date.newYear(y)).week());
        const e = Date.daysInYears(y);
        const d2 = d1.addDays(e - 1);
        try std.testing.expectEqual(Month.Elul, d2.month);
        try std.testing.expectEqual(e, d2.dayInYear());
        const w = @divFloor(e, 7);
        try std.testing.expect(@abs(w - d2.week()) <= 2);
        try std.testing.expectEqual(4, d2.quarter());
    }
}

test "hebrew format" {
    const features = @import("../utils/features.zig");
    const grade = features.gradeDateFormatting(Date);
    try std.testing.expectEqual(
        features.CalendarFormattingRating.Complete,
        grade.month.rating,
    );
    try std.testing.expectEqual(
        features.CalendarFormattingRating.Complete,
        grade.day_of_week.rating,
    );
    try std.testing.expectEqual(
        features.CalendarFormattingRating.Complete,
        grade.named,
    );
}

test "hebrew grade" {
    const features = @import("../utils/features.zig");
    const grade = features.gradeDate(Date);
    try std.testing.expectEqual(features.CalendarRating.Recommended, grade.rating);
}

test "hebrew datetime grade" {
    const features = @import("../utils/features.zig");
    const grade = features.gradeDateTime(DateTime);
    try std.testing.expectEqual(features.CalendarRating.Recommended, grade.rating);
}

test "hebrew datetimezoned grade" {
    const features = @import("../utils/features.zig");
    const grade = features.gradeDateTimeZoned(DateTimeZoned);
    try std.testing.expectEqual(features.CalendarRating.Recommended, grade.rating);
}
