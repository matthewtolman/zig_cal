const time = @import("./time.zig");
const m = @import("std").math;
const assert = @import("std").debug.assert;
const types = @import("../utils.zig").types;

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
//      C and C++ APIs: https://gitlab.com/mtolman/calendars
//      C++ constexpr: https://gitlab.com/mtolman/calendar-constexpr
pub const Date = struct {
    day: i32,
};

/// Represents a fixed date plus time
/// Prefer this over Moment whenever possible
pub const DateTime = struct {
    date: Date,
    time: time.Segments,

    /// Checks if we're valid
    pub fn validate(self: DateTime) !void {
        try self.time.validate();
    }

    /// Converts to a moment - avoid if possible
    pub fn toMoment(self: DateTime) Moment {
        assert(self.valid());
        const days = types.toTypeMath(f64, self.date.day);
        const t = self.time.toDayFraction();
        const res = Moment{ .dayAndTime = days + t.frac };
        assert(res.valid());
        return res;
    }
};

/// An extremely inprecise way of representing date and time
/// For 90% of use cases it works just fine because anything smaller than
/// seconds is generally not needed
/// But as time progresses, this just gets worse and worse.
/// That said, it does get worse slowly enough for us to build another Y2K.
/// And probably let a few generations retire before the Y2K happens.
///
/// I still don't like it. Used fixed.DateTime whenever possible instead.
pub const Moment = struct {
    dayAndTime: f64,

    /// Checks if we're valid
    pub fn valid(self: Moment) bool {
        return m.isFinite(self);
    }

    /// Converts to a fixed DateTime
    pub fn toFixed(self: Moment) DateTime {
        assert(self.valid());

        const days = m.floor(self.dayAndTime);
        const t = self.dayAndTime - days;

        const daysInt = types.toTypeMath(i32, days);

        return DateTime{
            .date = Date{ .days = daysInt },
            .time = (time.DayFraction{ .frac = t }).toSegments(),
        };
    }
};
