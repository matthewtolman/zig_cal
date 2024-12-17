const hebrew = @import("../calendars.zig").hebrew;
const AstronomicalYear = @import("../calendars.zig").AstronomicalYear;
const std = @import("std");
const math = @import("../utils.zig").math;

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
        return iyyar4.day_of_week_before(.Wednesday);
    } else if (day_of_week == .Sunday) {
        return iyyar4.add_days(1);
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
        return (hebrew.Date{ .year = year, .month = birth_date.month, .day = 1 }).add_days(birth_date.day - 1);
    }
}

pub fn yahrzeit(death_date: hebrew.Date, year: AstronomicalYear) hebrew.Date {
    if (death_date.month == .Marheshvan and death_date.day == 30 and !hebrew.Date.longMarheshvanY(year)) {
        return (hebrew.Date{ .year = year, .month = .Kislev, .day = 1 }).sub_days(1);
    } else if (death_date.month == .Kislev and death_date.day == 30 and hebrew.Date.shortKislevY(year)) {
        return (hebrew.Date{ .year = year, .month = .Tevet, .day = 1 }).sub_days(1);
    } else if (death_date.month == .Adar_II) {
        return (hebrew.Date{ .year = year, .month = hebrew.Date.lastMonthOfYear(year), .day = death_date.day });
    } else if (death_date.month == .Adar and death_date.day == 30 and !hebrew.Date.leapYear(year)) {
        return hebrew.Date{ .year = year, .month = .Shevat, .day = 30 };
    } else {
        return (hebrew.Date{ .year = year, .month = death_date.month, .day = 1 }).add_days(death_date.day - 1);
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
        res[i] = (hebrew.Date{ .year = year, .month = .Kislev, .day = 25 }).addDays(i);
    }
    return res;
}
