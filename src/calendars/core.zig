const assert = @import("std").debug.assert;
const m = @import("std").math;
const testing = @import("std").testing;

/// The Astronomical system (popularized by astronomers such as Cassini in 1740)
/// includes 0 in this count. This means we have 1 B.C., 0 B.C., 1 A.D.
/// Using int32 since FixedDate limits us to 11 million years anyways
/// Using a 32-bit int because why not? It'll prevent anybody from complaining
/// that 32,000 years from a 16 bit int isn't big enough, and I can tell anyone
/// who wants a 64-bit int to use one of my C++ libraries.
pub const AstronomicalYear = enum(i32) { _ };

/// The Anno Domini system (popularized by Venerable Bede around 731) skips 0
/// and goes 1 B.C., 1 A.D.
/// Using int32 since FixedDate limits us to 11 million years anyways
/// Using a 32-bit int because why not? It'll prevent anybody from complaining
/// that 32,000 years from a 16 bit int isn't big enough, and I can tell anyone
/// who wants a 64-bit int to use one of my C++ libraries.
pub const AnnoDominiYear = enum(i32) { _ };

/// Converts astronomical (-1, 0, 1) years to the Anno Domini (-1, 1) years
pub fn astroToAD(year: AstronomicalYear) AnnoDominiYear {
    const y = @intFromEnum(year);
    assert(y > m.minInt(i32) + 1);
    if (y > 0) {
        return @enumFromInt(y);
    }
    return @enumFromInt(y - 1);
}

/// Converts astronomical (-1, 0, 1) years to the Anno Domini (-1, 1) years
pub fn adToAstro(year: AnnoDominiYear) AstronomicalYear {
    const y = @intFromEnum(year);

    // We should never see year 0 from AnnoDomini
    assert(y != 0);

    if (y > 0) {
        return @enumFromInt(y);
    }
    return @enumFromInt(y + 1);
}

test "conversions" {
    const testCases = [_]struct {
        ad: AnnoDominiYear,
        astro: AstronomicalYear,
    }{
        .{ .ad = @enumFromInt(-1), .astro = @enumFromInt(0) },
        .{ .ad = @enumFromInt(1), .astro = @enumFromInt(1) },
        .{ .ad = @enumFromInt(-2), .astro = @enumFromInt(-1) },
        .{ .ad = @enumFromInt(2020), .astro = @enumFromInt(2020) },
        .{ .ad = @enumFromInt(-2020), .astro = @enumFromInt(-2019) },
    };

    for (testCases) |testCase| {
        try testing.expectEqual(testCase.ad, astroToAD(testCase.astro));
        try testing.expectEqual(testCase.astro, adToAstro(testCase.ad));
    }
}
