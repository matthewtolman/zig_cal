const hebrew = @import("../calendars.zig").hebrew;
const AstronomicalYear = @import("../calendars.zig").AstronomicalYear;
const std = @import("std");
const math = @import("../utils.zig").math;

const gregorianRange = @import("gregorian_range.zig");
const GregorianRange = gregorianRange.GregorianRange(3);

pub const asHebrew = struct {
    pub fn yomKippur(year: AstronomicalYear) hebrew.Date {
        return hebrew.Date{ .year = year, .month = .Tishri, .day = 10 };
    }

    pub fn roshHaShanah(year: AstronomicalYear) [2]hebrew.Date {
        return [2]hebrew.Date{
            hebrew.Date{ .year = year, .month = .Tishri, .day = 1 },
            hebrew.Date{ .year = year, .month = .Tishri, .day = 2 },
        };
    }

    pub fn sukkot(year: AstronomicalYear) hebrew.Date {
        return hebrew.Date{ .year = year, .month = .Tishri, .day = 15 };
    }

    pub fn hoshanaRabba(year: AstronomicalYear) hebrew.Date {
        return hebrew.Date{ .year = year, .month = .Tishri, .day = 21 };
    }

    pub fn shemiiAzerete(year: AstronomicalYear) hebrew.Date {
        return hebrew.Date{ .year = year, .month = .Tishri, .day = 22 };
    }

    pub fn simhatTorah(year: AstronomicalYear) hebrew.Date {
        return hebrew.Date{ .year = year, .month = .Tishri, .day = 23 };
    }

    pub fn passover(year: AstronomicalYear) hebrew.Date {
        return hebrew.Date{ .year = year, .month = .Nisan, .day = 15 };
    }

    pub fn passoverEnd(year: AstronomicalYear) hebrew.Date {
        return hebrew.Date{ .year = year, .month = .Nisan, .day = 21 };
    }

    pub fn shavou(year: AstronomicalYear) hebrew.Date {
        return hebrew.Date{ .year = year, .month = .Sivan, .day = 6 };
    }

    pub fn tuBShevat(year: AstronomicalYear) hebrew.Date {
        return hebrew.Date{ .year = year, .month = .Shevat, .day = 15 };
    }

    pub fn purim(year: AstronomicalYear) hebrew.Date {
        return hebrew.Date{
            .year = year,
            .month = hebrew.Date.lastMonthOfYear(year),
            .day = 14,
        };
    }

    pub fn taAnitEsther(year: AstronomicalYear) hebrew.Date {
        const purim_date = purim(year);
        if (purim_date.dayOfWeek() == .Sunday) {
            return purim_date.subDays(3);
        } else {
            return purim_date.subDays(1);
        }
    }

    fn postponeIfSaturday(date: hebrew.Date) hebrew.Date {
        if (date.dayOfWeek() == .Saturday) {
            return date.addDays(1);
        }
        return date;
    }

    pub fn tishahBeAv(year: AstronomicalYear) hebrew.Date {
        return postponeIfSaturday(hebrew.Date{
            .year = year,
            .month = .Av,
            .day = 9,
        });
    }

    pub fn tzomGedaliah(year: AstronomicalYear) hebrew.Date {
        return postponeIfSaturday(hebrew.Date{
            .year = year,
            .month = .Tishri,
            .day = 3,
        });
    }

    pub fn tzomTammuz(year: AstronomicalYear) hebrew.Date {
        return postponeIfSaturday(hebrew.Date{
            .year = year,
            .month = .Tammuz,
            .day = 17,
        });
    }

    pub fn yomHaShoah(year: AstronomicalYear) hebrew.Date {
        return postponeIfSaturday(hebrew.Date{
            .year = year,
            .month = .Nisan,
            .day = 27,
        });
    }

    pub fn yomHaZikkaron(year: AstronomicalYear) hebrew.Date {
        const iyyar4 = hebrew.Date{ .year = year, .month = .Iyyar, .day = 4 };
        const day_of_week = iyyar4.dayOfWeek();
        if (day_of_week == .Thursday or day_of_week == .Friday) {
            return iyyar4.dayOfWeekBefore(.Wednesday);
        } else if (day_of_week == .Sunday) {
            return iyyar4.addDays(1);
        } else {
            return iyyar4;
        }
    }

    fn omer(date: hebrew.Date) ?hebrew.Date {
        const c = date.dayDifference(passover(date).year);
        if (1 <= c or c <= 49) {
            return math.mod(i32, @intFromEnum(@floor(@as(f64, @floatFromInt(c)) / 7)), 7);
        }
        return null;
    }

    pub fn birthday(birth_date: hebrew.Date, year: AstronomicalYear) hebrew.Date {
        const last_month = hebrew.Date.lastMonthOfYear(year);
        if (birth_date.month == last_month) {
            return hebrew.Date{ .year = year, .month = last_month, .day = birth_date.day };
        } else {
            return (hebrew.Date{ .year = year, .month = birth_date.month, .day = 1 }).addDays(birth_date.day - 1);
        }
    }

    pub fn yahrzeit(death_date: hebrew.Date, year: AstronomicalYear) hebrew.Date {
        if (death_date.month == .Marheshvan and death_date.day == 30 and !hebrew.Date.longMarheshvanY(year)) {
            return (hebrew.Date{ .year = year, .month = .Kislev, .day = 1 }).subDays(1);
        } else if (death_date.month == .Kislev and death_date.day == 30 and hebrew.Date.shortKislevY(year)) {
            return (hebrew.Date{ .year = year, .month = .Tevet, .day = 1 }).subDays(1);
        } else if (death_date.month == .Adar_II) {
            return (hebrew.Date{ .year = year, .month = hebrew.Date.lastMonthOfYear(year), .day = death_date.day });
        } else if (death_date.month == .Adar and death_date.day == 30 and !hebrew.Date.leapYear(year)) {
            return hebrew.Date{ .year = year, .month = .Shevat, .day = 30 };
        } else {
            return (hebrew.Date{ .year = year, .month = death_date.month, .day = 1 }).addDays(death_date.day - 1);
        }
    }

    pub fn sukkotIntermediateDays(year: AstronomicalYear) [6]hebrew.Date {
        return [6]hebrew.Date{
            hebrew.Date{ .year = year, .month = .Tishri, .day = 16 },
            hebrew.Date{ .year = year, .month = .Tishri, .day = 17 },
            hebrew.Date{ .year = year, .month = .Tishri, .day = 18 },
            hebrew.Date{ .year = year, .month = .Tishri, .day = 19 },
            hebrew.Date{ .year = year, .month = .Tishri, .day = 20 },
            hebrew.Date{ .year = year, .month = .Tishri, .day = 21 },
        };
    }

    pub fn passoverDays(year: AstronomicalYear) [5]hebrew.Date {
        return [5]hebrew.Date{
            hebrew.Date{ .year = year, .month = .Nisan, .day = 16 },
            hebrew.Date{ .year = year, .month = .Nisan, .day = 17 },
            hebrew.Date{ .year = year, .month = .Nisan, .day = 18 },
            hebrew.Date{ .year = year, .month = .Nisan, .day = 19 },
            hebrew.Date{ .year = year, .month = .Nisan, .day = 20 },
        };
    }

    pub fn hanukkah(year: AstronomicalYear) [8]hebrew.Date {
        var res: [8]hebrew.Date = undefined;
        for (0..res.len) |i| {
            res[i] = (hebrew.Date{ .year = year, .month = .Kislev, .day = 25 }).addDays(@intCast(i));
        }
        return res;
    }
};

