const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;
const thanksgiving = @import("../usa.zig").thanksgiving;
const christmas = @import("../christian.zig").christmas;

pub fn dayBeforeThanksgiving(year: AstronomicalYear) gregorian.Date {
    return thanksgiving(year).subDays(1);
}

pub fn dayAfterThanksgiving(year: AstronomicalYear) gregorian.Date {
    return thanksgiving(year).addDays(1);
}

pub fn dayAfterChristmas(year: AstronomicalYear) gregorian.Date {
    return christmas(year).addDays(1);
}
