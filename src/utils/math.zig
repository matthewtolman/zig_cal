const m = @import("std").math;
const assert = @import("std").debug.assert;
const testing = @import("std").testing;
const types = @import("./types.zig");

/// Floor based mod for x and y
/// Can handle multiple input types, and will cast to desired output types
/// So much calendar math is sensitive to the type of flooring used that it's
/// just way easier for me to write it and maintain it rather than do a bunch
/// of research and testing on what a standard library/language uses, build
/// code around it, and then hope that nobody ever realizes they had a bug
/// and "fix" their code.
pub fn mod(comptime Out: type, x: anytype, y: anytype) Out {
    types.assertValidMathRuntimeType(Out);
    types.assertHasValidMathType(x);
    types.assertHasValidMathType(y);

    // Make sure we don't divide by zero
    assert(y != 0);

    // For this mod to work, we need decimal places
    // To do that, get x and y both as floats

    const xf = types.toTypeMath(f64, x);
    const yf = types.toTypeMath(f64, y);

    // Here's the actual math (Part1)
    const modifier = xf / yf;

    // We shouldn't be getting weird numbers that give us a NaN or +/- Infinity
    assert(m.isFinite(modifier));

    // Here's the actual math (Part2)
    const res = xf - yf * m.floor(modifier);

    // We should have our result between y and 0
    if (y < 0) {
        assert(res <= 0);
        assert(res > yf);
    } else {
        assert(res < yf);
        assert(res >= 0);
    }

    return types.toTypeMath(Out, res);
}

test "mod" {
    try testing.expectEqual(2, mod(i64, 2, 5));
    try testing.expectEqual(2, mod(f32, 12, 5));
    try testing.expectEqual(3, mod(u8, -12, 5));
    try testing.expectEqual(-3, mod(i8, 12, -5));

    // test conversions
    try testing.expectEqual(-3, mod(i16, @as(i64, 12), @as(i32, -5)));
    try testing.expectEqual(-3, mod(i32, @as(u64, 12), @as(f32, -5)));
}

/// Floor based adjusted mod for x and y
/// Equivalent to x mod [1..y]
/// Can handle multiple input types, and will cast to desired output types
/// This is used a lot in so many different calendars.
pub fn amod(comptime Out: type, x: anytype, y: anytype) Out {
    types.assertValidMathRuntimeType(Out);
    types.assertHasValidMathType(x);
    types.assertHasValidMathType(y);

    // mod uses f64 internally before casting to final type
    // We also use f64 internally before casting to final type
    const yf = types.toTypeMath(f64, y);
    return types.toTypeMath(Out, yf + mod(f64, x, -yf));
}

test "amod" {
    try testing.expectEqual(3, amod(i64, 3, 7));
    try testing.expectEqual(7, amod(i64, 7, 7));
    try testing.expectEqual(7, amod(i64, 0, 7));
    try testing.expectEqual(1, amod(i64, 7, 3));
    try testing.expectEqual(5, amod(i64, 12, 7));
    try testing.expectEqual(4, amod(i64, -3, 7));
    try testing.expectEqual(-4, amod(i64, 3, -7));
    try testing.expectEqual(-3, amod(i64, -3, -7));
}

/// Floor based range mod for x and y.
/// Equivalent to x mod [a..b)
/// Can handle multiple input types, and will cast to desired output types
/// Not used as much as amod, but still pretty well used
pub fn modRange(comptime Out: type, x: anytype, a: i64, b: i64) Out {
    types.assertHasValidMathType(x);
    types.assertValidMathRuntimeType(Out);

    if (a == b) {
        return types.toTypeMath(Out, x);
    }

    const aPrime = types.toTypeMath(types.mathRuntimeTypeOf(x), a);
    const res = aPrime + mod(types.mathRuntimeTypeOf(x), x - a, b - a);
    return types.toTypeMath(Out, res);
}

test "mod_range" {
    try testing.expectEqual(6, modRange(i32, 2, 3, 7));
    try testing.expectEqual(12, modRange(i8, 12, 2, 2));
    try testing.expectEqual(5, modRange(u16, 5, 3, 7));
    try testing.expectEqual(4, modRange(i64, 12, 3, 7));
    try testing.expectEqual(4000, modRange(i16, 12000, 3000, 7000));
}
