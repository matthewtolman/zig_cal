// Epochs define a calendar's "start date" in reference to the intermediate
// FixedDate calendar. The "FixedDate" (or "Rata Die" or RD Date) is a system
// that counts the number of days which have passed from a fixed day. It is a
// signed date (to allow before times) where
//               R.D. 1 (FixedDate 1) == Gregorian Jan 1, 1

pub const fixed = 0;
pub const gregorian = 1;
pub const unix = 719163;
