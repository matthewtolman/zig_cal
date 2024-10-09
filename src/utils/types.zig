const assert = @import("std").debug.assert;

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
    const t: type = comptime @TypeOf(x);
    return switch (t) {
        comptime_int => i64,
        comptime_float => f64,
        else => t,
    };
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
