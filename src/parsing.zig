const core = @import("calendars/core.zig");
const Format = @import("formatting/core.zig").Format;
const Segment = @import("formatting/core.zig").Segment;
const parseFormatStr = @import("formatting.zig").parseFormatStr;
const zone = @import("calendars/zone.zig");
const Zone = zone.TimeZone;
const AstronomicalYear = core.AstronomicalYear;
const gregorian = @import("calendars/gregorian.zig");
const Month = @import("calendars/gregorian.zig").Month;
const std = @import("std");

const Era = enum { AD, BC };
const TimeOfDay = enum { AM, PM };

const ParsedData = struct {
    year_unsigned: ?u32 = null,
    year_era: ?Era = null,
    year_signed: ?i32 = null,
    month: ?u8 = null,
    week: ?u8 = null,
    day_of_week: ?u8 = null,
    day_of_month: ?u8 = null,
    day_of_year: ?u16 = null,
    time_of_day: ?TimeOfDay = null,
    hour_12: ?u8 = null,
    hour_24: ?u8 = null,
    minute: ?u8 = null,
    second: ?u8 = null,
    nano: ?u32 = null,
    zone: ?Zone = null,
};

const ParseError = zone.TimeZoneValidationError || std.fmt.ParseIntError || error{ InvalidInput, UnsupportedFormatString, ConflictingInput };

/// Parses a date based on a format struct
pub fn parseDate(parse_fmt: Format, input: []const u8) !gregorian.DateTimeZoned {
    const data = try parseIntoStruct(parse_fmt, input);
    return try parsedToDate(data);
}

/// Parses a date based on a format string. First argument is format string, second is date string
/// Format string format:
/// | Character(s) | Meaning |
/// ---------------|---------|
/// | Y... | Year. Repeated occurrences determines padding. 1 B.C. is 0. 2 B.C. is -1 |
/// | y | Anno Domini year. All years are unsigned, so use with an era. If no era is found, assumes A.D. |
/// | yy | 2 digit year plus 2000 (i.e. 2 digit year for years after 2000) |
/// | yyy | 3 digit year plus 2000 (i.e. 3 digit year for years after 2000) |
/// | yyyy... | Anno domini year with 4 padding. Can add more `y` to increase padding |
/// | u... | Signed Year where '+' is for AD and '-' for B.C. Repeated occurrences determines padding. |
/// | G, GG, GGG | Era designator (supports ad, a.d., ce, c.e., bc, b.c., bce, b.c.e.) |
/// | GGGG | Era designator long. (supports "anno domini", "before christ", "current era", "before current era") |
/// | R.. | ISO week in year |
/// | M, MM | Month number |
/// | MMM | Month name short (Jan, Jun, Jul, etc) |
/// | MMMM | Month name full (January, June, July, etc.) |
/// | d, dd | Day of month |
/// | D... | Day of year (e.g. 236) |
/// | e | Day of week (1 - Monday, 7 - Sunday) |
/// | ee | Day of week padded to 2 digits |
/// | eee | Day of week name short (e.g. Tue). Based on calendar overrides or locale |
/// | eeee | Day of week name full (e.g. Tuesday) Based on calendar overrides or locale |
/// | eeeeee | Day of week name first 2 letters (e.g. Tu) Based on calendar overrides or locale |
/// | a, aa | Time of day (any of the A..AAAAA variants) |
/// | A, AA | Time of day upper (AM, PM) |
/// | AAA | Time of day lower (am, pm) |
/// | AAAA | Time of day lower with periods (a.m., p.m.) |
/// | AAAAA | Time of day lower, first letter (a, p) |
/// | h | Hour, 12-houring system |
/// | hh | Hour, 12-houring system 2 padding |
/// | H | Hour, 24-houring system |
/// | HH | Hour, 24-houring system, 2 padding |
/// | m | Minute, no padding |
/// | mm | Minute, 2 padding |
/// | s | Second, no padding |
/// | ss | Second, 2 padding |
/// | S... | Fraction of a second. Number of S's determine precision. Up to nanosecond supported |
/// | X, XX, XXX | Timezone offset from UTC. Z used for UTC. (e.g. -08, +0530, Z, -04:34) |
/// | x, xx, xxx | Timezone offset from UTC. (e.g. -08, +0530, +00, +01:00) |
/// | O | GMT offset, short. GMT/UTC timezone is shown as "GMT" (e.g. GMT+05, GMT-1020, GMT) |
/// | OO, OOO, OOOO | GMT offset (e.g. GMT+05, GMT-10:20, GMT+00, GMT-01:00) |
/// | '...' | Quoted text, will match contents. \' and \\ are allowed for escaping in quotes |
/// | \. | Escape following character (don't interpret as a command) |
/// | ... | Everything else is treated as plain text and will be matched as-is |
pub fn parse(parse_fmt: []const u8, input: []const u8) !gregorian.DateTimeZoned {
    return parseDate(try parseFormatStr(parse_fmt), input);
}

