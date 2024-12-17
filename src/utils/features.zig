const std = @import("std");
const time = @import("../calendars/time.zig");
const core = @import("../calendars/core.zig");
const unix = @import("../calendars/unix_timestamp.zig");

/// Features possible for a calendar
pub const Features = enum {
    // REQUIRED for ALL types (Date, DateTime, DateTimeZoned)

    /// Has validate(self: @This()) !void method
    Validate,
    /// Has compare(left: @This(), right: @This()) i32 method
    Compare,

    // REQUIRED for Date types

    /// Has toFixedDate(self: @This()) fixed.Date
    ToFixedDate,
    /// Has fromFixedDate(date: fixed.Date) @This()
    FromFixedDate,

    // REQUIRED for Date Time types

    /// Has toFixedDateTime(self: @This()) fixed.DateTime
    ToFixedDateTime,
    /// Has fromFixedDateTime(date: fixed.DateTime) @This()
    FromFixedDateTime,

    // REQUIRED for Zoned Date Time types

    /// Has toFixedDateTimeZoned(self: @This()) fixedDateTimeZoned
    ToFixedDateTimeZoned,
    /// Has fromFixedDateTimeZoned(date: fixed.DateTime) @This()
    FromFixedDateTimeZoned,
    /// Has toUtc(self: @This()) self()
    ToUtc,
    /// Has toTimezone(self: @This(), zone.TimeZone) @This()
    ToTimezone,
    /// Creates from a Date Time and timezone
    /// pub fn fromDateTime(dt: @This().DateTime, tz: TimeZone) @This()
    FromDateTime,
    /// Convert to target timezone and return time zone
    /// pub fn toDateTime(self: @This(), tz: TimeZone) @This().DateTime
    ToDateTime,

    // OPTIONAL but RECOMMENDED

    /// Calendar name for date formating
    /// Recommended for all dates
    /// Public constant of type []const u8
    Named,
    /// Debug formatting
    DebugFormat,
    /// Has dayDifference(left: @This(), right: @This()) i32 method
    DayDifference,
    /// Has addDays(left: @This(), n: i32) @This() method
    AddDays,
    /// Has subDays(left: @This(), n: i32) @This() method
    SubDays,

    /// Has isValid(self: @This()) bool method
    IsValid,
    /// Has nearestValid(self: @This()) @This() method
    NearestValid,

    /// Has nthWeekDay(self: @This(), n: i32, k: DayOfWeek) method
    NthWeekDay,
    /// Has dayOfWeekBefore(self: @This(), k: DayOfWeek) method
    DayOfWeekBefore,
    /// Has dayOfWeekAfter(self: @This(), k: DayOfWeek) method
    DayOfWeekAfter,
    /// Has dayOfWeekNearest(self: @This(), k: DayOfWeek) method
    DayOfWeekNearest,
    /// Has dayOfWeekOnOrBefore(self: @This(), k: DayOfWeek) method
    DayOfWeekOnOrBefore,
    /// Has dayOfWeekOnOrAfter(self: @This(), k: DayOfWeek) method
    DayOfWeekOnOrAfter,
    /// Has firstWeekDay(self: @This(), k: DayOfWeek) method
    FirstWeekDay,
    /// Has lastWeekDay(self: @This(), k: DayOfWeek) method
    LastWeekDay,

    // OPTIONAL, for formatting customization

    /// Custom day of week formatting
    /// pub fn dayOfWeekNameFull(self: @This()) []const u8
    CustomDayOfWeekFull,
    /// Custom day of week formatting
    /// pub fn dayOfWeekNameShort(self: @This()) []const u8
    CustomDayOfWeekShort,
    /// Custom day of week formatting
    /// pub fn dayOfWeekNameFirstLetter(self: @This()) []const u8
    CustomDayOfWeekFirstLetter,
    /// Custom day of week formatting
    /// pub fn dayOfWeekNameFirst2Letters(self: @This()) []const u8
    CustomDayOfWeekFirst2Letters,

    /// Custom day of month formatting
    /// pub fn monthNameFirstLetter(self: @This()) []const u8
    CustomMonthFirstLetter,
    /// Custom day of month formatting
    /// pub fn monthNameLong(self: @This()) []const u8
    CustomMonthLong,
    /// Custom day of month formatting
    /// pub fn monthNameShort(self: @This()) []const u8
    CustomMonthShort,

    // Informational

    /// Time is expressed using zcal.time.Segments
    /// RECOMENDED when HasTime is present
    TimeSegment,
    /// Time is expressed using zcal.time.DayFraction
    TimeDayFraction,
    /// Time is expressed using zcal.time.NanoSeconds
    TimeNanoSeconds,

    /// Year is expressed with zcal.calendar.AstronomicalYear
    AstronomicalYear,
    /// Year is expressed with zcal.calendar.AnnoDominiYear
    AnnoDominiYear,

    /// Has either year field or year() method
    /// RECOMENDED when not compatible with Gregorian Date
    HasYear,
    /// Has either month field or month() method
    /// RECOMENDED when not compatible with Gregorian Date
    HasMonth,
    /// Has either day field or day() method
    /// RECOMENDED when not compatible with Gregorian Date
    HasDayOfMonth,
    /// Has Zone constant and zone field
    /// REQUIRED for DateTimeZoned
    HasZone,
    /// Has Time constant and time field
    /// REQUIRED for DateTime and DateTimeZoned
    HasTime,
    /// Has Date constant and date field
    /// REQUIRED for DateTime and DateTimeZoned
    HasDate,
    /// Has either week field or week() method
    /// RECOMENDED when not compatible with ISO Date
    HasWeekOfYear,
    /// Has either day_in_year field or dayInYear() method
    /// RECOMENDED when not compatible with Gregorian Date
    HasDayOfYear,
    /// Has either day_of_week field or dayOfWeek() method
    HasDayOfWeek,
    /// Has either quarter field or quarter() method
    /// RECOMENDED when not compatible with Gregorian Date
    HasQuarter,

    /// Indicates that calendar is an approximation
    /// and that the actual dates may vary based on external factors
    IsApproximate,

    // Special Handling

    /// Type is a unix timestamp
    UnixSeconds,
    /// Type is a unix timestamp with ms
    UnixMilliSeconds,
};

