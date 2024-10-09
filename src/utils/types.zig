const assert = @import("std").debug.assert;
const testing = @import("std").testing;

// Just a lot of type-related helper functions
// I have to deal with numbers across so many different types and then do
// math across type boundaries. Something is needed for my sanity.
//
// Just FYI, for my own sanity I restricted this to deal with ints of multiples
// of 8 up to 64 bits. I also only support 32-bit and 64-bit floats. Any other
// int or float size is an error because I don't want to try to figure out how
// to support u37 or f9. Plus, those weird sizes probably have some sort of
// packing/unpacking penalty since they don't fit into x86_64 registers well.
// As for not supporting 128-bit, well I can only support 11 million years
// so I'm never gonna get that high.

/// Checks that the provided type is a valid "math" runtime type
/// "math" runtime types includes ints and floats
/// comptime_int and comptime_float will fail the assertion
/// This is used for checking assertions like "Can I cast y to OutType?"
/// For now, math types only include traditional bit sizes
pub fn assertValidMathRuntimeType(comptime Out: type) void {
    // Only these types are accepted as valid output types in this module
    comptime assert(switch (Out) {
        i8,
        i16,
        i32,
        i64,
        u8,
        u16,
        u32,
        u64,
        f32,
        f64,
        => true,
        else => false,
    });
}

/// Checks that the provided type is a valid "math" type
/// Counts comptime, untyped literals as valid (comptime_int, comptime_float)
/// This is used for checking assertions like "Are these types addable?"
/// For now, math types only include traditional bit sizes
pub fn assertValidMathType(comptime Out: type) void {
    // Only these types are accepted as valid output types in this module
    switch (Out) {
        comptime_float, comptime_int => return,
        else => assertValidMathRuntimeType(Out),
    }
}

/// Checks that the provided value has a valid "math" runtime type
/// "math" runtime types includes ints and floats
/// Untyped literals will pass the assertion
/// This is used for cehcks like "Can I add x and y?"
/// For now, math types only include traditional bit sizes
pub fn assertHasValidMathType(x: anytype) void {
    assertValidMathType(@TypeOf(x));
}

/// Checks that the provided value has a valid "math" type
/// Counts comptime, untyped literals as valid
/// This is used for checks like "Can I cast y to @TypeOf(x)?"
/// For now, math types only include traditional bit sizes
pub fn assertHasValidMathRuntimeType(x: anytype) void {
    assertValidMathRuntimeType(@TypeOf(x));
}

/// Returns the runtime type that can represent x
/// For all comptime values, will return the 64-bit type
/// (I.E. comptime_int => i64, comptime_flaot => f64)
/// For now, math types only include traditional bit sizes
pub fn mathRuntimeTypeOf(x: anytype) type {
    assertHasValidMathType(x);
    const t: type = comptime @TypeOf(x);
    return switch (t) {
        comptime_int => i64,
        comptime_float => f64,
        else => t,
    };
}

test "mathRuntimeTypeOf" {
    try testing.expect(i64 == mathRuntimeTypeOf(4));
    try testing.expect(f64 == mathRuntimeTypeOf(4.0));
    try testing.expect(i8 == mathRuntimeTypeOf(@as(i8, 3)));
    try testing.expect(i16 == mathRuntimeTypeOf(@as(i16, 3)));
    try testing.expect(i32 == mathRuntimeTypeOf(@as(i32, 3)));
    try testing.expect(i64 == mathRuntimeTypeOf(@as(i64, 3)));
    try testing.expect(u8 == mathRuntimeTypeOf(@as(u8, 3)));
    try testing.expect(u16 == mathRuntimeTypeOf(@as(u16, 3)));
    try testing.expect(u32 == mathRuntimeTypeOf(@as(u32, 3)));
    try testing.expect(u64 == mathRuntimeTypeOf(@as(u64, 3)));
    try testing.expect(f64 == mathRuntimeTypeOf(@as(f64, 3)));
    try testing.expect(f32 == mathRuntimeTypeOf(@as(f32, 3)));
}

/// Converts one "math" value to a specific "math" type
/// Math types and values are integers and floats
/// The target output type must be a runtime type (not comptime-only)
/// For now, math types only include traditional bit sizes
pub fn toTypeMath(comptime Out: type, x: anytype) Out {
    assertHasValidMathType(x);
    assertValidMathRuntimeType(Out);

    if (Out == @TypeOf(x)) {
        return @as(Out, x);
    }

    // not using @truncate to get additional asserts about overflows
    return switch (@TypeOf(x)) {
        comptime_int,
        i8,
        i16,
        i32,
        i64,
        u8,
        u16,
        u32,
        u64,
        => switch (Out) {
            i8,
            i16,
            i32,
            i64,
            u8,
            u16,
            u32,
            u64,
            => @intCast(x),
            f32, f64 => @floatFromInt(x),
            else => unreachable,
        },
        comptime_float, f32, f64 => switch (Out) {
            i8,
            i16,
            i32,
            i64,
            u8,
            u16,
            u32,
            u64,
            => @intFromFloat(x),
            f32, f64 => @floatCast(x),
            else => unreachable,
        },
        else => unreachable,
    };
}

test "toTypeMath" {
    try testing.expectEqual(@as(i64, 4), toTypeMath(i64, 4));
    try testing.expectEqual(@as(f64, 4), toTypeMath(f64, 4));
    try testing.expectEqual(@as(i64, 4), toTypeMath(i64, 4.0));
    try testing.expectEqual(@as(f64, 4), toTypeMath(f64, 4.0));
    try testing.expectEqual(@as(i8, 3), toTypeMath(i8, @as(i16, 3)));
    try testing.expectEqual(@as(i16, 3), toTypeMath(i16, @as(i32, 3)));
    try testing.expectEqual(@as(i32, 3), toTypeMath(i32, @as(i64, 3)));
    try testing.expectEqual(@as(i64, 3), toTypeMath(i64, @as(i64, 3)));
    try testing.expectEqual(@as(i64, 3), toTypeMath(i64, @as(u64, 3)));
    try testing.expectEqual(@as(i64, 3), toTypeMath(i64, @as(i8, 3)));
    try testing.expectEqual(@as(u8, 3), toTypeMath(u8, @as(i8, 3)));
    try testing.expectEqual(@as(u16, 3), toTypeMath(u16, @as(i16, 3)));
    try testing.expectEqual(@as(u32, 3), toTypeMath(u32, @as(i32, 3)));
    try testing.expectEqual(@as(u64, 3), toTypeMath(u64, @as(i64, 3)));
}
