const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn cesarChavezDay(year: AstronomicalYear) gregorian.Date {
    const usa = @import("../usa.zig");
    return usa.cesarChavezDay(year);
}

test "california" {
    const y: AstronomicalYear = @enumFromInt(2024);
    _ = cesarChavezDay(y);
}