/// Feature set which represents capabilities and information of a Calendar
pub const FeatureSet = std.enums.EnumSet(Features);

/// Creates a feature set for a calendar type
pub fn featureSet(comptime Calendar: type) FeatureSet {
    var set = FeatureSet.initEmpty();

    if (hasName(Calendar)) set.insert(Features.Named);

    if (hasZone(Calendar)) set.insert(Features.HasZone);
    if (hasTime(Calendar)) set.insert(Features.HasTime);
    if (hasDate(Calendar)) set.insert(Features.HasDate);

    if (hasDayOfWeekNameFull(Calendar)) set.insert(Features.CustomDayOfWeekFull);
    if (hasDayOfWeekNameShort(Calendar)) set.insert(Features.CustomDayOfWeekShort);
    if (hasDayOfWeekNameFirstLetter(Calendar)) set.insert(Features.CustomDayOfWeekFirstLetter);
    if (hasDayOfWeekNameFirst2Letters(Calendar)) set.insert(Features.CustomDayOfWeekFirst2Letters);

    if (hasMonthNameFirstLetter(Calendar)) set.insert(Features.CustomMonthFirstLetter);
    if (hasMonthNameLong(Calendar)) set.insert(Features.CustomMonthLong);
    if (hasMonthNameShort(Calendar)) set.insert(Features.CustomMonthShort);

    if (hasDayOfYear(Calendar)) set.insert(Features.HasDayOfYear);
    if (hasDayOfMonth(Calendar)) set.insert(Features.HasDayOfMonth);
    if (hasMonth(Calendar)) set.insert(Features.HasMonth);
    if (hasQuarter(Calendar)) set.insert(Features.HasQuarter);
    if (hasDayOfWeek(Calendar)) set.insert(Features.HasDayOfWeek);
    if (hasWeek(Calendar)) set.insert(Features.HasWeekOfYear);
    if (hasYear(Calendar)) set.insert(Features.HasYear);

    if (hasTimeSegments(Calendar)) set.insert(Features.TimeSegment);
    if (hasTimeDayFraction(Calendar)) set.insert(Features.TimeDayFraction);
    if (hasTimeNanoSeconds(Calendar)) set.insert(Features.TimeNanoSeconds);

    if (hasAstronomicalYear(Calendar)) set.insert(Features.AstronomicalYear);
    if (hasAnnoDominiYear(Calendar)) set.insert(Features.AnnoDominiYear);

    if (hasDayDifference(Calendar)) set.insert(Features.DayDifference);
    if (hasAddDays(Calendar)) set.insert(Features.AddDays);
    if (hasSubDays(Calendar)) set.insert(Features.SubDays);

    if (hasIsValid(Calendar)) set.insert(Features.IsValid);
    if (hasValidate(Calendar)) set.insert(Features.Validate);
    if (hasNearestValid(Calendar)) set.insert(Features.NearestValid);

    if (hasNthWeekDay(Calendar)) set.insert(Features.NthWeekDay);
    if (hasDayOfWeekBefore(Calendar)) set.insert(Features.DayOfWeekBefore);
    if (hasDayOfWeekAfter(Calendar)) set.insert(Features.DayOfWeekAfter);
    if (hasDayOfWeekNearest(Calendar)) set.insert(Features.DayOfWeekNearest);
    if (hasDayOfWeekOnOrBefore(Calendar)) set.insert(Features.DayOfWeekOnOrBefore);
    if (hasDayOfWeekOnOrAfter(Calendar)) set.insert(Features.DayOfWeekOnOrAfter);
    if (hasFirstWeekDay(Calendar)) set.insert(Features.FirstWeekDay);
    if (hasLastWeekDay(Calendar)) set.insert(Features.LastWeekDay);

    if (hasCompare(Calendar)) set.insert(Features.Compare);

    if (hasToFixedDate(Calendar)) set.insert(Features.ToFixedDate);
    if (hasFromFixedDate(Calendar)) set.insert(Features.FromFixedDate);

    if (hasToFixedDateTime(Calendar)) set.insert(Features.ToFixedDateTime);
    if (hasFromFixedDateTime(Calendar)) set.insert(Features.FromFixedDateTime);

    if (hasDebugFormat(Calendar)) set.insert(Features.DebugFormat);
    if (hasToFixedDateTimeZoned(Calendar)) set.insert(Features.ToFixedDateTimeZoned);
    if (hasFromFixedDateTimeZoned(Calendar)) set.insert(Features.FromFixedDateTimeZoned);
    if (hasToUtc(Calendar)) set.insert(Features.ToUtc);
    if (hasToTimezone(Calendar)) set.insert(Features.ToTimezone);

    if (hasFromDateTime(Calendar)) set.insert(Features.FromDateTime);
    if (hasToDateTime(Calendar)) set.insert(Features.ToDateTime);

    if (isUnixTimestampSeconds(Calendar)) set.insert(Features.UnixSeconds);
    if (isUnixTimestampMilliSeconds(Calendar)) set.insert(Features.UnixMilliSeconds);

    if (isApproximate(Calendar)) set.insert(Features.IsApproximate);

    return set;
}

