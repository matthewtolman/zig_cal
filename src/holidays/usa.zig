const gregorian = @import("../calendars.zig").gregorian;
const AstronomicalYear = @import("../calendars.zig").AstronomicalYear;
const std = @import("std");

pub fn independenceDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .July, 4) catch unreachable;
}

pub fn laborDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .September, 1) catch unreachable;
    return base.firstWeekDay(.Monday);
}

pub fn memorialDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .May, 31) catch unreachable;
    return base.lastWeekDay(.Monday);
}

pub fn electionDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .November, 2) catch unreachable;
    return base.firstWeekDay(.Tuesday);
}

pub fn thanksgiving(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .November, 1) catch unreachable;
    return base.nthWeekDay(4, .Thursday);
}

pub fn blackFriday(year: AstronomicalYear) gregorian.Date {
    return thanksgiving(year).addDays(1);
}

pub fn newYears(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .January, 1) catch unreachable;
}

pub fn newYearsEve(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .December, 31) catch unreachable;
}

pub fn presidentsDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .February, 1) catch unreachable;
    return base.nthWeekDay(3, .Monday);
}

pub fn cesarChavezDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .March, 31) catch unreachable;
}

pub fn georgeWashingtonBirthday(year: AstronomicalYear) gregorian.Date {
    return presidentsDay(year);
}

pub fn juneteenth(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .June, 19) catch unreachable;
}

pub fn columbusDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .October, 1) catch unreachable;
    return base.nthWeekDay(2, .Monday);
}

pub fn indigenousPeoplesDay(year: AstronomicalYear) gregorian.Date {
    return columbusDay(year);
}

pub fn americanIndianHeritageDay(year: AstronomicalYear) gregorian.Date {
    return indigenousPeoplesDay(year);
}

pub fn veteransDay(year: AstronomicalYear) gregorian.Date {
    return gregorian.Date.init(year, .November, 11) catch unreachable;
}

pub fn martinLutherKingJrDay(year: AstronomicalYear) gregorian.Date {
    const base = gregorian.Date.init(year, .January, 1) catch unreachable;
    return base.nthWeekDay(3, .Monday);
}

pub fn christmas(year: AstronomicalYear) gregorian.Date {
    return @import("christian.zig").christmas(year);
}

pub fn christmasEve(year: AstronomicalYear) gregorian.Date {
    return @import("christian.zig").christmasEve(year);
}

const alabama = @import("usa/alabama.zig");
const alaska = @import("usa/alaska.zig");
const arizona = @import("usa/arizona.zig");
const arkansas = @import("usa/arkansas.zig");
const california = @import("usa/california.zig");
const colorado = @import("usa/colorado.zig");
const connecticut = @import("usa/connecticut.zig");
const delaware = @import("usa/delaware.zig");
const florida = @import("usa/florida.zig");
const georgia = @import("usa/georgia.zig");
const hawaii = @import("usa/hawaii.zig");
const idaho = @import("usa/idaho.zig");
const illinois = @import("usa/illinois.zig");
const indiana = @import("usa/indiana.zig");
const iowa = @import("usa/iowa.zig");
const kansas = @import("usa/kansas.zig");
const kentucky = @import("usa/kentucky.zig");
const louisiana = @import("usa/louisiana.zig");
const maine = @import("usa/maine.zig");
const maryland = @import("usa/maryland.zig");
const massachusetts = @import("usa/massachusetts.zig");
const michigan = @import("usa/michigan.zig");
const minnesota = @import("usa/minnesota.zig");
const mississippi = @import("usa/mississippi.zig");
const missouri = @import("usa/missouri.zig");
const montana = @import("usa/montana.zig");
const nebraska = @import("usa/nebraska.zig");
const nevada = @import("usa/nevada.zig");
const new_hampshire = @import("usa/new_hampshire.zig");
const new_jersey = @import("usa/new_jersey.zig");
const new_mexico = @import("usa/new_mexico.zig");
const new_york = @import("usa/new_york.zig");
const north_carolina = @import("usa/north_carolina.zig");
const north_dakota = @import("usa/north_dakota.zig");
const ohio = @import("usa/ohio.zig");
const oklahoma = @import("usa/oklahoma.zig");
const oregon = @import("usa/oregon.zig");
const pennsylvania = @import("usa/pennsylvania.zig");
const rhode_island = @import("usa/rhode_island.zig");
const south_carolina = @import("usa/south_carolina.zig");
const south_dakota = @import("usa/south_dakota.zig");
const tennessee = @import("usa/tennessee.zig");
const texas = @import("usa/texas.zig");
const utah = @import("usa/utah.zig");
const vermont = @import("usa/vermont.zig");
const virginia = @import("usa/virginia.zig");
const washington = @import("usa/washington.zig");
const west_virginia = @import("usa/west_virginia.zig");
const wisconsin = @import("usa/wisconsin.zig");
const wyoming = @import("usa/wyoming.zig");

