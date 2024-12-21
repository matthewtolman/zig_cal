# Zig Cal

> Currently tested with version *0.13.0* and *nightly* (last nightly `0.14.0-dev.2546+0ff0bdb4a`)

A calendar date/time formatting, parsing, math, math, and conversion library for zig.

The goal is to provide ample support for most U.S. holidays with flexibility for additional holidays. Addtionally, since not all holidays are based on the Gregorian calendar, addtional calendaring systems have been provided with conversions between calendaring systems. More calendaring systems will be added in the future as well (it takes quite a bit of time to get them added).

Date formatting is available for all included calendaring systems. Date parsing is only availble for the Gregorian calendar system (which is the most widely used). Currently for "locale-based formatting" only En-US is provided, but passing in your own locale is supported. In the future, additional locales will be added to the library.

Date parsing is also available, though it only supports the Gregorian calendar and a subset of date formatting (usually locale-specifc parsing, such as ordinals, are not supported). Date parsing supports most date formats used in network transmission for machine consumption, such as ISO 8601 (including week and weekday variants), HTTP Date header, and C asctime to name a few. No plans exist for parsing heavily localized dates which include localized month or day names or ordinasl, such as "25 de noviembre 2020" or "December 25th". No plans exist for adding date parsing to non-Gregorian calendar systems.

Basic math operations exist for adding days, getting the day of the week, getting the next day of the week/nth day of the week, etc. Currently, no advanced operations exist (e.g. "add n months" or "add n years"), but plans exist for adding those to the Gregorian calendar.

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
* Essentials - Date is rather usable and can be used in most places, but has severe formatting limitations
* Recommended - Date has met minimum bar for use in library. May have some formatting issues if calendar has specific month/day of week names

Additionally, there is a separate grading scale for customized month and day of week formatting (which is useful if the Gregorian names aren't used or the calendar has more/less than the normal amount). The customization grading system has three separate sections: Calendar name (pass/fail, part of Essentials), day of week names, and month names. Day of week names and month names have the following scale:

* Deferred - No formatting function overrides are present, relying on Gregorian system for names
* Incomplete - Some formatting functions overrides are present, but some are missing
* Complete - All formatting function overrides are present

Since customization grading is completely optional and will fallback to the Gregorian system, it has been broken out as a separate grading report.

Comptime asserts, tests, etc. can be used to enforce specific grades. Each grade result comes with a `format` function so you can print the grade report and see what is missing.