test "feature set gregorian date" {
    const Greg = @import("../calendars/gregorian.zig").Date;
    const features = featureSet(Greg);
    try std.testing.expect(features.contains(.Named));
    try std.testing.expect(features.contains(.HasDayOfYear));
    try std.testing.expect(features.contains(.HasDayOfMonth));
    try std.testing.expect(features.contains(.HasMonth));
    try std.testing.expect(features.contains(.HasQuarter));
    try std.testing.expect(features.contains(.HasDayOfWeek));
    try std.testing.expect(features.contains(.HasYear));
    try std.testing.expect(features.contains(.AstronomicalYear));
}

const FeatureStruct = std.enums.EnumFieldStruct(Features, bool, false);

/// Required features for dates to work
pub const date_required = FeatureSet.init(
    FeatureStruct{
        .Validate = true,
        .Compare = true,
        .ToFixedDate = true,
        .FromFixedDate = true,
    },
);

/// Bare essentials for dates to be usable
pub const date_essentials = FeatureSet.init(
    FeatureStruct{
        .Named = true,
        .DayDifference = true,
        .AddDays = true,
        .SubDays = true,
        .IsValid = true,
        .NearestValid = true,
        .NthWeekDay = true,
        .DayOfWeekBefore = true,
        .DayOfWeekAfter = true,
        .DayOfWeekNearest = true,
        .DayOfWeekOnOrBefore = true,
        .DayOfWeekOnOrAfter = true,
    },
);

/// Guarantees correct functionality with implicit conversions
pub const date_recommended = FeatureSet.init(
    FeatureStruct{
        .HasYear = true,
        .DebugFormat = true,
        .HasMonth = true,
        .HasDayOfMonth = true,
        .HasWeekOfYear = true,
        .HasDayOfYear = true,
        .HasQuarter = true,
    },
);

/// Required features for date times to work
pub const date_time_required = FeatureSet.init(
    FeatureStruct{
        .Validate = true,
        .Compare = true,
        .ToFixedDateTime = true,
        .FromFixedDateTime = true,
        .HasDate = true,
        .HasTime = true,
    },
);

/// Bare essentials for date times to be usable
pub const date_time_essentials = FeatureSet.init(
    FeatureStruct{
        .Named = true,
        .DayDifference = true,
        .AddDays = true,
        .SubDays = true,
        .IsValid = true,
        .NearestValid = true,
        .NthWeekDay = true,
        .DayOfWeekBefore = true,
        .DayOfWeekAfter = true,
        .DayOfWeekNearest = true,
        .DayOfWeekOnOrBefore = true,
        .DayOfWeekOnOrAfter = true,
    },
);

/// Guarantees correct functionality with implicit conversions
pub const date_time_recommended = FeatureSet.init(
    FeatureStruct{
        .DebugFormat = true,
        .TimeSegment = true,
    },
);

