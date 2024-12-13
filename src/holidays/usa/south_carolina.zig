const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn confederateMemorialDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .May, 10) catch unreachable;
}

pub const dayAfterThanksgiving = @import("../usa.zig").blackFriday;
pub const dayAfterChristmas = @import("iowa.zig").dayAfterChristmas;
