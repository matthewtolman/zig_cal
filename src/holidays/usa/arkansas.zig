const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub fn daisyGatsonBatesDay(year: AstronomicalYear) gregorian.Date {
    const usa = @import("../usa.zig");
    return usa.presidentsDay(year);
}

test "arkansas" {
    const y: AstronomicalYear = @enumFromInt(2024);
    _ = daisyGatsonBatesDay(y);
}