/// Required features for date times to work
pub const date_time_zoned_required = FeatureSet.init(
    FeatureStruct{
        .Validate = true,
        .Compare = true,
        .ToFixedDateTimeZoned = true,
        .FromFixedDateTimeZoned = true,
        .HasDate = true,
        .HasTime = true,
        .HasZone = true,
        .ToUtc = true,
        .ToTimezone = true,
        .FromDateTime = true,
        .ToDateTime = true,
    },
);

/// Bare essentials for date times to be usable
pub const date_time_zoned_essentials = FeatureSet.init(
    FeatureStruct{
        .Named = true,
        .DayDifference = true,
        .AddDays = true,
        .SubDays = true,
        .IsValid = true,
        .NearestValid = true,
        .NthWeekDay = true,
        .DayOfWeekBefore = true,
        .DayOfWeekAfter = true,
        .DayOfWeekNearest = true,
        .DayOfWeekOnOrBefore = true,
        .DayOfWeekOnOrAfter = true,
    },
);

/// Guarantees correct functionality with implicit conversions
pub const date_time_zoned_recommended = FeatureSet.init(
    FeatureStruct{
        .DebugFormat = true,
        .TimeSegment = true,
    },
);

/// Rating for a calendar
pub const CalendarRating = enum {
    /// Represents when required minimums are not reached
    Incomplete,
    /// Represents only a bare minimum is reached
    Bare,
    /// Represents that usability essentials are reached
    Essentials,
    /// Represents that correctness recommendations are reached
    Recommended,
};

/// Calendar grade with recommendations to improve Date support
pub const CalendarDateGrade = struct {
    cal_name: []const u8,
    rating: CalendarRating = .Incomplete,
    feature_set: FeatureSet,
    next_level: FeatureSet = FeatureSet.initEmpty(),

    pub fn format(
        self: @This(),
        comptime f: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = f;

        try writer.print(
            "\n==============\nCal Date: {s}\nGRADE: {s}\n",
            .{ self.cal_name, @tagName(self.rating) },
        );
        try writer.writeAll("NEXT LEVEL:");

        if (self.next_level.count() == 0) {
            try writer.writeAll(" NONE\n");
        } else {
            try writer.writeByte('\n');
            var it = self.next_level.iterator();
            while (it.next()) |nl| {
                try writer.print("\t{s}\n", .{@tagName(nl)});
            }
        }

        try writer.writeAll("\nFEATURES:\n");

        var it = self.feature_set.iterator();
        while (it.next()) |nl| {
            try writer.print("\t{s}\n", .{@tagName(nl)});
        }
        try writer.writeAll("==============\n");
    }
};

/// Calendar grade with recommendations to improve DateTime support
pub const CalendarDateTimeGrade = struct {
    cal_name: []const u8,
    rating: CalendarRating = .Incomplete,
    date_grade: ?CalendarDateGrade = null,
    feature_set: FeatureSet,
    next_level: FeatureSet = FeatureSet.initEmpty(),

    pub fn format(
        self: @This(),
        comptime f: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print(
            "\n==============\nCal DateTime: {s}\nGRADE: {s}\n",
            .{ self.cal_name, @tagName(self.rating) },
        );
        try writer.writeAll("NEXT LEVEL:");

        if (self.next_level.count() == 0) {
            try writer.writeAll(" NONE\n");
        } else {
            try writer.writeByte('\n');
            var it = self.next_level.iterator();
            while (it.next()) |nl| {
                try writer.print("\t{s}\n", .{@tagName(nl)});
            }
        }

        try writer.writeAll("\nFEATURES:\n");

        var it = self.feature_set.iterator();
        while (it.next()) |nl| {
            try writer.print("\t{s}\n", .{@tagName(nl)});
        }

        if (self.date_grade) |dg| {
            try dg.print(self, f, options, writer);
        } else {
            try writer.writeAll("NO DATE\n");
        }

        try writer.writeAll("==============\n");
    }
};

/// Calendar grade with recommendations to improve DateTimeZoned support
pub const CalendarDateTimeZoneGrade = struct {
    cal_name: []const u8,
    rating: CalendarRating = .Incomplete,
    date_grade: ?CalendarDateGrade = null,
    feature_set: FeatureSet,
    next_level: FeatureSet = FeatureSet.initEmpty(),

    pub fn format(
        self: @This(),
        comptime f: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print(
            "\n==============\nCal DateTimeZone: {s}\nGRADE: {s}\n",
            .{ self.cal_name, @tagName(self.rating) },
        );
        try writer.writeAll("NEXT LEVEL:");

        if (self.next_level.count() == 0) {
            try writer.writeAll(" NONE\n");
        } else {
            try writer.writeByte('\n');
            var it = self.next_level.iterator();
            while (it.next()) |nl| {
                try writer.print("\t{s}\n", .{@tagName(nl)});
            }
        }

        try writer.writeAll("\nFEATURES:\n");

        var it = self.feature_set.iterator();
        while (it.next()) |nl| {
            try writer.print("\t{s}\n", .{@tagName(nl)});
        }

        if (self.date_grade) |dg| {
            try dg.print(self, f, options, writer);
        } else {
            try writer.writeAll("NO DATE\n");
        }

        try writer.writeAll("==============\n");
    }
};

