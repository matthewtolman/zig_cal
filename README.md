# Zig Cal

> Currently tested with version *0.13.0* and *nightly* (last nightly `0.14.0-dev.2546+0ff0bdb4a`)

A calendar date/time formatting, parsing, math, math, and conversion library for zig.

The goal is to provide ample support for most U.S. holidays with flexibility for additional holidays. Addtionally, since not all holidays are based on the Gregorian calendar, addtional calendaring systems have been provided with conversions between calendaring systems. More calendaring systems will be added in the future as well (it takes quite a bit of time to get them added).

Date formatting is available for all included calendaring systems. Date parsing is only availble for the Gregorian calendar system (which is the most widely used). Currently for "locale-based formatting" only En-US is provided, but passing in your own locale is supported. In the future, additional locales will be added to the library.

Date parsing is also available, though it only supports the Gregorian calendar and a subset of date formatting (usually locale-specifc parsing, such as ordinals, are not supported). Date parsing supports most date formats used in network transmission for machine consumption, such as ISO 8601 (including week and weekday variants), HTTP Date header, and C asctime to name a few. No plans exist for parsing heavily localized dates which include localized month or day names or ordinasl, such as "25 de noviembre 2020" or "December 25th". No plans exist for adding date parsing to non-Gregorian calendar systems.

Basic math operations exist for adding days, getting the day of the week, getting the next day of the week/nth day of the week, etc. Gregorian and Julian calendars have operations for adding weeks, months, and years to a date. DateTime and DateTimeZoned have methods to add hours, minutes, and seconds to a date. The Gregorian calendar system also provides a month iterator.

Dates for various calendar systems generally come in three flavors: date-only (Date), datetime (DateTime), and zoned datetime (DateTimeZoned). This allows for use of only what is needed for an application (e.g. some financial calculations only care about the Date, not the date and time in a timezone).

A general-purpose `convert` function is available to convert from any date/datetime/zoned datetime to any other date/datetime/zoned datetime, including custom calendar systems that meet a basic "Bare" grade. When time or timezone information needs to be inferred, the start of the day and UTC will be chosen.

Unix timestamps are also provided in both seconds and milliseconds as a separate calendar system.

For Day of Week in formatting we follow the ISO standard (1 for Monday, 7 for Sunday). For numerical values, we follow the Gregorian standard with 0 based indexing (0 for Sunday, 6 for Saturday).

Since some calendaring systems use Anno Domini year numbering (no 0 year) while others use Astronomical year numbering (0 year for 1 B.C.), two enums have been provided to avoid accidental casts, and two conversion methods have been provided to help in converting between the two.

## Supported Calendars

Currently these are the supported calendaring systems:

* Gregorian
* Fixed (intermediate calendar for conversions)
* Unix Timestamp (seconds and milliseconds)
* ISO
* Julian
* Hebrew (Approximate)

## Date Formatting

Date formatting uses format strings with the following sequences:

