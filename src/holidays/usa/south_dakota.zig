const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn nativeAmericansDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .October, 1) catch unreachable;
    return base.nthWeekDay(2, .Monday);
}
