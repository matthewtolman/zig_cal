// G, GG, GGG - era designator, short
// GGGG - era designator, long
// yo - unsigned year, ordinal
// Y - unsigned year, no padding
// YY - unsigned year, last two digits
// YYY - unsigned year, padded to 3
// YYYY - unsigned year, padded to 4
// YYYYY... - number of padding
// y - unsigned year, no padding
// yy - unsigned year, last two digits
// yyy - unsigned year, padded to 3
// yyyy - unsigned year, padded to 4
// yyyyy... - number of padding
// R - week in year
// Ro - week in year, ordinal
// RR - Week in year padded to 2
// RRR - week in year, padded to 3
// RRRRR... - number of padding
// u - signed year, no padding
// uu - signed year, 2 padding
// uuu - signed year, 3 padding
// uuuu - signed year, 4 padding
// uuuuu... - number of padding
// Qo - oridinal quartering
// Q - Quarter (stand alone)
// QQ - quarter, 2 padding
// QQQ - quarter prefixed with Q
// QQQQ - long text
// M - Month, no padding
// MM - Month, 2 padding
// MMM - Month, three letter padding
// MMMM - Month, long text
// MMMMM - Month, first letter
// do - day of month, ordinal
// d - day of month, no padding
// dd - day of month, 2 padding
// Do - day of year, ordinal
// D - day of year, no padding
// DD - day of year, 2 padding
// DDD... - number of padding
// eo - ordinal day of week
// e - day of week
// ee - day of week, 2 padding
// eee - day of week, short
// eeee - day of week, full name
// eeeee - day of week, first letter
// eeeeee - day of week, first two letters
// a, aa - time of day, locale (AM, PM)
// A, AA - time of day, upper (AM, PM)
// AAA - time of day, lower (am, pm)
// AAAA - time of day, lower, period (a.m., p.m.)
// AAAAA - time of day, loewr, first leter (a, p)
// ho - short hour (1-12), ordinal
// h - short hour (1-12), no padding
// hh - short hour (1-12), 2 padding
// Ho - full hour (1-24), ordinal
// H - full hour (1-24), no padding
// HH - full hour (1-24), 2 padding
// mo - minute, ordinal
// m - minute, no padding
// mm - minute, 2 padding
// so - second, ordinal
// s - second, no padding
// ss - second, 2 padding
// S - fraction of a second, 1 digit
// SS... - fraction of a second, number digits
// X - Timezone offset, with Z, undeliminated, min 2 (-08, +0530, Z)
// XX - Timezone offset, with Z, undeliminated, min 4 (-0800, +0530, Z)
// XXX - Timezone offset, with Z, deliminated (-08:00, +05:30, Z)
// x - Timezone offset, without Z, undeliminated, min 2 (-08, +0530)
// xx - Timezone offset, without Z, undeliminated, min 4 (-0800, +0530)
// xxx - Timezone offset, without Z, deliminated (-08:00, +05:30)
// O..OOO - GMT offset (GMT-8, GMT+5:30, GMT+0)
// OOOO - GMT offset, full (GMT-08:00)
// P..PPPP - Localized date
// p..pppp - Localized time
// Pp, PPpp, PPPppp, PPPPpppp - Localized date time combination
// C - Calendar system

/// Type of a token segment
pub const SegmentType = enum {
    EraDesignatorShort, // G, GG, GGG
    EraDesignatorLong, // GGGG

    YearOrdinal, // yo, Yo
    Year, // y, yy, yyy, yyyy, ..., Y, YY, YYY, YYYY, ...

    WeekInYearOrdinal, // Ro
    WeekInYear, // R, RR, RRR, ...

    SignedYear, // u, uu, uuu, uuuu, ...

    QuarterOrdinal, // Qo
    QuarterNum, // Q, QQ
    QuarterPrefixed, // QQQ
    QuarterLong, // QQQQ

    MonthNum, // M, MM
    MonthNameShort, // MMM
    MonthNameLong, // MMMM
    MonthNameFirstLetter, // MMMMM

    DayOfMonthOrdinal, // do
    DayOfMonthNum, // d, dd

    DayOfYearOrdinal, // Do
    DayofYearNum, // D, DD, DDD, ....

    DayOfWeekOrdinal, // eo, Eo
    DayOfWeekNum, // e, ee, E, EE
    DayOfWeekNameShort, // eee, EEE
    DayOfWeekNameFull, // eeee, EEEE
    DayOfWeekNameFirstLetter, // eeeee, EEEEE
    DayOfWeekNameFirst2Letters, // eeeeee, EEEEEE

    TimeOfDayLocale, // a, aa
    TimeOfDayAM, // A, AA
    TimeOfDay_am, // AAA
    TimeOfDay_a_m, // AAAA
    TimeOfDay_ap, // AAAAA

    Hour12Ordinal, // ho
    Hour12Num, // h, hh

    Hour24Ordinal, // Ho
    Hour24Num, // H, HH

    MinuteOrdinal, // mo
    MinuteNum, // m, mm

    SecondOrdinal, // so
    SecondNum, // s, ss

    FractionOfASecond, // S, SS, ...

    TimezoneOffsetZ, // X, XX, XXX, XXXX, XXXXX

    TimezoneOffset, // x, xx, xxx, xxxx, xxxxx

    GmtOffset, // O, OO, OOOO
    GmtOffsetFull, // OOOO

    LocalizedLongDate, // P, PP, PPP, PPPP
    LocalizedLongTime, // p, pp, ppp, pppp

    LocalizedLongDateTime, // Pp, PPpp, PPPppp, PPPPpppp

    CalendarSystem, // C

    Text,
};
