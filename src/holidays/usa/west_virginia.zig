const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn westVirginiaDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .June, 20) catch unreachable;
}