test "states" {
    _ = wyoming;
    _ = wisconsin;
    _ = west_virginia;
    _ = washington;
    _ = virginia;
    _ = vermont;
    _ = utah;
    _ = texas;
    _ = tennessee;
    _ = south_dakota;
    _ = south_carolina;
    _ = rhode_island;
    _ = pennsylvania;
    _ = oregon;
    _ = oklahoma;
    _ = ohio;
    _ = north_dakota;
    _ = north_carolina;
    _ = new_york;
    _ = new_mexico;
    _ = new_jersey;
    _ = new_hampshire;
    _ = nevada;
    _ = nebraska;
    _ = montana;
    _ = missouri;
    _ = mississippi;
    _ = minnesota;
    _ = michigan;
    _ = massachusetts;
    _ = maryland;
    _ = maine;
    _ = louisiana;
    _ = kentucky;
    _ = kansas;
    _ = iowa;
    _ = indiana;
    _ = illinois;
    _ = idaho;
    _ = hawaii;
    _ = georgia;
    _ = florida;
    _ = delaware;
    _ = connecticut;
    _ = colorado;
    _ = california;
    _ = arkansas;
    _ = arizona;
    _ = alaska;
    _ = alabama;
}

test "Independence Day" {
    const year: AstronomicalYear = @enumFromInt(2018);
    const expected = gregorian.Date{ .year = year, .month = .July, .day = 4 };
    try std.testing.expectEqualDeep(expected, independenceDay(year));
}

test "Labor Day" {
    const year: AstronomicalYear = @enumFromInt(2018);
    const expected = gregorian.Date{ .year = year, .month = .September, .day = 3 };
    try std.testing.expectEqualDeep(expected, laborDay(year));
}

test "Memorial Day" {
    const year: AstronomicalYear = @enumFromInt(2018);
    const expected = gregorian.Date{ .year = year, .month = .May, .day = 28 };
    try std.testing.expectEqualDeep(expected, memorialDay(year));
}

test "Election Day" {
    const year: AstronomicalYear = @enumFromInt(2018);
    const expected = gregorian.Date{ .year = year, .month = .November, .day = 6 };
    try std.testing.expectEqualDeep(expected, electionDay(year));
}

test "Thanksgiving" {
    const TestCase = struct { year: i32, expected_day: u8 };

    const cases = [_]TestCase{
        TestCase{ .year = 2023, .expected_day = 23 },
        TestCase{ .year = 2024, .expected_day = 28 },
        TestCase{ .year = 2025, .expected_day = 27 },
        TestCase{ .year = 2026, .expected_day = 26 },
        TestCase{ .year = 1951, .expected_day = 22 },
    };

    for (cases) |c| {
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(
                @enumFromInt(c.year),
                .November,
                c.expected_day,
            ),
            thanksgiving(@enumFromInt(c.year)),
        );
    }
}

