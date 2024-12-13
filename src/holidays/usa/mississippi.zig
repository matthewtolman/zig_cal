const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub const robertELeesBirthday = @import("../usa.zig").martinLutherKingJrDay;

pub fn confederateMemorialDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .April, 30) catch unreachable;
    return base.lastWeekDay(.Monday);
}

pub const jeffersonDavisBirthday = @import("../usa.zig").memorialDay;

pub const armistice = @import("../usa.zig").veteransDay;

pub fn elvisAaronPresleyDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .August, 16) catch unreachable;
}

pub fn hernandoDeSotoDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .May, 8) catch unreachable;
}
