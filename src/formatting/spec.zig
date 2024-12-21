/// Type of a token segment
pub const SegmentType = enum {
    EraDesignatorShort, // G, GG, GGG
    EraDesignatorLong, // GGGG

    YearOrdinal, // yo, Yo
    Year, // y, yy, yyy, yyyy, ..., Y, YY, YYY, YYYY, ...
    YearIso,

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
    TextQuoted,
};
