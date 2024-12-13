pub const goodFriday = @import("../christian.zig").goodFriday;

const gregorian = @import("../../calendars.zig").gregorian;
const AstronomicalYear = @import("../../calendars.zig").AstronomicalYear;

pub const lincolnsBirthday = @import("../usa.zig").blackFriday;

test "indiana" {
    const testing = @import("std").testing;
    const expectEqualDeep = testing.expectEqualDeep;
    const Date = gregorian.Date;

    try expectEqualDeep(
        try Date.initNums(2024, 11, 29),
        lincolnsBirthday(@enumFromInt(2024)),
    );

    try expectEqualDeep(
        try Date.initNums(2025, 11, 28),
        lincolnsBirthday(@enumFromInt(2025)),
    );
}