/// Useful properties for overriding day of week formatter output
pub const day_of_week_formatting = FeatureSet.init(
    FeatureStruct{
        .CustomDayOfWeekFull = true,
        .CustomDayOfWeekShort = true,
        .CustomDayOfWeekFirstLetter = true,
        .CustomDayOfWeekFirst2Letters = true,
    },
);

/// Useful properties for overriding day of week formatter output
pub const month_formatting = FeatureSet.init(
    FeatureStruct{
        .CustomMonthFirstLetter = true,
        .CustomMonthLong = true,
        .CustomMonthShort = true,
    },
);

/// Useful properties for overriding day of week formatter output
pub const name_formatting = FeatureSet.init(
    FeatureStruct{
        .Named = true,
    },
);

pub const CalendarFormattingRating = enum { Incomplete, Deferred, Complete };

pub const CalendarFormatSubGrade = struct {
    rating: CalendarFormattingRating = .Deferred,
    missing: FeatureSet = FeatureSet.initEmpty(),

    pub fn format(
        self: @This(),
        comptime f: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = f;
        _ = options;
        try writer.print(
            "\n--------------\nGRADE: {s}\n",
            .{@tagName(self.rating)},
        );
        try writer.writeAll("MISSING:");

        if (self.missing.count() == 0) {
            try writer.writeAll(" NONE\n");
        } else {
            try writer.writeByte('\n');
            var it = self.missing.iterator();
            while (it.next()) |nl| {
                try writer.print("\t{s}\n", .{@tagName(nl)});
            }
        }

        try writer.writeAll("--------------\n");
    }
};

pub const CalendarFormattingGrade = struct {
    day_of_week: CalendarFormatSubGrade = .{},
    month: CalendarFormatSubGrade = .{},
    named: CalendarFormattingRating = .Incomplete,
    feature_set: FeatureSet,
    cal_name: []const u8,

    pub fn format(
        self: @This(),
        comptime f: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = f;
        _ = options;
        try writer.print(
            "\n==============\nCalendar: {s}\n",
            .{self.cal_name},
        );

        try writer.print("Named: {s}\n", .{@tagName(self.named)});
        try writer.print("Month: {}\n", .{self.month});
        try writer.print("Day Of Week: {}\n", .{self.day_of_week});
        try writer.writeAll("==============\n");
    }
};

pub fn gradeDateFormatting(comptime Cal: type) CalendarFormattingGrade {
    var res = CalendarFormattingGrade{
        .feature_set = featureSet(Cal),
        .cal_name = @typeName(Cal),
    };

    const missing_day_of_week = day_of_week_formatting.differenceWith(res.feature_set);
    res.day_of_week.missing = missing_day_of_week;
    if (missing_day_of_week.eql(day_of_week_formatting)) {
        res.day_of_week.rating = .Deferred;
    } else if (missing_day_of_week.count() != 0) {
        res.day_of_week.rating = .Incomplete;
    } else {
        res.day_of_week.rating = .Complete;
    }

    const missing_month = month_formatting.differenceWith(res.feature_set);
    res.month.missing = missing_month;
    if (missing_month.eql(month_formatting)) {
        res.month.rating = .Deferred;
    } else if (missing_month.count() != 0) {
        res.month.rating = .Incomplete;
    } else {
        res.month.rating = .Complete;
    }

    if (res.feature_set.contains(.Named)) {
        res.named = .Complete;
    } else {
        res.named = .Incomplete;
    }

    return res;
}

/// Grades a calendar's suitability as a Date
pub fn gradeDate(comptime Cal: type) CalendarDateGrade {
    var res = CalendarDateGrade{
        .cal_name = @typeName(Cal),
        .rating = .Incomplete,
        .feature_set = featureSet(Cal),
    };
    const missing_req = date_required.differenceWith(res.feature_set);
    if (missing_req.count() != 0) {
        res.next_level = missing_req;
        return res;
    }

    res.rating = .Bare;
    const missing_essentials = date_essentials.differenceWith(res.feature_set);
    if (missing_essentials.count() != 0) {
        res.next_level = missing_essentials;
        return res;
    }

    res.rating = .Essentials;
    const missing_recommended = date_recommended.differenceWith(res.feature_set);
    if (missing_recommended.count() != 0) {
        res.next_level = missing_recommended;
        return res;
    }

    res.rating = .Recommended;
    return res;
}