fn parsedToDate(data: ParsedData) !gregorian.DateTimeZoned {
    const Gregorian = gregorian.Date;
    var target_year: ?AstronomicalYear = null;
    if (data.year_signed) |year_signed| {
        target_year = @enumFromInt(year_signed);
    }
    if (data.year_unsigned) |yu| {
        var y: i32 = @intCast(yu);
        if (data.year_era == Era.BC) {
            y *= -1;
        }
        if (target_year) |ty| {
            if (y != @intFromEnum(ty)) return ParseError.ConflictingInput;
        }
        target_year = try core.adToAstro(@enumFromInt(yu));
    }
    const default_year: AstronomicalYear = @enumFromInt(1);

    const year_start = Gregorian{
        .year = target_year orelse default_year,
        .month = .January,
        .day = 1,
    };

    var cur_estimate = year_start;
    var changed_month = false;
    var changed_day = false;
    var changed_week = false;

    if (data.month) |month| {
        defer changed_month = true;
        if (month == 0) return ParseError.InvalidInput;
        if (month > 12) return ParseError.InvalidInput;
        var new_estimate = cur_estimate;
        new_estimate.month = @enumFromInt(month);

        if (changed_month and new_estimate.month != cur_estimate.month) {
            return ParseError.ConflictingInput;
        }
        cur_estimate = new_estimate;
    }

    if (data.week) |week| {
        defer changed_week = true;

        const week_initial = year_start.firstWeekDay(.Thursday);
        const week_thur = week_initial.addDays((@as(i32, @intCast(week)) - 1) * 7);
        var week_start = week_thur.dayOfWeekBefore(.Monday);
        if (@intFromEnum(week_start.year) < @intFromEnum(year_start.year)) {
            week_start = year_start;
        } else if (@intFromEnum(week_start.year) > @intFromEnum(year_start.year)) {
            return ParseError.ConflictingInput;
        }

        var new_estimate = week_start;

        if (changed_month and new_estimate.month != cur_estimate.month) {
            if (@intFromEnum(new_estimate.month) + 1 == @intFromEnum(cur_estimate.month)) {
                const target_date = Gregorian{ .year = target_year orelse default_year, .month = cur_estimate.month, .day = 1 };
                if (target_date.dayDifference(new_estimate) >= 7) {
                    return ParseError.ConflictingInput;
                }
                new_estimate = target_date;
            } else {
                return ParseError.ConflictingInput;
            }
        }
        cur_estimate = new_estimate;
    }

    if (data.day_of_year) |doy| {
        defer changed_month = true;
        defer changed_day = true;
        if (doy == 0) return ParseError.InvalidInput;
        if (doy > year_start.daysRemaining() + 1) return ParseError.InvalidInput;
        const new_estimate = cur_estimate.addDays(doy - 1);
        if (changed_month) {
            if (new_estimate.month != cur_estimate.month) {
                return ParseError.ConflictingInput;
            }
        }
        if (changed_day) {
            if (new_estimate.day != cur_estimate.day) {
                return ParseError.ConflictingInput;
            }
        }
        if (changed_week) {
            if (@abs(new_estimate.dayDifference(cur_estimate)) >= 7) {
                return ParseError.ConflictingInput;
            }
        }
        cur_estimate = new_estimate;
    }

    if (data.day_of_month) |dom| {
        defer changed_day = true;
        var new_estimate = cur_estimate;
        new_estimate.day = dom;

        if (changed_day and new_estimate.compare(cur_estimate) != 0) {
            return ParseError.ConflictingInput;
        }

        cur_estimate = new_estimate;
    }

    if (data.day_of_week) |dow| {
        defer changed_day = true;
        const dow_enum: core.DayOfWeek = if (dow == 0 or dow == 7) .Sunday else @enumFromInt(dow);
        const new_estimate = cur_estimate.dayOfWeekOnOrAfter(dow_enum);

        if (changed_day and new_estimate.compare(cur_estimate) != 0) {
            return ParseError.ConflictingInput;
        }

        cur_estimate = new_estimate;
    }

    try cur_estimate.validate();

    var hour: u8 = 0;
    var changed_hour = false;

    if (data.hour_12) |h12| {
        defer changed_hour = true;
        const tod = data.time_of_day orelse .AM;
        if (tod == .AM) {
            if (h12 == 12) hour = 0 else hour = h12;
        } else {
            if (h12 == 12) hour = h12 else hour = h12 + 12;
        }
    }

    if (data.hour_24) |h24| {
        defer changed_hour = true;
        if (changed_hour and h24 != hour) {
            return ParseError.ConflictingInput;
        }
        hour = h24;
    }

    const minute = data.minute orelse 0;
    const second = data.second orelse 0;
    const nano = data.nano orelse 0;
    const tz = data.zone orelse zone.UTC;

    const time = try gregorian.DateTimeZoned.Time.init(hour, minute, second, nano);

    return try gregorian.DateTimeZoned.init(cur_estimate, time, tz);
}