pub const asGregorian = struct {
    pub fn yomKippur(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.yomKippur);
    }

    pub fn roshHaShanah(year: AstronomicalYear) gregorianRange.GregorianRange(6) {
        return gregorianRange.holidaysInGregorianYears(hebrew.Date, 2, year, asHebrew.roshHaShanah);
    }

    pub fn sukkot(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.sukkot);
    }

    pub fn hoshanaRabba(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.hoshanaRabba);
    }

    pub fn shemiiAzerete(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.shemiiAzerete);
    }

    pub fn simhatTorah(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.simhatTorah);
    }

    pub fn passover(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.passover);
    }

    pub fn passoverEnd(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.passoverEnd);
    }

    pub fn shavou(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.shavou);
    }

    pub fn tuBShevat(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.tuBShevat);
    }

    pub fn purim(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.purim);
    }

    pub fn taAnitEsther(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.taAnitEsther);
    }

    pub fn tishahBeAv(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.tishahBeAv);
    }

    pub fn tzomGedaliah(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.tzomGedaliah);
    }

    pub fn tzomTammuz(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.tzomTammuz);
    }

    pub fn yomHaShoah(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.yomHaShoah);
    }

    pub fn yomHaZikkaron(year: AstronomicalYear) GregorianRange {
        return gregorianRange.holidayInGregorianYears(hebrew.Date, year, asHebrew.yomHaZikkaron);
    }

    pub fn sukkotIntermediateDays(year: AstronomicalYear) gregorianRange.GregorianRange(3 * 6) {
        return gregorianRange.holidaysInGregorianYears(hebrew.Date, 6, year, asHebrew.sukkotIntermediateDays);
    }

    pub fn passoverDays(year: AstronomicalYear) gregorianRange.GregorianRange(3 * 5) {
        return gregorianRange.holidaysInGregorianYears(hebrew.Date, 5, year, asHebrew.passoverDays);
    }

    pub fn hanukkah(year: AstronomicalYear) gregorianRange.GregorianRange(3 * 8) {
        return gregorianRange.holidaysInGregorianYears(hebrew.Date, 8, year, asHebrew.hanukkah);
    }
};