/// Grades a calendar's suitability as a DateTime
pub fn gradeDateTime(comptime Cal: type) CalendarDateTimeGrade {
    var res = CalendarDateTimeGrade{
        .cal_name = @typeName(Cal),
        .rating = .Incomplete,
        .feature_set = featureSet(Cal),
    };

    defer {
        if (!hasTime(Cal)) {
            res.rating = .Incomplete;
            res.next_level.insert(.HasTime);
            res.next_level.insert(.TimeSegment);
        }

        if (hasDate(Cal)) {
            res.date_grade = gradeDate(Cal.Date);
            res.rating = @enumFromInt(@min(
                @intFromEnum(res.rating),
                @intFromEnum(res.date_grade.?.rating),
            ));
        } else {
            res.rating = .Incomplete;
            res.next_level.insert(.HasDate);
        }

        if (res.rating == .Recommended) {
            if (!hasTimeSegments(Cal)) {
                res.rating = .Essentials;
                res.next_level.insert(.TimeSegment);
            }
        }
    }

    const missing_req = date_time_required.differenceWith(res.feature_set);
    if (missing_req.count() != 0) {
        res.next_level = missing_req;
        return res;
    }

    res.rating = .Bare;
    const missing_essentials = date_time_essentials.differenceWith(
        res.feature_set,
    );
    if (missing_essentials.count() != 0) {
        res.next_level = missing_essentials;
        return res;
    }

    res.rating = .Essentials;
    const missing_recommended = date_time_recommended.differenceWith(
        res.feature_set,
    );
    if (missing_recommended.count() != 0) {
        res.next_level = missing_recommended;
        return res;
    }

    res.rating = .Recommended;
    return res;
}

/// Grades a calendar's suitability as a DateTimeZoned
pub fn gradeDateTimeZoned(comptime Cal: type) CalendarDateTimeZoneGrade {
    var res = CalendarDateTimeZoneGrade{
        .cal_name = @typeName(Cal),
        .rating = .Incomplete,
        .feature_set = featureSet(Cal),
    };

    defer {
        if (!hasTime(Cal)) {
            res.rating = .Incomplete;
            res.next_level.insert(.HasTime);
            res.next_level.insert(.TimeSegment);
        }

        if (hasDate(Cal)) {
            res.date_grade = gradeDate(Cal.Date);
            res.rating = @enumFromInt(@min(
                @intFromEnum(res.rating),
                @intFromEnum(res.date_grade.?.rating),
            ));
        } else {
            res.rating = .Incomplete;
            res.next_level.insert(.HasDate);
        }

        if (res.rating == .Recommended) {
            if (!hasTimeSegments(Cal)) {
                res.rating = .Essentials;
                res.next_level.insert(.TimeSegment);
            }
        }
    }

    const missing_req = date_time_zoned_required.differenceWith(
        res.feature_set,
    );
    if (missing_req.count() != 0) {
        res.next_level = missing_req;
        return res;
    }

    res.rating = .Bare;
    const missing_essentials = date_time_zoned_essentials.differenceWith(
        res.feature_set,
    );
    if (missing_essentials.count() != 0) {
        res.next_level = missing_essentials;
        return res;
    }

    res.rating = .Essentials;
    const missing_recommended = date_time_zoned_recommended.differenceWith(
        res.feature_set,
    );
    if (missing_recommended.count() != 0) {
        res.next_level = missing_recommended;
        return res;
    }

    res.rating = .Recommended;
    return res;
}

/// Returns if a calendar type is a date
pub fn isDate(comptime Cal: type) bool {
    const features = featureSet(Cal);
    return date_required.subsetOf(features);
}

/// Returns if a calendar type is a date time
pub fn isDateTime(comptime Cal: type) bool {
    const features = featureSet(Cal);
    return date_time_required.subsetOf(features);
}

/// Returns if a calendar type is a date time zoned
pub fn isDateTimeZoned(comptime Cal: type) bool {
    const features = featureSet(Cal);
    return date_time_zoned_required.subsetOf(features);
}

/// Returns if a calendar is a unix timestamp (seconds or milliseconds)
pub fn isUnixTimestamp(comptime Cal: type) bool {
    return isUnixTimestampSeconds(Cal) or isUnixTimestampMilliSeconds(Cal);
}

/// Returns if a calendar is a unix timestamp in milliseconds
pub fn isUnixTimestampMilliSeconds(comptime Cal: type) bool {
    return comptime Cal == unix.TimestampMs;
}

/// Returns if a calendar is a unix timestamp in seconds
pub fn isUnixTimestampSeconds(comptime Cal: type) bool {
    return comptime Cal == unix.Timestamp;
}

