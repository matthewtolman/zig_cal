const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn victoryDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .August, 1) catch unreachable;
    return base.nthWeekDay(2, .Monday);
}
