const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn arborDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .April, 22) catch unreachable;
}