fn parseIntoStruct(fmt: Format, input: []const u8) ParseError!ParsedData {
    var res = ParsedData{};
    var view = input[0..];
    for (fmt._segs[0..fmt._segs_len]) |segment| {
        if (view.len == 0) return ParseError.InvalidInput;
        const consumed = try getView(segment, view, &res);
        defer view = view[consumed..];
    }
    return res;
}

fn getView(segment: Segment, input: []const u8, out: *ParsedData) ParseError!usize {
    if (input.len == 0) return ParseError.InvalidInput;
    switch (segment.type) {
        .Text => {
            var index: usize = 0;
            var escaped = false;
            for (segment.str) |c| {
                const cur = if (index < input.len) input[index] else return ParseError.InvalidInput;
                if (escaped) {
                    escaped = false;
                } else if (c == '\\') {
                    escaped = true;
                }

                if (!escaped) {
                    if (c != cur) {
                        return ParseError.InvalidInput;
                    } else {
                        index += 1;
                    }
                }
            }
            return segment.str.len;
        },
        .TextQuoted => {
            var index: usize = 0;
            var escaped = false;
            for (segment.str) |c| {
                const cur = if (index < input.len) input[index] else return ParseError.InvalidInput;
                if (escaped) {
                    escaped = false;
                } else if (c == '\\') {
                    escaped = true;
                }

                if (!escaped) {
                    if (c != cur) {
                        return ParseError.InvalidInput;
                    } else {
                        index += 1;
                    }
                }
            }
            return segment.str.len;
        },
        .YearIso => {
            const s: usize = if (input[0] == '-') 1 else 0;
            const in = input[s..];
            const nums = if (segment.str.len == 1) try consumeNum(in, 250) else try consumeNum(in, segment.str.len);
            const p = try std.fmt.parseInt(u32, nums, 10);
            if (s == 1) {
                out.year_signed = -@as(i32, @intCast(p));
            } else {
                out.year_signed = @as(i32, @intCast(p));
            }
            return nums.len + s;
        },
        .Year => {
            const nums = if (segment.str.len == 1) try consumeNum(input, 250) else try consumeNum(input, segment.str.len);
            const p = try std.fmt.parseInt(u32, nums, 10);
            if (segment.str.len == 2) {
                out.year_unsigned = 2000 + p;
            } else if (segment.str.len == 3) {
                out.year_unsigned = 2000 + p;
            } else {
                out.year_unsigned = p;
            }
            return nums.len;
        },
        .MonthNum => {
            const nums = try consumeNum(input, 2);
            const p = try std.fmt.parseInt(u8, nums, 10);
            out.month = p;
            return nums.len;
        },
        .MonthNameShort => return try consumeMonthNameShort(input, out),
        .MonthNameLong => return try consumeMonthNameLong(input, out),
        .DayOfMonthNum => {
            const nums = try consumeNum(input, 2);
            const p = try std.fmt.parseInt(u8, nums, 10);
            out.day_of_month = p;
            return nums.len;
        },
        .DayOfWeekNum => {
            const nums = try consumeNum(input, segment.str.len);
            const p = try std.fmt.parseInt(u8, nums, 10);
            out.day_of_week = p;
            return nums.len;
        },
        .DayOfWeekNameFull => {
            return try consumeDayOfWeekFull(input, out);
        },
        .DayOfWeekNameShort => {
            return try consumeDayOfWeekShort(input, out);
        },
        .DayOfWeekNameFirst2Letters => {
            return try consumeDayOfWeekFirstTwoLetters(input, out);
        },
        .DayofYearNum => {
            const nums = try consumeNum(input, 3);
            const p = try std.fmt.parseInt(u8, nums, 10);
            out.day_of_year = p;
            return nums.len;
        },
        .WeekInYear => {
            const nums = try consumeNum(input, @max(2, segment.str.len));
            const p = try std.fmt.parseInt(u8, nums, 10);
            out.week = p;
            return nums.len;
        },
        .SignedYear => {
            const nums = if (segment.str.len == 1) try consumeSignedNum(input, 250) else try consumeSignedNum(input, segment.str.len);
            const p = try std.fmt.parseInt(i32, nums, 10);
            out.year_signed = p;
            return nums.len;
        },
        .TimeOfDayAM => {
            return consumeAM(input, out);
        },
        .TimeOfDay_am => {
            return consume_am(input, out);
        },
        .TimeOfDay_ap => {
            return consume_ap(input, out);
        },
        .TimeOfDay_a_m => {
            return consume_a_m(input, out);
        },
        .TimeOfDayLocale => {
            return consumeAM(input, out) catch consume_am(input, out) catch consume_a_m(input, out) catch consume_a_m(input, out);
        },
        .Hour12Num => {
            const nums = try consumeNum(input, 2);
            const p = try std.fmt.parseInt(u8, nums, 10);
            out.hour_12 = p;
            return nums.len;
        },
        .Hour24Num => {
            const nums = try consumeNum(input, 2);
            const p = try std.fmt.parseInt(u8, nums, 10);
            out.hour_24 = p;
            return nums.len;
        },
        .MinuteNum => {
            const nums = try consumeNum(input, 2);
            const p = try std.fmt.parseInt(u8, nums, 10);
            out.minute = p;
            return nums.len;
        },
        .SecondNum => {
            const nums = try consumeNum(input, 2);
            const p = try std.fmt.parseInt(u8, nums, 10);
            out.second = p;
            return nums.len;
        },
        .FractionOfASecond => {
            const nums = try consumeNum(input, segment.str.len);
            var p = try std.fmt.parseInt(u32, nums, 10);
            if (nums.len < 9) {
                p *= std.math.pow(u32, 10, @intCast(9 - nums.len));
            }
            out.nano = p;
            return nums.len;
        },
        .EraDesignatorShort => return consumeEraShort(input, out),
        .EraDesignatorLong => return consumeEraLong(input, out),
        .YearOrdinal,
        .DayOfMonthOrdinal,
        .MinuteOrdinal,
        .SecondOrdinal,
        .QuarterOrdinal,
        .Hour12Ordinal,
        .Hour24Ordinal,
        .WeekInYearOrdinal,
        .QuarterNum,
        .QuarterLong,
        .QuarterPrefixed,
        .LocalizedLongDate,
        .LocalizedLongTime,
        .LocalizedLongDateTime,
        .DayOfWeekOrdinal,
        .DayOfYearOrdinal,
        .CalendarSystem,
        .DayOfWeekNameFirstLetter,
        .MonthNameFirstLetter,
        => return ParseError.UnsupportedFormatString,
        .TimezoneOffset => return consumeTimezoneOffset(input, out),
        .TimezoneOffsetZ => return consumeTimezoneOffsetWithZ(input, out),
        .GmtOffset, .GmtOffsetFull => return consumeGmtOffset(input, out),
    }
}