/// Checks if there is a toDateTime method
pub fn hasToDateTime(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "toDateTime");
}

/// Checks if there is a fromDateTime method
pub fn hasFromDateTime(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "fromDateTime");
}

/// Checks if there is a toTimezone method
pub fn hasToTimezone(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "toTimezone");
}

/// Checks if there is a toUtc method
pub fn hasToUtc(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "toUtc");
}

/// Checks if there is a fromFixedDateTimeZoned method
pub fn hasFromFixedDateTimeZoned(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "fromFixedDateTimeZoned");
}

/// Checks if there is a toFIxedDateTimeZoned method
pub fn hasToFixedDateTimeZoned(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "toFixedDateTimeZoned");
}

/// Checks if there is a format function (for debugging)
pub fn hasDebugFormat(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "format");
}

/// Checks if there is a fromFixedDateTime function
pub fn hasFromFixedDateTime(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "fromFixedDateTime");
}

/// Checks if there is a toFixedDateTime function
pub fn hasToFixedDateTime(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "toFixedDateTime");
}

/// Checks if there is a fromFixedDate function
pub fn hasFromFixedDate(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "fromFixedDate");
}

/// Checks if there is a toFixedDate function
pub fn hasToFixedDate(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "toFixedDate");
}

/// Checks if there is a compare method
pub fn hasCompare(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "compare");
}

/// Checks if there is a lastWeekDay method
pub fn hasLastWeekDay(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "lastWeekDay");
}

/// Checks if there is a firstWeekDay method
pub fn hasFirstWeekDay(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "firstWeekDay");
}

/// Checks if there is a dayOfWeekOnOrAfter method
pub fn hasDayOfWeekOnOrAfter(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "dayOfWeekOnOrAfter");
}

/// Checks if there is a dayOfWeekOnOrBefore method
pub fn hasDayOfWeekOnOrBefore(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "dayOfWeekOnOrBefore");
}

/// Checks if there is a dayOfWeekNearest method
pub fn hasDayOfWeekNearest(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "dayOfWeekNearest");
}

/// Checks if there is a dayOfWeekAfter method
pub fn hasDayOfWeekAfter(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "dayOfWeekAfter");
}

/// Checks if there is a dayOfWeekBefore method
pub fn hasDayOfWeekBefore(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "dayOfWeekBefore");
}

/// Checks if there is a nthWeekDay method
pub fn hasNthWeekDay(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "nthWeekDay");
}

/// Checks if there is a nearestValid method
pub fn hasNearestValid(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "nearestValid");
}

/// Checks if there is a validate method
pub fn hasValidate(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "validate");
}

/// Checks if there is a isValid method
pub fn hasIsValid(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "isValid");
}

/// Checks if there is a subDays method
pub fn hasSubDays(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "subDays");
}

/// Checks if there is a addDays method
pub fn hasAddDays(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "addDays");
}

/// Checks if there is a dayDifference method
pub fn hasDayDifference(comptime Cal: type) bool {
    return comptime std.meta.hasFn(Cal, "dayDifference");
}

/// Checks if a calendar is approximate
pub fn isApproximate(comptime Cal: type) bool {
    if (comptime @hasField(Cal, "Approximate")) {
        return Cal.Approximate;
    } else {
        return false;
    }
}

/// Gets the type of year on a calendar
pub fn YearType(comptime Calendar: type) type {
    if (!comptime hasYear(Calendar)) return void;

    if (comptime @hasField(Calendar, "year")) {
        return @TypeOf((Calendar{}).year);
    } else {
        return @TypeOf((Calendar{}).year());
    }
}

/// Gets the year from a calendar (must pass feature hasYear)
pub fn yearFor(calendar: anytype) YearType(@TypeOf(calendar)) {
    const Calendar = @TypeOf(calendar);
    comptime std.debug.assert(hasYear(Calendar));
    if (comptime @hasField(Calendar, "year")) {
        return calendar.year;
    } else {
        return calendar.year();
    }
}

/// Checks if there is a annoDominiYear method
pub fn hasAnnoDominiYear(comptime Calendar: type) bool {
    if (!comptime hasYear(Calendar)) return false;
    return YearType(Calendar) == core.AnnoDominiYear;
}

/// Checks if there is a astronomicalYear method
pub fn hasAstronomicalYear(comptime Calendar: type) bool {
    if (!comptime hasYear(Calendar)) return false;
    return YearType(Calendar) == core.AstronomicalYear;
}

/// Checks if there is a Name constant
pub fn hasName(comptime Calendar: type) bool {
    if (comptime @hasDecl(Calendar, "Name")) {
        return true;
    } else if (comptime @hasDecl(Calendar, "Date") and @hasDecl(Calendar.Date, "Name")) {
        return true;
    } else {
        return false;
    }
}