test "Black Friday" {
    const TestCase = struct { year: i32, expected_day: u8 };

    const cases = [_]TestCase{
        TestCase{ .year = 2023, .expected_day = 24 },
        TestCase{ .year = 2024, .expected_day = 29 },
        TestCase{ .year = 2025, .expected_day = 28 },
        TestCase{ .year = 2026, .expected_day = 27 },
        TestCase{ .year = 1951, .expected_day = 23 },
    };

    for (cases) |c| {
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(
                @enumFromInt(c.year),
                .November,
                c.expected_day,
            ),
            blackFriday(@enumFromInt(c.year)),
        );
    }
}

test "New Years" {
    const TestCase = struct { year: i32 };

    const cases = [_]TestCase{
        TestCase{ .year = 2023 },
        TestCase{ .year = 2024 },
        TestCase{ .year = 2025 },
        TestCase{ .year = 2026 },
        TestCase{ .year = 1951 },
    };

    for (cases) |c| {
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(@enumFromInt(c.year), .January, 1),
            newYears(@enumFromInt(c.year)),
        );
    }
}

test "New Years Eve" {
    const TestCase = struct { year: i32 };

    const cases = [_]TestCase{
        TestCase{ .year = 2023 },
        TestCase{ .year = 2024 },
        TestCase{ .year = 2025 },
        TestCase{ .year = 2026 },
        TestCase{ .year = 1951 },
    };

    for (cases) |c| {
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(@enumFromInt(c.year), .December, 31),
            newYearsEve(@enumFromInt(c.year)),
        );
    }
}

test "Presidents day" {
    const TestCase = struct { year: i32, expected_day: u8 };

    const cases = [_]TestCase{
        TestCase{ .year = 2023, .expected_day = 20 },
        TestCase{ .year = 2024, .expected_day = 19 },
        TestCase{ .year = 2025, .expected_day = 17 },
        TestCase{ .year = 2026, .expected_day = 16 },
    };

    for (cases) |c| {
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(
                @enumFromInt(c.year),
                .February,
                c.expected_day,
            ),
            presidentsDay(@enumFromInt(c.year)),
        );
    }
}

test "Juneteenth day" {
    const TestCase = struct { year: i32, expected_day: u8 };

    const cases = [_]TestCase{
        TestCase{ .year = 2023, .expected_day = 19 },
        TestCase{ .year = 2024, .expected_day = 19 },
        TestCase{ .year = 2025, .expected_day = 19 },
        TestCase{ .year = 2026, .expected_day = 19 },
    };

    for (cases) |c| {
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(
                @enumFromInt(c.year),
                .June,
                c.expected_day,
            ),
            juneteenth(@enumFromInt(c.year)),
        );
    }
}

test "Columbus day/Indigenous Peoples Day" {
    const TestCase = struct { year: i32, expected_day: u8 };

    const cases = [_]TestCase{
        TestCase{ .year = 2023, .expected_day = 9 },
        TestCase{ .year = 2024, .expected_day = 14 },
        TestCase{ .year = 2025, .expected_day = 13 },
        TestCase{ .year = 2026, .expected_day = 12 },
    };

    for (cases) |c| {
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(
                @enumFromInt(c.year),
                .October,
                c.expected_day,
            ),
            columbusDay(@enumFromInt(c.year)),
        );
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(
                @enumFromInt(c.year),
                .October,
                c.expected_day,
            ),
            indigenousPeoplesDay(@enumFromInt(c.year)),
        );
    }
}

test "Veterans Day" {
    const TestCase = struct { year: i32, expected_day: u8 };

    const cases = [_]TestCase{
        TestCase{ .year = 2023, .expected_day = 11 },
        TestCase{ .year = 2024, .expected_day = 11 },
        TestCase{ .year = 2025, .expected_day = 11 },
        TestCase{ .year = 2026, .expected_day = 11 },
    };

    for (cases) |c| {
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(
                @enumFromInt(c.year),
                .November,
                c.expected_day,
            ),
            veteransDay(@enumFromInt(c.year)),
        );
    }
}