fn consumeGmtOffset(input: []const u8, out: *ParsedData) !usize {
    if (input.len < 3) return ParseError.InvalidInput;

    if (!std.mem.startsWith(u8, input, "GMT")) return ParseError.InvalidInput;
    var len: usize = 3;

    if (input.len == 3 or (input[3] != '-' and input[3] != '+')) {
        out.zone = zone.GMT;
        return len;
    }

    const z = input[3..];
    if (input.len < 5) return ParseError.InvalidInput;

    const hours = try consumeSignedNum(z, 2);
    len += hours.len;
    var minutes: []const u8 = "00";
    if (z.len > hours.len + 1 and z[hours.len] == ':') {
        const sub = z[(hours.len)..][1..];
        minutes = try consumeNum(sub, 2);
        len += minutes.len + 1;
    }

    const hour = try std.fmt.parseInt(i8, hours, 10);
    const min = try std.fmt.parseInt(u8, minutes, 10);

    if (hour == 0 and min == 0) {
        out.zone = zone.GMT;
        return len;
    }

    const tz = try Zone.init(.{ .hours = hour, .minutes = min }, null);
    out.zone = tz;
    return len;
}

fn consumeTimezoneOffset(input: []const u8, out: *ParsedData) ParseError!usize {
    if (input.len < 3) return ParseError.InvalidInput;

    var len: usize = 0;

    const nums = try consumeSignedNum(input, 4);
    if (nums.len != 3 and nums.len != 5) {
        return ParseError.InvalidInput;
    }
    len = nums.len;

    const hours = nums[0..3];
    var minutes = if (nums.len == 3) "00" else nums[3..];

    if (input.len > 5 and input[3] == ':') {
        minutes = try consumeNum(input[4..], 2);
        len += minutes.len + 1;
    }

    const hour = try std.fmt.parseInt(i8, hours, 10);
    const min = try std.fmt.parseInt(u8, minutes, 10);

    if (hour == 0 and min == 0) {
        out.zone = zone.UTC;
        return len;
    }

    const tz = try Zone.init(.{ .hours = hour, .minutes = min }, null);
    out.zone = tz;
    return len;
}