/// Checks if the Time constant is time.Segments
pub fn hasTimeSegments(comptime Calendar: type) bool {
    return comptime hasTime(Calendar) and Calendar.Time == time.Segments;
}

/// Checks if the Time constant is time.DayFraction
pub fn hasTimeDayFraction(comptime Calendar: type) bool {
    return comptime hasTime(Calendar) and Calendar.Time == time.DayFraction;
}

/// Checks if the Time constant is time.NanoSeconds
pub fn hasTimeNanoSeconds(comptime Calendar: type) bool {
    return comptime hasTime(Calendar) and Calendar.Time == time.NanoSeconds;
}

/// Checks if there is a dayOfWeekNameShort method
pub fn hasDayOfWeekNameShort(comptime Calendar: type) bool {
    return comptime std.meta.hasFn(Calendar, "dayOfWeekNameShort");
}

/// Checks if there is a monthNameLong method
pub fn hasMonthNameLong(comptime Calendar: type) bool {
    return comptime std.meta.hasFn(Calendar, "monthNameLong");
}

/// Checks if there is a monthNameShort method
pub fn hasMonthNameShort(comptime Calendar: type) bool {
    return comptime std.meta.hasFn(Calendar, "monthNameShort");
}

/// Checks if there is a monthNameFirstLetter method
pub fn hasMonthNameFirstLetter(comptime Calendar: type) bool {
    return comptime std.meta.hasFn(Calendar, "monthNameFirstLetter");
}

/// Checks if there is a dayOfWeekNameFirstLetter method
pub fn hasDayOfWeekNameFirstLetter(comptime Calendar: type) bool {
    return comptime std.meta.hasFn(Calendar, "dayOfWeekNameFirstLetter");
}

/// Checks if there is a dayOfWeekNameFirst2Letters method
pub fn hasDayOfWeekNameFirst2Letters(comptime Calendar: type) bool {
    return comptime std.meta.hasFn(Calendar, "dayOfWeekNameFirst2Letters");
}

/// Checks if there is a dayOfWeekNameFull method
pub fn hasDayOfWeekNameFull(comptime Calendar: type) bool {
    return comptime std.meta.hasFn(Calendar, "dayOfWeekNameFull");
}

/// Checks if there is a Zone constant and zone field
pub fn hasZone(comptime Calendar: type) bool {
    return comptime @hasDecl(Calendar, "Zone")
    //
    and @hasField(Calendar, "zone")
    //
    and Calendar.Zone == @import("../calendars/zone.zig").TimeZone;
}

/// Checks if there is a Time constant and time field
pub fn hasTime(comptime Calendar: type) bool {
    return comptime @hasDecl(Calendar, "Time") and @hasField(Calendar, "time")
    //
    and (Calendar.Time == time.Segments
    //
    or Calendar.Time == time.DayFraction
    //
    or Calendar.Time == time.NanoSeconds);
}

/// Checks if there is a Date constant and date field
pub fn hasDate(comptime Calendar: type) bool {
    return comptime @hasDecl(Calendar, "Date") and @hasField(Calendar, "date");
}

/// Checks if there is a day_number field or dayNumber method
pub fn hasDayOfYear(comptime Calendar: type) bool {
    return comptime (@hasField(Calendar, "day_in_year")
    //
    or std.meta.hasFn(Calendar, "dayInYear"));
}

/// Checks if there is a day field or day method
pub fn hasDayOfMonth(comptime Calendar: type) bool {
    return comptime (@hasField(Calendar, "day")
    //
    or std.meta.hasFn(Calendar, "day"));
}

/// Checks if there is a month field or month method
pub fn hasMonth(comptime Calendar: type) bool {
    return comptime (@hasField(Calendar, "month")
    //
    or std.meta.hasFn(Calendar, "month"));
}

/// Checks if there is a quarter field or quarter method
pub fn hasQuarter(comptime Calendar: type) bool {
    return comptime (@hasField(Calendar, "quarter")
    //
    or std.meta.hasFn(Calendar, "quarter"));
}

/// Checks if there is a day_of_week field or dayOfWeek method
pub fn hasDayOfWeek(comptime Calendar: type) bool {
    return comptime @hasField(Calendar, "day_of_week")
    //
    or std.meta.hasFn(Calendar, "dayOfWeek");
}

/// Checks if there is a week field or week method
pub fn hasWeek(comptime Calendar: type) bool {
    return comptime (@hasField(Calendar, "week")
    //
    or std.meta.hasFn(Calendar, "week"));
}

/// Checks if there is a year field or year method
pub fn hasYear(comptime Calendar: type) bool {
    return comptime (@hasField(Calendar, "year")
    //
    or std.meta.hasFn(Calendar, "year"));
}