| Character(s) | Meaning |
---------------|---------|
| Y... | Year. Repeated occurrences determines padding. 1 B.C. is 0. 2 B.C. is -1 |
| Yo | Year in ordinal format based on locale (e.g. 2024th) |
| y | Anno Domini year. All years are unsigned, so use with an era. No padding. |
| yo | Anno Domini year in ordinal (e.g. 2021st)|
| yy | Year minus 2000 to 2 digits (i.e. 2 digit year for years after 2000) |
| yyy | year minus 2000 to 3 digits (i.e. 3 digit year for years after 2000) |
| yyyy... | Anno domini year with 4 padding. Can add more `y` to increase padding |
| u... | Signed Year where '+' is for AD and '-' for B.C. Repeated occurrences determines padding. |
| G, GG, GGG | Era designator, short. Based on locale |
| GGGG | Era designator long. Based on locale |
| R | Week in year. For Gregorian, this is the ISO week. |
| RR... | Week in year padded to number of occurrences of R. For Gregorian, this is the ISO week. |
| Ro | Week in year in ordinal (e.g 4th) |
| Q | Quarter (e.g. 1) |
| Qo | Quarter in ordinal form |
| QQ | Quarter padded to 2 digits |
| QQQ | Quarter prefixed with Q (e.g. Q1). Locale can change prefix/ordering. |
| QQQQ | Quarter spelled out with number (e.g. Quarter 1). Based on locale |
| M | Month number, no padding |
| MM | Month number padded to 2 digits |
| MMM | Month name short (based on either calendar overrides or locale) |
| MMMM | Month name full (based on either calendar overrides or locale) |
| MMMMM | Month name first leter (based on either calendar overrides or locale) |
| d | Day of month |
| dd | Day of month, 2 padding |
| do | Day of month, ordinal |
| D... | Day of year (e.g. 236). Repitition determins padding |
| Do | Day of year in ordinal form |
| e | Day of week (1 - Monday, 7 - Sunday) |
| ee | Day of week padded to 2 digits |
| eee | Day of week name short (e.g. Tue). Based on calendar overrides or locale |
| eeee | Day of week name full (e.g. Tuesday) Based on calendar overrides or locale |
| eeeee | Day of week name first letter (e.g. T) Based on calendar overrides or locale |
| eeeeee | Day of week name first 2 letters (e.g. Tu) Based on calendar overrides or locale |
| eo | Day of week number in ordinal form (e.g. 1st) |
| a, aa | Time of day based on locale (e.g. a.m., PM, etc) |
| A, AA | Time of day upper (AM, PM) |
| AAA | Time of day lower (am, pm) |
| AAAA | Time of day lower with periods (a.m., p.m.) |
| AAAAA | Time of day lower, first letter (a, p) |
| h | Hour, 12-houring system |
| hh | Hour, 12-houring system 2 padding |
| ho | Hour, 12-houring system ordinal |
| H | Hour, 24-houring system |
| HH | Hour, 24-houring system, 2 padding |
| Ho | Hour, 24-houring system ordinal |
| m | Minute, no padding |
| mm | Minute, 2 padding |
| mo | Minute, ordinal |
| s | Second, no padding |
| ss | Second, 2 padding |
| so | Second, ordinal |
| S... | Fraction of a second. Number of S's determine precision. Up to nanosecond supported |
| X | Timezone offset from UTC. Z used for UTC. No delimiter, compact (e.g. -08, +0530, Z) |
| XX | Timezone offset from UTC. Z used for UTC. No delimiter (e.g. -0800, +0530, Z) |
| XXX | Timezone offset from UTC. Z used for UTC. Colon delimiter (e.g. -08:00, +05:30, Z) |
| x | Timezone offset from UTC. No delimiter, compact (e.g. -08, +0530, +00) |
| xx | Timezone offset from UTC. No delimiter (e.g. -0800, +0530, +0000) |
| xxx | Timezone offset from UTC. Colon delimiter (e.g. -08:00, +05:30, +00:00) |
| O | GMT offset, short. GMT/UTC timezone is shown as "GMT" (e.g. GMT+05, GMT-1020, GMT) |
| OO, OOO | GMT offset, short (e.g. GMT+05, GMT-10:20, GMT+00) |
| OOOO | GMT offset, full (e.g. GMT+05:00, GMT-10:20, GMT+00:00) |
| P..PPPP | Localized date. Number of characters determines variant |
| p..pppp | Localized time. Number of characters determines variant |
| Pp..PPPPpppp | Localized date time. Number of characters determines variant. Upper and lower p count must match. |
| C | Calendar system name |
| '...' | Quoted text, will output contents. \' and \\ are allowed for escaping in quotes |
| \. | Escape following character (don't interpret as a command) |
| ... | Everything else is treated as plain text and will be output as-is |

Note: Only 128 control segments (including text) are allowed in a format string. Escaped characters are wrapped up as part of the surrounding text segment and don't count towards that total (though each quoted text segment does count separately). For my use cases, 128 is way too high and I may consider lowering it in the future.

## Date parsing format strings

Date parsing strings are similar to date format strings (and use the same tokenizer under the hood). However, date parsing is more constrained due to the following:
* Date parsing does not understand locales (it's already enough work to format for different locales, I'm not going to add parsing to the mix)
    * This means anything that relies on locale data is either locked to EN-US (e.g. month names) or is not supported (e.g. all ordinal options)
* Only parsing into Gregorian is supported
* Things that are too ambiguous (e.g. "first letter of day of week") is not supported
* Quarters are not supported
* Padding minimum requirements are not enforced. This means that "YYYY" will parse "24" and "2024" just fine
* Passing in padding will only consume _up to_ that number of characters. So for 20240605 a format of "YYYYMMdd" will consume 4 characters for year (2024), two for month (06), and two for day (05). Likewise, "MMddYYYY" will consume 2 for month (20), 2 for day (24), 4 for year (0605).
* If there is conflicting information, then an error will be thrown (e.g. if day of year is 12 but month is 10, then an error will be returned)
* Parsing is case insensitive where possible (so Ad, aD, AD, ad are all the same)

For accepting the most dates, it is recommended to not include padding unless padding is required for correct parsing (which happens when there are no delimiters between pieces).

The table of what is allowed for parsing strings is as follows:

| Character(s) | Meaning |
---------------|---------|
| Y... | Year. Repeated occurrences determines padding. 1 B.C. is 0. 2 B.C. is -1 |
| y | Anno Domini year. All years are unsigned, so use with an era. If no era is found, assumes A.D. |
| yy | 2 digit year plus 2000 (i.e. 2 digit year for years after 2000) |
| yyy | 3 digit year plus 2000 (i.e. 3 digit year for years after 2000) |
| yyyy... | Anno domini year with 4 padding. Can add more `y` to increase padding |
| u... | Signed Year where '+' is for AD and '-' for B.C. Repeated occurrences determines padding. |
| G, GG, GGG | Era designator (supports ad, a.d., ce, c.e., bc, b.c., bce, b.c.e.) |
| GGGG | Era designator long. (supports "anno domini", "before christ", "current era", "before current era") |
| R.. | ISO week in year |
| M, MM | Month number |
| MMM | Month name short (Jan, Jun, Jul, etc) |
| MMMM | Month name full (January, June, July, etc.) |
| d, dd | Day of month |
| D... | Day of year (e.g. 236) |
| e | Day of week (1 - Monday, 7 - Sunday) |
| ee | Day of week padded to 2 digits |
| eee | Day of week name short (e.g. Tue). Based on calendar overrides or locale |
| eeee | Day of week name full (e.g. Tuesday) Based on calendar overrides or locale |
| eeeeee | Day of week name first 2 letters (e.g. Tu) Based on calendar overrides or locale |
| a, aa | Time of day (any of the A..AAAAA variants) |
| A, AA | Time of day upper (AM, PM) |
| AAA | Time of day lower (am, pm) |
| AAAA | Time of day lower with periods (a.m., p.m.) |
| AAAAA | Time of day lower, first letter (a, p) |
| h | Hour, 12-houring system |
| hh | Hour, 12-houring system 2 padding |
| H | Hour, 24-houring system |
| HH | Hour, 24-houring system, 2 padding |
| m | Minute, no padding |
| mm | Minute, 2 padding |
| s | Second, no padding |
| ss | Second, 2 padding |
| S... | Fraction of a second. Number of S's determine precision. Up to nanosecond supported |
| X, XX, XXX | Timezone offset from UTC. Z used for UTC. (e.g. -08, +0530, Z, -04:34) |
| x, xx, xxx | Timezone offset from UTC. (e.g. -08, +0530, +00, +01:00) |
| O | GMT offset, short. GMT/UTC timezone is shown as "GMT" (e.g. GMT+05, GMT-1020, GMT) |
| OO, OOO, OOOO | GMT offset (e.g. GMT+05, GMT-10:20, GMT+00, GMT-01:00) |
| '...' | Quoted text, will match contents. \' and \\ are allowed for escaping in quotes |
| \. | Escape following character (don't interpret as a command) |
| ... | Everything else is treated as plain text and will be matched as-is |

## Holidays

The `holidays` sub-module includes many different holidays. There are several christain holidays (e.g. easter, christmas, pentecost), eastern orthodox holidays (e.g. theophany), U.S. holidays (e.g. Independence Day, Thanksgiving), and U.S. state holidays. I am slowly adding more, but my goal is to not be a source for all holidays. I'm mostly adding holidays to have a basic baseline to ensure I have a solid enough foundation for calculating holidays, and to demonstrate how holidays are calculated. The goal is that anybody can use this library to easily calculate whatever holiday is needed.

Mandatory disclaimer for internet people who don't understand how holidays and calendars work - especially in regards to American politics. I have included political holidays. Some of those holidays may be offensive to you - especially if you have very different political beliefs from the people who practice that holiday. I also have not included every holiday that may be "legal" in a state but isn't actually observed. The holidays I did include are the holidays on the official state holiday schedules published by the appropriate governing body of each one of the 50 states. If a state has a holiday with the same name and date as the U.S. Federal holiday schedule, then that holiday is left out of the state schedule. That means some state governments which only observe federal holidays don't have anything in their file. It also means, if a state renames a holiday (which is common) - even if the rename is offensive - then I have the rename reflected in their file. Furthermore, if a holiday is "official" but not observed by the state government (i.e. in their state legal code but not on their holiday schedule), I have left it out (mostly since I don't want to dig through 50 state legal codes looking for holidays). Furthermore, if a state's schedule was difficult for me to find, then I will use the most authorative secondary sources I could find. Additionally, if a holiday is listed as "optional" I will still try to include it - even if it's only practiced in a single county.

### Rules around Holidays

* I will not remove a holiday simply because it is offensive or you don't like it. I don't like all the holidays that are practiced, but the holidays that are included here are legally observed holidays in the US on either the Federal or a state holiday schedule. The names I use are from those schedules. I have found some of the names used either problematic or offensive, but those are the legal names used on legal documents. The "problem" is not the inclusion of offensive holidays in this library. The "problem" is the complex historical, social, political, and cultural strife that exists in America and a "solution" to said problem needs to happen across generations with extensive de-polarization and increased unification of America. If that isn't something you want, then don't complain about someone else's holidays because they don't like yours either.
* I will not add a holiday simply because it's "your favorite" or even if it's a legal holiday in a legal code somewhere but no government body observes it. I don't have "Valentine's Day" included simply because it's not part of a legal holiday schedule that I could find. I do like Valentine's day, I do celebrate it, but I don't include it here because it's not part of a legal calendar schedule, and I don't want to open this library up to a bunch of meaningless pull requests to add "My doggie's birthday Pweeeaasee UwU". If your favorite holiday is missing and it's not part of a US Federal or State observance schedule, then either fork this repository and add it, or create a new library and use this as a dependency.
* I will not add one-off or "governor's choice" holidays. Yes, they exist, and they are essentially "the govenor can designate a day as a state holiday because why not?" These holidays are only announced at most a year in advance, there is really poor record keeping for historical data, and to properly support it I'd have to rely on a web service (probably mine) that is publishing updates over the internet to every application that uses this library. I don't want to do that, so I'm not adding "govenor's choice" holidays.
* I am not adding the "observed" day for holidays which fall on weekends. While there are generally basic rules (e.g. Saturday -> Friday, Sunday -> Monday), with how much govenor power is involved with moving holidays I'm not going to touch it. I'm not touching that, it's not being included, if you need it, figure out what the rule is for your jurisdiction (or just do the Sat -> Fri, Sun -> Mon thing).
* I'm not going to add "govenor changes" to holidays on the schedule. These changes are essentially "well, I didn't like that holiday fell on day X this year, so I'm moving it to day Y for this year only." Instead, I'm only supporting the normal, typical date for the holiday.
* Some calendars that I use for holidays are approximate (e.g. the Hebrew calendar). The "observational" calendars require a lot more math and I haven't written them yet, and even then they may still be approximate because real life authorities can adjust calendars as needed. I'm not updating everything based on real life authorities, so some dates may be off. If you report a bug for a holiday based on an approximate calendar, I may just close it because the calendar is approximate.


## Calendar Grading and Feature Set System

To assist in developing and maintaining calendars - especially as new functionality and features are added across calendars - a calendar grading system has been developed as part of the library. This system will not only categorize a calendar by quality level, but it will also output a list of anything that is missing. This allows us to handle larger changes more easily.

Grading works by first using reflection to detect a calendar's "feature set" (what it can do). That feature set is then compared against lists of predetermined ranks to determine the "grade". For a full list of features, see `src/utils/features.zig` and look at the `Features` enum. It's way too long to list here.

Grades vary based on the type of date being evaluated (Date, DateTime, DateTimeZoned). DateTime and DateTimeZoned use composition for their features, so they rely on the underlying Date for functionality. Reflection is used to ensure correct dispatch when a Date is present (e.g. call `month()` on the contained `Date` not on the `DateTime`). Because of that, grades for DateTime and DateTimeZoned will include a separate rating for their underlying Date type, and if the underlying Date type has a poor grade then the combined type will also have a poor grade.

Grades are split into the following ratings:

* Incomplete - Usability minimums are not meant, cannot use as a "calendar" with this library
* Bare - Bare minimum met for `convert` to work, but requires conversions for more advanced usage
* Essentials - Date is rather usable and can be used in most places in the library, but has severe formatting limitations
* Recommended - Date will operate correctly in most places with the only exception being if month/day of week names are not based on the Gregorian calendar (a separate customization scale is available)

Additionally, there is a separate grading scale for customized month and day of week formatting (which is useful if the Gregorian names aren't used or the calendar has more/less than the normal amount). The customization grading system has three separate sections: Calendar name (pass/fail, part of Essentials), day of week names, and month names. Day of week names and month names have the following scale:

* Deferred - No formatting function overrides are present, relying on Gregorian system for names
* Incomplete - Some formatting functions overrides are present, but some are missing
* Complete - All formatting function overrides are present

Since customization grading is completely optional and will fallback to the Gregorian system, it has been broken out as a separate grading report.

Comptime asserts, tests, etc. can be used to enforce specific grades. Each grade result comes with a `format` function so you can print the grade report and see what is missing.