fn consumeTimezoneOffsetWithZ(input: []const u8, out: *ParsedData) ParseError!usize {
    if (input.len >= 1 and (input[0] == 'Z' or input[0] == 'z')) {
        out.zone = zone.UTC;
        return 1;
    }

    return try consumeTimezoneOffset(input, out);
}

fn startsWithInsensitive(haystack: []const u8, needle: []const u8) bool {
    if (haystack.len < needle.len) return false;

    for (needle, 0..) |needle_char, i| {
        if (needle_char != haystack[i] and (needle_char == ' ' or needle_char != (haystack[i] | ASCII_CASE_BIT))) {
            return false;
        }
    }
    return true;
}

fn consumeEraLong(input: []const u8, out: *ParsedData) ParseError!usize {
    const bc_strs = [_][]const u8{
        "before christ", "before current era",
    };
    const ad_strs = [_][]const u8{
        "anno domini", "current erra",
    };
    for (ad_strs) |ad_str| {
        if (startsWithInsensitive(input, ad_str)) {
            out.year_era = .AD;
            return ad_str.len;
        }
    }
    for (bc_strs) |bc_str| {
        if (startsWithInsensitive(input, bc_str)) {
            out.year_era = .BC;
            return bc_str.len;
        }
    }
    return ParseError.InvalidInput;
}

fn consumeMonthNameShort(input: []const u8, out: *ParsedData) ParseError!usize {
    const january = "jan";
    const february = "feb";
    const march = "mar";
    const april = "apr";
    const may = "may";
    const june = "jun";
    const july = "jul";
    const august = "aug";
    const september = "sep";
    const october = "oct";
    const november = "nov";
    const december = "dec";

    if (startsWithInsensitive(input, january)) {
        out.month = @intFromEnum(Month.January);
        return january.len;
    } else if (startsWithInsensitive(input, february)) {
        out.month = @intFromEnum(Month.February);
        return february.len;
    } else if (startsWithInsensitive(input, march)) {
        out.month = @intFromEnum(Month.March);
        return february.len;
    } else if (startsWithInsensitive(input, april)) {
        out.month = @intFromEnum(Month.April);
        return february.len;
    } else if (startsWithInsensitive(input, may)) {
        out.month = @intFromEnum(Month.May);
        return february.len;
    } else if (startsWithInsensitive(input, june)) {
        out.month = @intFromEnum(Month.June);
        return february.len;
    } else if (startsWithInsensitive(input, july)) {
        out.month = @intFromEnum(Month.July);
        return february.len;
    } else if (startsWithInsensitive(input, august)) {
        out.month = @intFromEnum(Month.August);
        return february.len;
    } else if (startsWithInsensitive(input, september)) {
        out.month = @intFromEnum(Month.September);
        return february.len;
    } else if (startsWithInsensitive(input, october)) {
        out.month = @intFromEnum(Month.October);
        return february.len;
    } else if (startsWithInsensitive(input, november)) {
        out.month = @intFromEnum(Month.November);
        return february.len;
    } else if (startsWithInsensitive(input, december)) {
        out.month = @intFromEnum(Month.December);
        return february.len;
    } else {
        return ParseError.InvalidInput;
    }
}

