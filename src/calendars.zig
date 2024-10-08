const epochs = @import("./epochs.zig");
const time = @import("./time.zig");
const math = @import("./math.zig");
const testing = @import("std").testing;
const assert = @import("std").debug.assert;
const m = @import("std").math;
const fmt = @import("std").fmt;
const mem = @import("std").mem;

// A 32-bit int gives us 11 million years.
// A 64-bit integer can represent way more than 11 million years.
//
// However, past a few hundred thousand years the whole "calendar" concept
// should really be done away with. For one the precision of "Earth days"
// doesn't make any sense when talking about dinosaurs or the Big Bang. Even
// individual years doesn't make much sense at that level. For one, we don't
// even have precise day (or often year) data at that time scale, so there's not
// much point in saying "this dinosaur bone died on this day". Even if we did,
// there's not much point in pinning it to a single day. What benefit do we get
// if the Big Bang happened in what would have been our February or March had
// our earth existed over 14 billion years ago? Why does that even matter?
//
// Because of the ridiculousness of trying to apply calendars past a certain
// threshold, I'm not even going to try to support it. All of our calendars fall
// apart at a large enough timescale. It doesn't matter because our lives are
// not even close to that time scale. Most civilizations collapse either well
// before their calendar system collapses (if it's a really, really good
// calendar), they replace it with a new system once it collapses, or they
// collapse around the same time the calendar system collapses. For really bad
// calendar systems they still are fairly accurate for hundreds of years, and
// even then their "inaccuracy" is with seasonal drift. Hundreds of years is
// long enough for an individual to worry about. This library will support
// millions of years. I can definitely sleep at night with a measly 32-bit
// number.
//
// If you really want a 64-bit int for the FixedDate, see my C++ versions
//      non-constexper version: https://gitlab.com/mtolman/calendars
//      constexpr version: https://gitlab.com/mtolman/calendar-constexpr
pub const FixedDate = struct { dayCount: i32 };

/// Represents the gregorian months
pub const GregorianMonth = enum(u8) {
    January = 1,
    February,
    March,
    April,
    May,
    June,
    July,
    August,
    September,
    October,
    November,
    December,
};

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
pub fn astronomicalToAnnoDomini(year: AstronomicalYear) AnnoDominiYear {
    const y = @intFromEnum(year);
    assert(y > m.minInt(i32) + 1);
    if (y > 0) {
        return @enumFromInt(y);
    }
    return @enumFromInt(y - 1);
}

/// Converts astronomical (-1, 0, 1) years to the Anno Domini (-1, 1) years
pub fn annoDominiToAstronomical(year: AnnoDominiYear) AstronomicalYear {
    const y = @intFromEnum(year);

    // We should never see year 0 from AnnoDomini
    assert(y != 0);

    if (y > 0) {
        return @enumFromInt(y);
    }
    return @enumFromInt(y + 1);
}

