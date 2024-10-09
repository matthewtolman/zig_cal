/// Represents time in Hour, Minut, Second, and Nanosecond fragments
/// Using u32 for nano since I only need to represent 1 billion nanoseconds,
/// and u32 can represent 4 billion nanoseconds
/// Also, at some point I just lose so much precision since we'll be converting
/// to and from Moment for some math, so it's really just a silly system.
/// But, it's also a system most devs are familiar with, and so long as they
/// don't hit one of the (*fun*) conversions that require Moment we'll be
/// good.
/// I'm going to try to replace and avoid Moment conversions wherever possible,
/// unlike in my C++ code where I just YOLO'd it and went with the book.
/// Ideally, nano is just fine.
///
/// And no, I'm not ever going below nano. Go too small and things get weird,
/// both at the hardware precision level and at the whole relativity/quantum
/// level.
pub const Segments = struct {
    hour: u8,
    minute: u8,
    second: u8,
    nano: u32,
};

/// Fraction of a day as a float. Makes math easier, makes precision worse.
/// If you need to preserve all nanoseconds while doing a date conversion then feel free
/// to write something better.
pub const DayFraction = struct { frac: f64 };

/// Time of day in nanoseconds. This struct goes brrrrrr.
pub const NanoSeconds = struct { nano: u64 };
