const calendars = @import("../calendars.zig");
const fixed = calendars.fixed;
const gregorian = calendars.gregorian;
const AstronomicalYear = calendars.AstronomicalYear;
const AnnoDominiYear = calendars.AnnoDominiYear;
const astroToAd = calendars.astronomicalToAnnoDomini;
const adToAstro = calendars.annoDominiToAstronomical;
const features = @import("../utils.zig").features;
const std = @import("std");
const convert = @import("../utils.zig").convert;

pub fn GregorianRange(comptime max_size: usize) type {
    return struct {
        const Error = error{InsufficientSpace};
        const Capacity = max_size;
        _elems: [Capacity]gregorian.Date = undefined,
        _len: usize = 0,

        pub fn data(self: *const @This()) []const gregorian.Date {
            return self._elems[0..self._len];
        }

        pub fn add(self: *@This(), date: gregorian.Date) Error!void {
            if (self._len >= Capacity) {
                return Error.InsufficientSpace;
            }

            self._elems[self._len] = date;
            self._len += 1;
        }

        pub fn format(
            self: *const @This(),
            comptime f: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = options;
            _ = f;

            try writer.print("Gregorian Range. Len: {d}. Elems: ", .{self._len});

            for (self.data()) |d| {
                try writer.print("\t{}", .{d});
            }
        }
    };
}

pub fn holidayInGregorianYearsSize(
    comptime Cal: type,
    comptime max_size: usize,
    year: AstronomicalYear,
    holidayFn: fn (year: features.YearType(Cal)) Cal,
) GregorianRange(max_size) {
    var range = GregorianRange(max_size){};

    const gregStart = gregorian.Date.init(year, .January, 1) catch unreachable;
    const gregEnd = gregorian.Date.init(year, .December, 31) catch unreachable;

    const rangeStart = convert(gregStart, Cal);
    const rangeEnd = convert(gregEnd, Cal);

    const yearStart = features.yearFor(rangeStart);
    const yearEnd = features.yearFor(rangeEnd);
    const Year = features.YearType(Cal);

    if (comptime Year == AstronomicalYear) {
        const ys: i32 = @intFromEnum(yearStart);
        const ye: i32 = @intFromEnum(yearEnd);
        std.debug.assert(ye < std.math.maxInt(i32));

        var y = ys;
        while (y <= ye) : (y += 1) {
            const d = convert(holidayFn(@enumFromInt(y)), gregorian.Date);
            if (d.compare(gregStart) >= 0 and d.compare(gregEnd) <= 0) {
                range.add(d) catch unreachable;
            }
        }
    } else if (comptime Year == AnnoDominiYear) {
        const astroStart: i32 = @intFromEnum(adToAstro(yearStart) catch unreachable);
        const astroEnd: i32 = @intFromEnum(adToAstro(yearEnd) catch unreachable);
        std.debug.assert(astroEnd < std.math.maxInt(i32));

        var astro = astroStart;
        while (astro <= astroEnd) : (astro += 1) {
            const h = holidayFn(astroToAd(@enumFromInt(astro)) catch unreachable);
            const d = convert(h, gregorian.Date);
            if (d.compare(gregStart) >= 0 and d.compare(gregEnd) <= 0) {
                range.add(d) catch unreachable;
            }
        }
    } else {
        const ys: i32 = @intFromEnum(yearStart);
        const ye: i32 = @intFromEnum(yearEnd);
        std.debug.assert(ye < std.math.maxInt(i32));

        var y = ys;
        while (y <= ye) : (y += 1) {
            const d = convert(
                holidayFn(y),
                gregorian.Date,
            );
            if (d.compare(gregStart) >= 0 and d.compare(gregEnd) <= 0) {
                range.add(d) catch unreachable;
            }
        }
    }

    return range;
}

pub fn holidayInGregorianYears(
    comptime Cal: type,
    year: AstronomicalYear,
    holidayFn: fn (year: features.YearType(Cal)) Cal,
) GregorianRange(3) {
    return holidayInGregorianYearsSize(Cal, 3, year, holidayFn);
}

pub fn holidaysInGregorianYearsSize(
    comptime Cal: type,
    comptime max_years: usize,
    comptime range_size: usize,
    year: AstronomicalYear,
    holidayFn: fn (year: features.YearType(Cal)) [range_size]Cal,
) GregorianRange(max_years * range_size) {
    var range = GregorianRange(max_years * range_size){};

    const gregStart = gregorian.Date.init(year, .January, 1) catch unreachable;
    const gregEnd = gregorian.Date.init(year, .December, 31) catch unreachable;

    const rangeStart = convert(gregStart, Cal);
    const rangeEnd = convert(gregEnd, Cal);

    const yearStart = features.yearFor(rangeStart);
    const yearEnd = features.yearFor(rangeEnd);
    const Year = features.YearType(Cal);

    if (comptime Year == AstronomicalYear) {
        const ys: i32 = @intFromEnum(yearStart);
        const ye: i32 = @intFromEnum(yearEnd);
        std.debug.assert(ye < std.math.maxInt(i32));

        var y = ys;
        while (y <= ye) : (y += 1) {
            const r = holidayFn(@enumFromInt(y));

            for (r) |dc| {
                const d = convert(dc, gregorian.Date);
                if (d.compare(gregStart) >= 0 and d.compare(gregEnd) <= 0) {
                    range.add(d) catch unreachable;
                }
            }
        }
    } else if (comptime Year == AnnoDominiYear) {
        const astroStart: i32 = @intFromEnum(adToAstro(yearStart) catch unreachable);
        const astroEnd: i32 = @intFromEnum(adToAstro(yearEnd) catch unreachable);
        std.debug.assert(astroEnd < std.math.maxInt(i32));

        var astro = astroStart;
        while (astro <= astroEnd) : (astro += 1) {
            const r = holidayFn(@enumFromInt(astro));

            for (r) |dc| {
                const d = convert(dc, gregorian.Date);
                if (d.compare(gregStart) >= 0 and d.compare(gregEnd) <= 0) {
                    range.add(d) catch unreachable;
                }
            }
        }
    } else {
        const ys: i32 = @intFromEnum(yearStart);
        const ye: i32 = @intFromEnum(yearEnd);
        std.debug.assert(ye < std.math.maxInt(i32));

        var y = ys;
        while (y <= ye) : (y += 1) {
            const r = holidayFn(@enumFromInt(y));

            for (r) |dc| {
                const d = convert(dc, gregorian.Date);
                if (d.compare(gregStart) >= 0 and d.compare(gregEnd) <= 0) {
                    range.add(d) catch unreachable;
                }
            }
        }
    }

    return range;
}

pub fn holidaysInGregorianYears(
    comptime Cal: type,
    comptime range_size: usize,
    year: AstronomicalYear,
    holidayFn: fn (year: features.YearType(Cal)) [range_size]Cal,
) GregorianRange(range_size * 3) {
    return holidaysInGregorianYearsSize(Cal, 3, range_size, year, holidayFn);
}
