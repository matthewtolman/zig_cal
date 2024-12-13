const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;
const christian = @import("../christian.zig");

pub fn goodFriday(year: AstronomicalYear) gregorian.Date {
    return christian.goodFriday(year);
}

test "california" {
    const y: AstronomicalYear = @enumFromInt(2024);
    _ = goodFriday(y);
}
