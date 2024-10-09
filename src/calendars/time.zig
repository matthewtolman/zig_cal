const toTypeMath = @import("../utils.zig").types.toTypeMath;
const m = @import("std").math;
const math = @import("../utils.zig").math;
const assert = @import("std").debug.assert;

//                 ns/s s/m   m/h  h/d
const nanoPerDay = 1e9 * 60 * 60 * 24;

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
    /// 0-23
    hour: u8,
    /// 0-59
    minute: u8,
    /// 0-59 - we don't do leap seconds
    second: u8,
    /// 0-99,999,999
    nano: u32,

    /// Checks whether the current segment is valid
    /// Cannot run other methods if this is valid
    pub fn valid(self: Segments) bool {
        if (self.hour >= 24) {
            return false;
        }

        if (self.minute >= 60) {
            return false;
        }

        if (self.second >= 60) {
            return false;
        }

        if (self.nano >= 1e9) {
            return false;
        }

        return true;
    }

    /// Converts time segments to nanoseconds
    pub fn toNanoSeconds(self: Segments) NanoSeconds {
        assert(self.valid());
        const hours = toTypeMath(u64, self.hour);
        const minutes = hours * 60 + toTypeMath(u64, self.minute);
        const seconds = minutes * 60 + toTypeMath(u64, self.second);
        const nano = seconds * 1e9 + toTypeMath(u64, self.nano);
        const res = NanoSeconds{ .nano = nano };
        assert(res.valid());
        return res;
    }

    /// Converts time segments to day fraction
    pub fn toDayFraction(self: Segments) DayFraction {
        return self.toNanoSeconds().toDayFraction();
    }

    pub fn compare(self: Segments, other: Segments) i32 {
        assert(self.valid());
        assert(other.valid());

        var res = 0;

        if (self.hour != other.hour) {
            res = if (self.hour < other.hour) -1 else 1;
        } else if (self.minute != other.minute) {
            res = if (self.minute < other.minute) -1 else 1;
        } else if (self.second != other.second) {
            res = if (self.second < other.second) -1 else 1;
        } else if (self.nano != other.nano) {
            res = if (self.nano < other.nano) -1 else 1;
        }

        assert(res == 1 or res == -1 or res == 0);
        return res;
    }
};

/// Fraction of a day as a float. Makes math easier, makes precision worse.
/// If you need to preserve all nanoseconds while doing a date conversion then
/// feel free to write something better.
///
/// Generally, I avoid using day fraction unless the math really needs it
/// When the math does need it, I try to avoid "Moment" even more
pub const DayFraction = struct {
    /// Fraction of the day (e.g. 0.5 = mid-day or 12pm)
    /// Note: this MUST be a finite number in the range [0..1)
    /// An invalid fraction is "undefined behavior" (i.e. crash in safe mode)
    frac: f64,

    /// Checks if instance is valid
    /// Cannot run other methods if not valid
    pub fn valid(self: DayFraction) bool {
        if (!m.isFinite(self.frac)) {
            return false;
        }
        if (self.frac < 0) {
            return false;
        }
        if (self.frac >= 1) {
            return false;
        }
        return true;
    }

    /// Converts day fraction to nano seconds
    pub fn toNanoSeconds(self: DayFraction) NanoSeconds {
        assert(self.valid());
        const nanoSeconds = toTypeMath(u64, m.floor(self.frac * nanoPerDay));
        const res = NanoSeconds{ .nano = nanoSeconds };
        assert(res.valid());
        return res;
    }

    /// Converts day fraction to segments
    pub fn toSegments(self: DayFraction) Segments {
        return self.toNanoSeconds().toSegments();
    }

    /// Compares two day fractions and returns -1, 0, or 1
    pub fn compare(self: DayFraction, other: DayFraction) i32 {
        assert(self.valid());
        assert(other.valid());

        var res = 0;
        if (self.frac != other.frac) {
            res = if (self.frac < other.frac) -1 else 1;
        }

        assert(res == 0 or res == -1 or res == 1);
        return res;
    }
};

/// Time of day in nanoseconds. This struct goes brrrrrr.
pub const NanoSeconds = struct {
    /// The number of nanoseconds
    /// Must be in the range [0..nanoPerDay)
    nano: u64,

    /// Checks if instance is valid
    /// Cannot run other methods if not valid
    pub fn valid(self: NanoSeconds) bool {
        return self.nano < nanoPerDay;
    }

    /// Converts nano seconds to day fraction
    pub fn toDayFraction(self: NanoSeconds) DayFraction {
        assert(self.valid());
        // yay precision loss!
        const nano = @as(f64, @floatFromInt(self.nano));
        const res = DayFraction{ .frac = nano / nanoPerDay };
        assert(res.valid());
        return res;
    }

    /// Converts nano seconds to segments
    pub fn toSegments(self: NanoSeconds) Segments {
        assert(self.valid());

        var val: u64 = self.nano;

        const nano = math.mod(u32, val, 1e9);
        assert(nano < 1e9);
        val = val / 1e9;

        const seconds = math.mod(u8, val, 60);
        assert(seconds < 60);
        val = val / 60;

        const minutes = math.mod(u8, val, 60);
        assert(minutes < 60);
        val = val / 60;

        assert(val < 24);
        const res = Segments{
            .hour = toTypeMath(u8, val),
            .minute = minutes,
            .second = seconds,
            .nano = nano,
        };

        assert(res.valid());
        return res;
    }

    /// Compares two day fractions and returns -1, 0, or 1
    pub fn compare(self: NanoSeconds, other: NanoSeconds) i32 {
        assert(self.valid());
        assert(other.valid());

        var res = 0;
        if (self.nano != other.nano) {
            res = if (self.nano < other.nano) -1 else 1;
        }

        assert(res == 0 or res == -1 or res == 1);
        return res;
    }
};
