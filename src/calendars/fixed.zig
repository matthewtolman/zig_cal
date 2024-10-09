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
pub const Date = struct { dayCount: i32 };