fn consumeMonthNameLong(input: []const u8, out: *ParsedData) ParseError!usize {
    const january = "january";
    const february = "february";
    const march = "march";
    const april = "april";
    const may = "may";
    const june = "june";
    const july = "july";
    const august = "august";
    const september = "september";
    const october = "october";
    const november = "november";
    const december = "december";

    if (startsWithInsensitive(input, january)) {
        out.month = @intFromEnum(Month.January);
        return january.len;
    } else if (startsWithInsensitive(input, february)) {
        out.month = @intFromEnum(Month.February);
        return february.len;
    } else if (startsWithInsensitive(input, march)) {
        out.month = @intFromEnum(Month.March);
        return february.len;
    } else if (startsWithInsensitive(input, april)) {
        out.month = @intFromEnum(Month.April);
        return february.len;
    } else if (startsWithInsensitive(input, may)) {
        out.month = @intFromEnum(Month.May);
        return february.len;
    } else if (startsWithInsensitive(input, june)) {
        out.month = @intFromEnum(Month.June);
        return february.len;
    } else if (startsWithInsensitive(input, july)) {
        out.month = @intFromEnum(Month.July);
        return february.len;
    } else if (startsWithInsensitive(input, august)) {
        out.month = @intFromEnum(Month.August);
        return february.len;
    } else if (startsWithInsensitive(input, september)) {
        out.month = @intFromEnum(Month.September);
        return february.len;
    } else if (startsWithInsensitive(input, october)) {
        out.month = @intFromEnum(Month.October);
        return february.len;
    } else if (startsWithInsensitive(input, november)) {
        out.month = @intFromEnum(Month.November);
        return february.len;
    } else if (startsWithInsensitive(input, december)) {
        out.month = @intFromEnum(Month.December);
        return february.len;
    } else {
        return ParseError.InvalidInput;
    }
}

fn consumeEraShort(input: []const u8, out: *ParsedData) ParseError!usize {
    const bc_strs = [_][]const u8{ "bc", "b.c.", "bce", "b.c.e.", "BC", "B.C.", "BCE", "B.C.E" };
    const ad_strs = [_][]const u8{ "ad", "a.d.", "ce", "c.e.", "AD", "A.D.", "CE", "C.E." };
    for (ad_strs) |ad_str| {
        if (std.mem.startsWith(u8, input, ad_str)) {
            out.year_era = .AD;
            return ad_str.len;
        }
    }
    for (bc_strs) |bc_str| {
        if (std.mem.startsWith(u8, input, bc_str)) {
            out.year_era = .BC;
            return bc_str.len;
        }
    }
    return ParseError.InvalidInput;
}

const ASCII_CASE_BIT = 0b0010_0000;

fn consume_a_m(input: []const u8, out: *ParsedData) ParseError!usize {
    if (input.len < 4) return ParseError.InvalidInput;
    const substr = input[0..4];
    if (std.mem.eql(u8, substr, "a.m.")) {
        out.time_of_day = .AM;
        return 4;
    } else if (std.mem.eql(u8, substr, "p.m.")) {
        out.time_of_day = .PM;
        return 4;
    }
    return ParseError.InvalidInput;
}

fn consume_ap(input: []const u8, out: *ParsedData) ParseError!usize {
    if (input.len < 1) return ParseError.InvalidInput;
    if (input[0] == 'a') {
        out.time_of_day = .AM;
        return 1;
    } else if (input[0] == 'p') {
        out.time_of_day = .PM;
        return 1;
    }
    return ParseError.InvalidInput;
}

fn consume_am(input: []const u8, out: *ParsedData) ParseError!usize {
    if (input.len < 2) return ParseError.InvalidInput;
    if (input[0] == 'a' and input[1] == 'm') {
        out.time_of_day = .AM;
        return 2;
    } else if (input[0] == 'p' and input[1] == 'm') {
        out.time_of_day = .PM;
        return 2;
    }
    return ParseError.InvalidInput;
}

fn consumeAM(input: []const u8, out: *ParsedData) ParseError!usize {
    if (input.len < 2) return ParseError.InvalidInput;
    if (input[0] == 'A' and input[1] == 'M') {
        out.time_of_day = .AM;
        return 2;
    } else if (input[0] == 'P' and input[1] == 'M') {
        out.time_of_day = .PM;
        return 2;
    }
    return ParseError.InvalidInput;
}

