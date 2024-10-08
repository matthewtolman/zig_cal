/// Represents time in Hour, Minut, Second, and Nanosecond fragments
/// Using u32 for nano since I only need to represent 1 billion nanoseconds,
/// and u32 can represent 4 billion nanoseconds
/// Also, at some point I just lose so much precision since we'll be converting
/// to and from DayFraction for a lot of conversions, so it's really just a silly system
/// But, most time and clock APIs expose nanoseconds (even though most clocks still don't
/// have nanosecond precision), so I guess I'll include it
pub const Segments = struct { hour: u8, minute: u8, second: u8, nano: u32 };

/// Fraction of a day as a float. Makes math easier, makes precision worse.
/// If you need to preserve all nanoseconds while doing a date conversion then feel free
/// to write something better.
pub const DayFraction = struct { frac: f64 };

/// Time of day in nanoseconds. This struct goes brrrrrr.
pub const NanoSeconds = struct { nano: u64 };
