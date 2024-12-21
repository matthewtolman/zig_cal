const std = @import("std");
const Code = @import("../formatting.zig");
const core = @import("core.zig");
const Format = core.Format;
const Segment = core.Segment;
const parseFormatStr = Code.parseFormatStr;

const TestCase = struct {
    input: []const u8,
    res: Format,
};

test "parse format string" {
    const test_cases = [_]TestCase{
        .{ .input = "G", .res = Format.from(&[_]Segment{
            .{ .type = .EraDesignatorShort, .str = "G" },
        }) },
        .{ .input = "GG", .res = Format.from(&[_]Segment{
            .{ .type = .EraDesignatorShort, .str = "GG" },
        }) },
        .{ .input = "GGG", .res = Format.from(&[_]Segment{
            .{ .type = .EraDesignatorShort, .str = "GGG" },
        }) },
        .{ .input = "GGGG", .res = Format.from(&[_]Segment{
            .{ .type = .EraDesignatorLong, .str = "GGGG" },
        }) },
        .{ .input = "GGGGG", .res = Format.from(&[_]Segment{
            .{ .type = .EraDesignatorLong, .str = "GGGG" },
            .{ .type = .EraDesignatorShort, .str = "G" },
        }) },
        .{ .input = "A", .res = Format.from(&[_]Segment{
            .{ .type = .TimeOfDayAM, .str = "A" },
        }) },
        .{ .input = "AA", .res = Format.from(&[_]Segment{
            .{ .type = .TimeOfDayAM, .str = "AA" },
        }) },
        .{ .input = "AAA", .res = Format.from(&[_]Segment{
            .{ .type = .TimeOfDay_am, .str = "AAA" },
        }) },
        .{ .input = "AAAA", .res = Format.from(&[_]Segment{
            .{ .type = .TimeOfDay_a_m, .str = "AAAA" },
        }) },
        .{ .input = "AAAAA", .res = Format.from(&[_]Segment{
            .{ .type = .TimeOfDay_ap, .str = "AAAAA" },
        }) },
        .{ .input = "AAAAAA", .res = Format.from(&[_]Segment{
            .{ .type = .TimeOfDay_ap, .str = "AAAAA" },
            .{ .type = .TimeOfDayAM, .str = "A" },
        }) },
        .{ .input = "a", .res = Format.from(&[_]Segment{
            .{ .type = .TimeOfDayLocale, .str = "a" },
        }) },
        .{ .input = "aa", .res = Format.from(&[_]Segment{
            .{ .type = .TimeOfDayLocale, .str = "aa" },
        }) },
        .{ .input = "aaa", .res = Format.from(&[_]Segment{
            .{ .type = .TimeOfDayLocale, .str = "aa" },
            .{ .type = .TimeOfDayLocale, .str = "a" },
        }) },
        .{ .input = "d", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfMonthNum, .str = "d" },
        }) },
        .{ .input = "do", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfMonthOrdinal, .str = "do" },
        }) },
        .{ .input = "dd", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfMonthNum, .str = "dd" },
        }) },
        .{ .input = "D", .res = Format.from(&[_]Segment{
            .{ .type = .DayofYearNum, .str = "D" },
        }) },
        .{ .input = "Do", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfYearOrdinal, .str = "Do" },
        }) },
        .{ .input = "DD", .res = Format.from(&[_]Segment{
            .{ .type = .DayofYearNum, .str = "DD" },
        }) },
        .{ .input = "DDD", .res = Format.from(&[_]Segment{
            .{ .type = .DayofYearNum, .str = "DDD" },
        }) },
        .{ .input = "Y", .res = Format.from(&[_]Segment{
            .{ .type = .YearIso, .str = "Y" },
        }) },
        .{ .input = "Yo", .res = Format.from(&[_]Segment{
            .{ .type = .YearOrdinal, .str = "Yo" },
        }) },
        .{ .input = "YY", .res = Format.from(&[_]Segment{
            .{ .type = .YearIso, .str = "YY" },
        }) },
        .{ .input = "YYY", .res = Format.from(&[_]Segment{
            .{ .type = .YearIso, .str = "YYY" },
        }) },
        .{ .input = "YYYY", .res = Format.from(&[_]Segment{
            .{ .type = .YearIso, .str = "YYYY" },
        }) },
        .{ .input = "YYYYYYYYYY", .res = Format.from(&[_]Segment{
            .{ .type = .YearIso, .str = "YYYYYYYYYY" },
        }) },
        .{ .input = "y", .res = Format.from(&[_]Segment{
            .{ .type = .Year, .str = "y" },
        }) },
        .{ .input = "yo", .res = Format.from(&[_]Segment{
            .{ .type = .YearOrdinal, .str = "yo" },
        }) },
        .{ .input = "yy", .res = Format.from(&[_]Segment{
            .{ .type = .Year, .str = "yy" },
        }) },
        .{ .input = "yyy", .res = Format.from(&[_]Segment{
            .{ .type = .Year, .str = "yyy" },
        }) },
        .{ .input = "yyyy", .res = Format.from(&[_]Segment{
            .{ .type = .Year, .str = "yyyy" },
        }) },
        .{ .input = "yyyyyyyyyy", .res = Format.from(&[_]Segment{
            .{ .type = .Year, .str = "yyyyyyyyyy" },
        }) },
        .{ .input = "R", .res = Format.from(&[_]Segment{
            .{ .type = .WeekInYear, .str = "R" },
        }) },
        .{ .input = "Ro", .res = Format.from(&[_]Segment{
            .{ .type = .WeekInYearOrdinal, .str = "Ro" },
        }) },
        .{ .input = "RR", .res = Format.from(&[_]Segment{
            .{ .type = .WeekInYear, .str = "RR" },
        }) },
        .{ .input = "u", .res = Format.from(&[_]Segment{
            .{ .type = .SignedYear, .str = "u" },
        }) },
        .{ .input = "uu", .res = Format.from(&[_]Segment{
            .{ .type = .SignedYear, .str = "uu" },
        }) },
        .{ .input = "uuu", .res = Format.from(&[_]Segment{
            .{ .type = .SignedYear, .str = "uuu" },
        }) },
        .{ .input = "Q", .res = Format.from(&[_]Segment{
            .{ .type = .QuarterNum, .str = "Q" },
        }) },
        .{ .input = "Qo", .res = Format.from(&[_]Segment{
            .{ .type = .QuarterOrdinal, .str = "Qo" },
        }) },
        .{ .input = "QQ", .res = Format.from(&[_]Segment{
            .{ .type = .QuarterNum, .str = "QQ" },
        }) },
        .{ .input = "QQQ", .res = Format.from(&[_]Segment{
            .{ .type = .QuarterPrefixed, .str = "QQQ" },
        }) },
        .{ .input = "QQQQ", .res = Format.from(&[_]Segment{
            .{ .type = .QuarterLong, .str = "QQQQ" },
        }) },
        .{ .input = "QQQQQ", .res = Format.from(&[_]Segment{
            .{ .type = .QuarterLong, .str = "QQQQ" },
            .{ .type = .QuarterNum, .str = "Q" },
        }) },
        .{ .input = "h", .res = Format.from(&[_]Segment{
            .{ .type = .Hour12Num, .str = "h" },
        }) },
        .{ .input = "ho", .res = Format.from(&[_]Segment{
            .{ .type = .Hour12Ordinal, .str = "ho" },
        }) },
        .{ .input = "hh", .res = Format.from(&[_]Segment{
            .{ .type = .Hour12Num, .str = "hh" },
        }) },
        .{ .input = "hhh", .res = Format.from(&[_]Segment{
            .{ .type = .Hour12Num, .str = "hh" },
            .{ .type = .Hour12Num, .str = "h" },
        }) },
        .{ .input = "H", .res = Format.from(&[_]Segment{
            .{ .type = .Hour24Num, .str = "H" },
        }) },
        .{ .input = "Ho", .res = Format.from(&[_]Segment{
            .{ .type = .Hour24Ordinal, .str = "Ho" },
        }) },
        .{ .input = "HH", .res = Format.from(&[_]Segment{
            .{ .type = .Hour24Num, .str = "HH" },
        }) },
        .{ .input = "HHH", .res = Format.from(&[_]Segment{
            .{ .type = .Hour24Num, .str = "HH" },
            .{ .type = .Hour24Num, .str = "H" },
        }) },
        .{ .input = "m", .res = Format.from(&[_]Segment{
            .{ .type = .MinuteNum, .str = "m" },
        }) },
        .{ .input = "mo", .res = Format.from(&[_]Segment{
            .{ .type = .MinuteOrdinal, .str = "mo" },
        }) },
        .{ .input = "mm", .res = Format.from(&[_]Segment{
            .{ .type = .MinuteNum, .str = "mm" },
        }) },
        .{ .input = "mmm", .res = Format.from(&[_]Segment{
            .{ .type = .MinuteNum, .str = "mm" },
            .{ .type = .MinuteNum, .str = "m" },
        }) },
        .{ .input = "s", .res = Format.from(&[_]Segment{
            .{ .type = .SecondNum, .str = "s" },
        }) },
        .{ .input = "so", .res = Format.from(&[_]Segment{
            .{ .type = .SecondOrdinal, .str = "so" },
        }) },
        .{ .input = "ss", .res = Format.from(&[_]Segment{
            .{ .type = .SecondNum, .str = "ss" },
        }) },
        .{ .input = "sss", .res = Format.from(&[_]Segment{
            .{ .type = .SecondNum, .str = "ss" },
            .{ .type = .SecondNum, .str = "s" },
        }) },
        .{ .input = "e", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfWeekNum, .str = "e" },
        }) },
        .{ .input = "eo", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfWeekOrdinal, .str = "eo" },
        }) },
        .{ .input = "ee", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfWeekNum, .str = "ee" },
        }) },
        .{ .input = "eee", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfWeekNameShort, .str = "eee" },
        }) },
        .{ .input = "eeee", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfWeekNameFull, .str = "eeee" },
        }) },
        .{ .input = "eeeee", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfWeekNameFirstLetter, .str = "eeeee" },
        }) },
        .{ .input = "eeeeee", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfWeekNameFirst2Letters, .str = "eeeeee" },
        }) },
        .{ .input = "eeeeeee", .res = Format.from(&[_]Segment{
            .{ .type = .DayOfWeekNameFirst2Letters, .str = "eeeeee" },
            .{ .type = .DayOfWeekNum, .str = "e" },
        }) },
        .{ .input = "M", .res = Format.from(&[_]Segment{
            .{ .type = .MonthNum, .str = "M" },
        }) },
        .{ .input = "MM", .res = Format.from(&[_]Segment{
            .{ .type = .MonthNum, .str = "MM" },
        }) },
        .{ .input = "MMM", .res = Format.from(&[_]Segment{
            .{ .type = .MonthNameShort, .str = "MMM" },
        }) },
        .{ .input = "MMMM", .res = Format.from(&[_]Segment{
            .{ .type = .MonthNameLong, .str = "MMMM" },
        }) },
        .{ .input = "MMMMM", .res = Format.from(&[_]Segment{
            .{ .type = .MonthNameFirstLetter, .str = "MMMMM" },
        }) },
        .{ .input = "MMMMMM", .res = Format.from(&[_]Segment{
            .{ .type = .MonthNameFirstLetter, .str = "MMMMM" },
            .{ .type = .MonthNum, .str = "M" },
        }) },
        .{ .input = "S", .res = Format.from(&[_]Segment{
            .{ .type = .FractionOfASecond, .str = "S" },
        }) },
        .{ .input = "SS", .res = Format.from(&[_]Segment{
            .{ .type = .FractionOfASecond, .str = "SS" },
        }) },
        .{ .input = "SSS", .res = Format.from(&[_]Segment{
            .{ .type = .FractionOfASecond, .str = "SSS" },
        }) },
        .{ .input = "X", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffsetZ, .str = "X" },
        }) },
        .{ .input = "XX", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffsetZ, .str = "XX" },
        }) },
        .{ .input = "XXX", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffsetZ, .str = "XXX" },
        }) },
        .{ .input = "XXXX", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffsetZ, .str = "XXXX" },
        }) },
        .{ .input = "XXXXX", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffsetZ, .str = "XXXXX" },
        }) },
        .{ .input = "XXXXXX", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffsetZ, .str = "XXXXX" },
            .{ .type = .TimezoneOffsetZ, .str = "X" },
        }) },
        .{ .input = "x", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffset, .str = "x" },
        }) },
        .{ .input = "xx", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffset, .str = "xx" },
        }) },
        .{ .input = "xxx", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffset, .str = "xxx" },
        }) },
        .{ .input = "xxxx", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffset, .str = "xxxx" },
        }) },
        .{ .input = "xxxxx", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffset, .str = "xxxxx" },
        }) },
        .{ .input = "xxxxxx", .res = Format.from(&[_]Segment{
            .{ .type = .TimezoneOffset, .str = "xxxxx" },
            .{ .type = .TimezoneOffset, .str = "x" },
        }) },
        .{ .input = "O", .res = Format.from(&[_]Segment{
            .{ .type = .GmtOffset, .str = "O" },
        }) },
        .{ .input = "OO", .res = Format.from(&[_]Segment{
            .{ .type = .GmtOffset, .str = "OO" },
        }) },
        .{ .input = "OOO", .res = Format.from(&[_]Segment{
            .{ .type = .GmtOffset, .str = "OOO" },
        }) },
        .{ .input = "OOOO", .res = Format.from(&[_]Segment{
            .{ .type = .GmtOffsetFull, .str = "OOOO" },
        }) },
        .{ .input = "OOOOO", .res = Format.from(&[_]Segment{
            .{ .type = .GmtOffsetFull, .str = "OOOO" },
            .{ .type = .GmtOffset, .str = "O" },
        }) },
        .{ .input = "P", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDate, .str = "P" },
        }) },
        .{ .input = "PP", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDate, .str = "PP" },
        }) },
        .{ .input = "PPP", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDate, .str = "PPP" },
        }) },
        .{ .input = "PPPP", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDate, .str = "PPPP" },
        }) },
        .{ .input = "C", .res = Format.from(&[_]Segment{
            .{ .type = .CalendarSystem, .str = "C" },
        }) },
        .{ .input = "CC", .res = Format.from(&[_]Segment{
            .{ .type = .CalendarSystem, .str = "C" },
            .{ .type = .CalendarSystem, .str = "C" },
        }) },
        .{ .input = "p", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongTime, .str = "p" },
        }) },
        .{ .input = "pp", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongTime, .str = "pp" },
        }) },
        .{ .input = "ppp", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongTime, .str = "ppp" },
        }) },
        .{ .input = "pppp", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongTime, .str = "pppp" },
        }) },
        .{ .input = "Pp", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDateTime, .str = "Pp" },
        }) },
        .{ .input = "PPpp", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDateTime, .str = "PPpp" },
        }) },
        .{ .input = "PPPppp", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDateTime, .str = "PPPppp" },
        }) },
        .{ .input = "PPPPpppp", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDateTime, .str = "PPPPpppp" },
        }) },
        .{ .input = "PPp", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDate, .str = "PP" },
            .{ .type = .LocalizedLongTime, .str = "p" },
        }) },
        .{ .input = "PPPp", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDate, .str = "PPP" },
            .{ .type = .LocalizedLongTime, .str = "p" },
        }) },
        .{ .input = "PPPPppp", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDate, .str = "PPPP" },
            .{ .type = .LocalizedLongTime, .str = "ppp" },
        }) },
        .{ .input = "PPPpppp", .res = Format.from(&[_]Segment{
            .{ .type = .LocalizedLongDateTime, .str = "PPPppp" },
            .{ .type = .LocalizedLongTime, .str = "p" },
        }) },
    };

    for (test_cases) |test_case| {
        const res = try parseFormatStr(test_case.input);
        try std.testing.expectEqual(test_case.res._segs_len, res._segs_len);
        for (0..test_case.res._segs_len) |i| {
            try std.testing.expectEqualStrings(
                test_case.res._segs[i].str,
                res._segs[i].str,
            );
            try std.testing.expectEqual(
                test_case.res._segs[i].type,
                res._segs[i].type,
            );
        }
    }
}