test "Martin Luther King Jr Day" {
    const TestCase = struct { year: i32, expected_day: u8 };

    const cases = [_]TestCase{
        TestCase{ .year = 2023, .expected_day = 16 },
        TestCase{ .year = 2024, .expected_day = 15 },
        TestCase{ .year = 2025, .expected_day = 20 },
        TestCase{ .year = 2026, .expected_day = 19 },
        TestCase{ .year = 2027, .expected_day = 18 },
    };

    for (cases) |c| {
        try std.testing.expectEqualDeep(
            try gregorian.Date.init(
                @enumFromInt(c.year),
                .January,
                c.expected_day,
            ),
            martinLutherKingJrDay(@enumFromInt(c.year)),
        );
    }
}

test "sample data" {
    const sample_years = @import("test_helpers.zig").sample_years;

    // independence day
    for (sample_years) |y| {
        const year: AstronomicalYear = @enumFromInt(y);
        try std.testing.expectEqualDeep(try gregorian.Date.init(year, .July, 4), independenceDay(year));
    }

    // election day
    const expected_election_days = [_]u8{ 7, 6, 5, 4, 2, 8, 7, 6, 4, 3, 2, 8, 6, 5, 4, 3, 8, 7, 6, 5, 3, 2, 8, 7, 5, 4, 3, 2, 7, 6, 5, 4, 2, 8, 7, 6, 4, 3, 2, 8, 6, 5, 4, 3, 8, 7, 6, 5, 3, 2, 8, 7, 5, 4, 3, 2, 7, 6, 5, 4, 2, 8, 7, 6, 4, 3, 2, 8, 6, 5, 4, 3, 8, 7, 6, 5, 3, 2, 8, 7, 5, 4, 3, 2, 7, 6, 5, 4, 2, 8, 7, 6, 4, 3, 2, 8, 6, 5, 4, 3, 2, 8, 7, 6 };
    for (sample_years, expected_election_days) |y, day| {
        const year: AstronomicalYear = @enumFromInt(y);
        try std.testing.expectEqualDeep(try gregorian.Date.init(year, .November, day), electionDay(year));
    }

    const expected_labor_days = [_]u8{ 4, 3, 2, 1, 6, 5, 4, 3, 1, 7, 6, 5, 3, 2, 1, 7, 5, 4, 3, 2, 7, 6, 5, 4, 2, 1, 7, 6, 4, 3, 2, 1, 6, 5, 4, 3, 1, 7, 6, 5, 3, 2, 1, 7, 5, 4, 3, 2, 7, 6, 5, 4, 2, 1, 7, 6, 4, 3, 2, 1, 6, 5, 4, 3, 1, 7, 6, 5, 3, 2, 1, 7, 5, 4, 3, 2, 7, 6, 5, 4, 2, 1, 7, 6, 4, 3, 2, 1, 6, 5, 4, 3, 1, 7, 6, 5, 3, 2, 1, 7, 6, 5, 4, 3 };
    for (sample_years, expected_labor_days) |y, day| {
        const year: AstronomicalYear = @enumFromInt(y);
        try std.testing.expectEqualDeep(try gregorian.Date.init(year, .September, day), laborDay(year));
    }

    const expected_memorial_days = [_]u8{ 29, 28, 27, 26, 31, 30, 29, 28, 26, 25, 31, 30, 28, 27, 26, 25, 30, 29, 28, 27, 25, 31, 30, 29, 27, 26, 25, 31, 29, 28, 27, 26, 31, 30, 29, 28, 26, 25, 31, 30, 28, 27, 26, 25, 30, 29, 28, 27, 25, 31, 30, 29, 27, 26, 25, 31, 29, 28, 27, 26, 31, 30, 29, 28, 26, 25, 31, 30, 28, 27, 26, 25, 30, 29, 28, 27, 25, 31, 30, 29, 27, 26, 25, 31, 29, 28, 27, 26, 31, 30, 29, 28, 26, 25, 31, 30, 28, 27, 26, 25, 31, 30, 29, 28 };
    for (sample_years, expected_memorial_days) |y, day| {
        const year: AstronomicalYear = @enumFromInt(y);
        try std.testing.expectEqualDeep(try gregorian.Date.init(year, .May, day), memorialDay(year));
    }
}