test "build asHebrew" {
    const y: AstronomicalYear = @enumFromInt(2024);
    _ = asHebrew.birthday(.{ .year = y, .month = .Nisan, .day = 2 }, y);
    _ = asHebrew.hanukkah(y);
    _ = asHebrew.hoshanaRabba(y);
    _ = asHebrew.passoverDays(y);
    _ = asHebrew.purim(y);
    _ = asHebrew.passover(y);
    _ = asHebrew.passoverEnd(y);
    _ = asHebrew.roshHaShanah(y);
    _ = asHebrew.shavou(y);
    _ = asHebrew.sukkotIntermediateDays(y);
    _ = asHebrew.simhatTorah(y);
    _ = asHebrew.shemiiAzerete(y);
    _ = asHebrew.sukkot(y);
    _ = asHebrew.tzomTammuz(y);
    _ = asHebrew.tzomGedaliah(y);
    _ = asHebrew.tishahBeAv(y);
    _ = asHebrew.taAnitEsther(y);
    _ = asHebrew.tuBShevat(y);
    _ = asHebrew.yomKippur(y);
    _ = asHebrew.yomHaShoah(y);
    _ = asHebrew.yomHaZikkaron(y);
    _ = asHebrew.yahrzeit(.{ .year = y, .month = .Nisan, .day = 2 }, y);
}

test "build asGregorian" {
    const y: AstronomicalYear = @enumFromInt(2024);
    _ = asGregorian.hanukkah(y);
    _ = asGregorian.hoshanaRabba(y);
    _ = asGregorian.passoverDays(y);
    _ = asGregorian.purim(y);
    _ = asGregorian.passover(y);
    _ = asGregorian.passoverEnd(y);
    _ = asGregorian.roshHaShanah(y);
    _ = asGregorian.shavou(y);
    _ = asGregorian.sukkotIntermediateDays(y);
    _ = asGregorian.simhatTorah(y);
    _ = asGregorian.shemiiAzerete(y);
    _ = asGregorian.sukkot(y);
    _ = asGregorian.tzomTammuz(y);
    _ = asGregorian.tzomGedaliah(y);
    _ = asGregorian.tishahBeAv(y);
    _ = asGregorian.taAnitEsther(y);
    _ = asGregorian.tuBShevat(y);
    _ = asGregorian.yomKippur(y);
    _ = asGregorian.yomHaShoah(y);
    _ = asGregorian.yomHaZikkaron(y);
}