fn consumeDayOfWeekFull(input: []const u8, out: *ParsedData) ParseError!usize {
    var buff: [9]u8 = undefined;
    std.mem.copyForwards(u8, &buff, input[0..@min(input.len, buff.len)]);
    for (buff, 0..) |b, i| {
        buff[i] = b | ASCII_CASE_BIT;
    }

    const monday = "monday";
    const tuesday = "tuesday";
    const wednesday = "wednesday";
    const thursday = "thursday";
    const friday = "friday";
    const saturday = "saturday";
    const sunday = "sunday";

    if (std.mem.startsWith(u8, &buff, monday)) {
        out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Monday));
        return monday.len;
    } else if (std.mem.startsWith(u8, &buff, tuesday)) {
        out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Tuesday));
        return tuesday.len;
    } else if (std.mem.startsWith(u8, &buff, wednesday)) {
        out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Wednesday));
        return wednesday.len;
    } else if (std.mem.startsWith(u8, &buff, thursday)) {
        out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Thursday));
        return thursday.len;
    } else if (std.mem.startsWith(u8, &buff, friday)) {
        out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Friday));
        return friday.len;
    } else if (std.mem.startsWith(u8, &buff, saturday)) {
        out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Saturday));
        return saturday.len;
    } else if (std.mem.startsWith(u8, &buff, sunday)) {
        out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Sunday));
        return sunday.len;
    }

    return ParseError.InvalidInput;
}

fn consumeDayOfWeekShort(input: []const u8, out: *ParsedData) ParseError!usize {
    if (input.len < 3) return ParseError.InvalidInput;
    const first_char = input[0] | ASCII_CASE_BIT;
    const second_char = input[1] | ASCII_CASE_BIT;
    const third_char = input[2] | ASCII_CASE_BIT;

    if (first_char == 't') {
        if (second_char == 'u' and third_char == 'e') {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Tuesday));
            return 3;
        } else if (second_char == 'h' and third_char == 'u') {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Thursday));
            return 3;
        }
    } else if (first_char == 's') {
        if (second_char == 'u' and third_char == 'n') {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Sunday));
            return 3;
        } else if (second_char == 'a' and third_char == 't') {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Saturday));
            return 3;
        }
    } else {
        const str = [3]u8{ first_char, second_char, third_char };
        if (std.mem.eql(u8, &str, "mon")) {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Monday));
            return 3;
        } else if (std.mem.eql(u8, &str, "wed")) {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Wednesday));
            return 3;
        } else if (std.mem.eql(u8, &str, "fri")) {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Friday));
            return 3;
        }
    }

    return ParseError.InvalidInput;
}

fn consumeDayOfWeekFirstTwoLetters(input: []const u8, out: *ParsedData) ParseError!usize {
    if (input.len < 2) return ParseError.InvalidInput;
    const first_char = input[0] | ASCII_CASE_BIT;
    const second_char = input[1] | ASCII_CASE_BIT;

    if (first_char == 't') {
        if (second_char == 'u') {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Tuesday));
            return 2;
        } else if (second_char == 'h') {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Thursday));
            return 2;
        }
    } else if (first_char == 's') {
        if (second_char == 'u') {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Sunday));
            return 2;
        } else if (second_char == 'a') {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Saturday));
            return 2;
        }
    } else {
        const str = [2]u8{ first_char, second_char };
        if (std.mem.eql(u8, &str, "mo")) {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Monday));
            return 2;
        } else if (std.mem.eql(u8, &str, "we")) {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Wednesday));
            return 2;
        } else if (std.mem.eql(u8, &str, "fr")) {
            out.day_of_week = @as(u8, @intFromEnum(core.DayOfWeek.Friday));
            return 2;
        }
    }

    return ParseError.InvalidInput;
}

fn consumeSignedNum(input: []const u8, max_len: usize) ParseError![]const u8 {
    if (input.len <= 1) return ParseError.InvalidInput;
    switch (input[0]) {
        '-', '+' => {},
        else => return ParseError.InvalidInput,
    }
    const nums = try consumeNum(input[1..], max_len);
    return input[0..(nums.len + 1)];
}

fn consumeNum(input: []const u8, max_len: usize) ParseError![]const u8 {
    if (input.len == 0) return ParseError.InvalidInput;
    var len: usize = 0;
    while (len < input.len and len < max_len and input[len] >= '0' and input[len] <= '9') : (len += 1) {}
    if (len == 0) return ParseError.InvalidInput;
    return input[0..len];
}