/// Represents a date on the Gregorian Calendar system.
/// This calendar uses the Astronomical year counting system which includes 0.
/// Year 0 correspondes to 1 B.C. on the Anno Domini system of counting.
///
/// To make the year system explicit, we have "distinct int types" through
/// non-exhaustive enums.
///
/// If you don't like Year 0, then take a look at how we exclude it with the
/// JulianDate and then make your own version with it excluded.
///
/// Note that the year is a 32-bit signed integer
/// This means we can represent a large chunk of the earth's history, but
/// probably not all of it and definitely not the history of the universe.
/// Which is okay. Usually when needing that kind of timescale you'll be using
/// either the geologic time scale or cosmic calendar rather than the gregorian
/// calendar. Keeping track of the Gregorian leap years is less significant
/// when plotting out the events that happened after the big bang.
pub const GregorianDate = struct {
    year: AstronomicalYear = @enumFromInt(0),
    month: GregorianMonth = .January,
    day: u8 = 1,

    /// Checks whether the gregorian date is a leap year or not
    fn isLeapYear(self: GregorianDate) bool {
        const y = @intFromEnum(self.year);
        if (math.mod(i32, y, 4) != 0) {
            return false;
        }

        const yearMod400 = math.mod(i32, y, 400);
        return yearMod400 != 100 and yearMod400 != 200 and yearMod400 != 300;
    }

    /// Formats Gregorian Calendar into string form
    /// Format of "s" will do human readable date string with Anno Domini year
    ///     (e.g. March 23, 345 B.C.    April 3, 2023 A.D.)
    /// Default format (for any other format type) will do -?YYYY-MM-DD with
    /// astronomical year.
    /// If year is negative, will prefix date with a "-", otherwise will not
    ///     (e.g. -0344-03-23       2023-04-03)
    pub fn format(self: GregorianDate, comptime f: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
        _ = options;

        if (mem.eql(u8, f, "s")) {
            const y = @intFromEnum(astronomicalToAnnoDomini(self.year));
            const month = @tagName(self.month);
            const adOrBc = if (y > 0) "A.D." else "B.C.";
            const yAbs = @as(u32, @intCast(y * m.sign(y)));

            try writer.print("{s} {d}, {d} {s}", .{ month, self.day, yAbs, adOrBc });
            return;
        }

        const y = @intFromEnum(self.year);
        const month = @intFromEnum(self.month);
        if (y >= 0) {
            try writer.print("{d:0>4}-{d:0>2}-{d:0>2}", .{ @as(u32, @intCast(y)), month, self.day });
        } else {
            try writer.print("-{d:0>4}-{d:0>2}-{d:0>2}", .{ @as(u32, @intCast(m.sign(y) * y)), month, self.day });
        }
    }
};

test "gregorian formatting" {
    var list = @import("std").ArrayList(u8).init(testing.allocator);
    defer list.deinit();
    const testCases = [_]struct { date: GregorianDate, expectedS: []const u8, expectedAny: []const u8 }{
        .{ .date = GregorianDate{}, .expectedS = "January 1, 1 B.C.", .expectedAny = "0000-01-01" },
        .{
            .date = GregorianDate{
                .year = @enumFromInt(2024),
                .month = .February,
                .day = 29,
            },
            .expectedAny = "2024-02-29",
            .expectedS = "February 29, 2024 A.D.",
        },
        .{ .date = GregorianDate{
            .year = @enumFromInt(-2024),
            .month = .February,
            .day = 29,
        }, .expectedAny = "-2024-02-29", .expectedS = "February 29, 2025 B.C." },
    };

    for (testCases) |testCase| {
        {
            defer list.clearRetainingCapacity();

            try list.writer().print("{s}", .{testCase.date});
            try testing.expectEqualStrings(testCase.expectedS, list.items);
        }
        {
            defer list.clearRetainingCapacity();

            try list.writer().print("{any}", .{testCase.date});
            try testing.expectEqualStrings(testCase.expectedAny, list.items);
        }
    }
}

test "gregorian leap year" {
    try testing.expect((GregorianDate{ .year = @as(AstronomicalYear, @enumFromInt(0)) }).isLeapYear());
    try testing.expect((GregorianDate{ .year = annoDominiToAstronomical(@as(AnnoDominiYear, @enumFromInt(-1))) }).isLeapYear());
    try testing.expect((GregorianDate{ .year = @enumFromInt(4) }).isLeapYear());
    try testing.expect((GregorianDate{ .year = @enumFromInt(8) }).isLeapYear());
    try testing.expect((GregorianDate{ .year = @enumFromInt(2000) }).isLeapYear());
    try testing.expect(!(GregorianDate{ .year = @enumFromInt(1900) }).isLeapYear());
    try testing.expect(!(GregorianDate{ .year = @enumFromInt(1800) }).isLeapYear());
    try testing.expect(!(GregorianDate{ .year = @enumFromInt(1700) }).isLeapYear());
    try testing.expect(!(GregorianDate{ .year = @enumFromInt(2023) }).isLeapYear());
    try testing.expect((GregorianDate{ .year = @enumFromInt(2024) }).isLeapYear());
    try testing.expect((GregorianDate{ .year = @enumFromInt(2020) }).isLeapYear());
    try testing.expect((GregorianDate{ .year = @enumFromInt(1600) }).isLeapYear());
}

/// Represents a gregorian date and time combination
pub const GregorianDateTime = struct {
    date: GregorianDate,
    time: time.Segments,
};
