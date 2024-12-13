const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub const lincolnsBirthday = @import("connecticut.zig").lincolnsBirthday;

pub fn trumanDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .May, 8) catch unreachable;
}