test "_" {
    _ = @import("parsing/tests.zig");
}

test "parse year" {
    var res = try parseIntoStruct(try parseFormatStr("YYYY"), "2024");
    try std.testing.expectEqual(2024, res.year_signed.?);

    res = try parseIntoStruct(try parseFormatStr("y"), "2024");
    try std.testing.expectEqual(2024, res.year_unsigned.?);

    res = try parseIntoStruct(try parseFormatStr("yy"), "24");
    try std.testing.expectEqual(2024, res.year_unsigned.?);

    res = try parseIntoStruct(try parseFormatStr("YYYm"), "2024");
    try std.testing.expectEqual(202, res.year_signed.?);

    res = try parseIntoStruct(try parseFormatStr("yyym"), "2024");
    try std.testing.expectEqual(2202, res.year_unsigned.?);
}

test "parse ymd hms" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddTHH:mm:ss"),
        "2024-07-01T23:49:32",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(23, res.hour_24.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
}

test "parse ymd hms.S AAA x (no colon)" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS AAA x"),
        "2024-07-01T08:49:32.58493 pm -0530",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
    try std.testing.expectEqualDeep(try Zone.init(.{ .hours = -5, .minutes = 30 }, null), res.zone.?);
}

test "parse ymd hms.S AAA x" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS AAA x"),
        "2024-07-01T08:49:32.58493 pm -08",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
    try std.testing.expectEqualDeep(try Zone.init(.{ .hours = -8 }, null), res.zone.?);
}

test "parse ymd hms.S AAA x (colon)" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS AAA x"),
        "2024-07-01T08:49:32.58493 pm +08:43",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
    try std.testing.expectEqualDeep(try Zone.init(.{ .hours = 8, .minutes = 43 }, null), res.zone.?);
}

test "parse ymd hms.S AAA X (Z)" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS AAA X"),
        "2024-07-01T08:49:32.58493 pm Z",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
    try std.testing.expectEqualDeep(zone.UTC, res.zone.?);
}

test "parse ymd hms.S AAA X (no colon)" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS AAA X"),
        "2024-07-01T08:49:32.58493 pm -0530",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
    try std.testing.expectEqualDeep(try Zone.init(.{ .hours = -5, .minutes = 30 }, null), res.zone.?);
}

test "parse ymd hms.S AAA X" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS AAA X YYYY"),
        "2024-07-01T08:49:32.58493 pm -08 2024",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
    try std.testing.expectEqualDeep(try Zone.init(.{ .hours = -8 }, null), res.zone.?);
}

test "parse ymd hms.S AAA X (colon)" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS AAA X"),
        "2024-07-01T08:49:32.58493 pm +08:43",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
    try std.testing.expectEqualDeep(try Zone.init(.{ .hours = 8, .minutes = 43 }, null), res.zone.?);
}

test "parse ymd hms.S AAA O" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS AAA O YYYY"),
        "2024-07-01T08:49:32.58493 pm GMT+08:43 2024",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
    try std.testing.expectEqualDeep(try Zone.init(.{ .hours = 8, .minutes = 43 }, null), res.zone.?);
}

test "parse ymd hms.S a" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS a"),
        "2024-07-01T08:49:32.58493 pm",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
}

test "parse ymd hms.S AAA" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS AAA"),
        "2024-07-01T08:49:32.58493 pm",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
}

test "parse ymd hms.S AAA GGGG (AD)" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS AAA GGGG"),
        "2024-07-01T08:49:32.58493 pm anno Domini",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(Era.AD, res.year_era.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
}

test "parse ymd hms.S AAA GGGG (BC)" {
    const res = try parseIntoStruct(
        try parseFormatStr("YYYY-MM-ddThh:mm:ss.SSSSS AAA GGGG"),
        "2024-07-01T08:49:32.58493 pm Before christ",
    );
    try std.testing.expectEqual(2024, res.year_signed.?);
    try std.testing.expectEqual(Era.BC, res.year_era.?);
    try std.testing.expectEqual(7, res.month.?);
    try std.testing.expectEqual(1, res.day_of_month.?);
    try std.testing.expectEqual(8, res.hour_12.?);
    try std.testing.expectEqual(.PM, res.time_of_day.?);
    try std.testing.expectEqual(49, res.minute.?);
    try std.testing.expectEqual(32, res.second.?);
}
