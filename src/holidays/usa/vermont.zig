const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn townMeetingDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .March, 1) catch unreachable;
    return base.firstWeekDay(.Monday);
}

pub fn benningtonBattleDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .August, 16) catch unreachable;
}
