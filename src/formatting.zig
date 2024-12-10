const std = @import("std");
const Format = @import("formatting/core.zig").Format;
const ParseFormatError = @import("formatting/core.zig").ParseFormatError;
const Segment = @import("formatting/core.zig").Segment;

/// Character iterator
const CharIter = struct {
    _input: []const u8,
    _cur: ?u8 = null,
    _next: ?u8 = null,
    _head: usize = 0,

    /// Current character
    pub fn cur(self: *const @This()) ?u8 {
        return self._cur;
    }

    /// Peek at next character
    pub fn peek(self: *const @This()) ?u8 {
        return self._next;
    }

    /// Checks if has n repeating characters at current position
    /// Does so without consuming those characters
    pub fn hasRepeat(self: *const @This(), count: usize) bool {
        const c = self.cur();
        if (c) |look| {
            const p = self.pos();
            var i: usize = 0;
            while (i + p < self._input.len and i < count) : (i += 1) {
                if (self._input[i + p] != look) return false;
            }

            if (i != count) return false;

            return true;
        } else {
            return false;
        }
    }

    /// Consume to the next character
    pub fn next(self: *@This()) ?u8 {
        std.debug.assert(!self.atEnd());
        self._cur = self._next;
        self._next = if (self._head < self._input.len) self._input[self._head] else null;
        self._head += 1;
        return self.cur();
    }

    /// Returns if at end
    pub fn atEnd(self: *const @This()) bool {
        return self._head > 0 and self._cur == null and self._next == null;
    }

    /// Gets position in input
    pub fn pos(self: *const @This()) usize {
        if (self._head <= 1) {
            return 0;
        }
        return self._head - 2;
    }

    /// Initializes character iterator from input
    pub fn init(input: []const u8) @This() {
        var res: @This() = .{
            ._input = input,
        };
        _ = res.next();
        _ = res.next();
        std.debug.assert(res.pos() == 0);
        std.debug.assert(res._head == 2);
        return res;
    }

    /// Consumes n characters
    pub fn consumeN(self: *@This(), n: usize) ![]const u8 {
        std.debug.assert(n > 0);
        if (self.atEnd()) {
            unreachable;
        }

        const start = self.pos();
        const end = start + n;
        self._head += n;
        if (self._head - 2 < self._input.len) {
            self._cur = self._input[self._head - 2];
        } else {
            self._cur = null;
        }

        if (self._head - 1 < self._input.len) {
            self._next = self._input[self._head - 1];
        } else {
            self._next = null;
        }
        const res = self._input[start..end];
        if (res.len < n) {
            return ParseFormatError.UnexpectedEndOfFile;
        }
        return res;
    }

    /// Consumes a repeated character
    pub fn consumeRepeat(self: *@This(), max: usize) ![]const u8 {
        if (self.atEnd()) {
            unreachable;
        }

        const s_pos = self.pos();
        const s_ch = self._input[s_pos];
        while (self.next()) |c| {
            const section = self._input[s_pos..self.pos()];
            if (section.len >= max or c != s_ch) {
                return self._input[s_pos..self.pos()];
            }
        }
        return self._input[s_pos..];
    }

    //// Consumes until reaches one of a character
    /// Will ignore escaped characters as terminator
    pub fn consumUntilOneOf(
        self: *@This(),
        escape: u8,
        one_of: []const u8,
    ) ![]const u8 {
        if (self.atEnd()) {
            unreachable;
        }

        const start = self.pos();
        var escaped = false;
        var counter: usize = 0;
        while (self.next()) |c| {
            defer counter += 1;
            if (counter > 5000) {
                return ParseFormatError.LoopTooLong;
            }
            if (escaped) {
                escaped = false;
                continue;
            }
            if (c == escape) {
                escaped = true;
                continue;
            }
            const s = [_]u8{c};
            if (std.mem.indexOf(u8, one_of, &s)) |_| {
                return self._input[start..self.pos()];
            }
        }
        if (escaped) {
            return ParseFormatError.UnexpectedEndOfFile;
        }
        return self._input[start..];
    }
};

/// Tokenizes a stream from a character iterator
const Tokenizer = struct {
    _iter: CharIter,

    /// Gets the next segment token
    pub fn next(self: *@This()) !?Segment {
        if (self._iter.atEnd()) {
            return null;
        }

        const seg_start = self._iter.cur();
        if (seg_start) |start| {
            const escape: u8 = '\\';
            const non_text = "yYDduRMQeEaAhHmsSGXxOPpC";
            switch (start) {
                'Y' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .YearOrdinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }

                    return .{
                        .type = .Year,
                        .str = try self._iter.consumeRepeat(500),
                    };
                },
                'y' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .YearOrdinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }

                    return .{
                        .type = .Year,
                        .str = try self._iter.consumeRepeat(500),
                    };
                },
                'D' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .DayOfYearOrdinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }

                    return .{
                        .type = .DayofYearNum,
                        .str = try self._iter.consumeRepeat(500),
                    };
                },
                'd' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .DayOfMonthOrdinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }

                    return .{
                        .type = .DayOfMonthNum,
                        .str = try self._iter.consumeRepeat(2),
                    };
                },
                'u' => {
                    return .{
                        .type = .SignedYear,
                        .str = try self._iter.consumeRepeat(500),
                    };
                },
                'R' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .WeekInYearOrdinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }
                    return .{
                        .type = .WeekInYear,
                        .str = try self._iter.consumeRepeat(500),
                    };
                },
                'M' => {
                    const res = try self._iter.consumeRepeat(5);
                    if (res.len <= 2) {
                        return .{
                            .type = .MonthNum,
                            .str = res,
                        };
                    } else if (res.len == 3) {
                        return .{
                            .type = .MonthNameShort,
                            .str = res,
                        };
                    } else if (res.len == 4) {
                        return .{
                            .type = .MonthNameLong,
                            .str = res,
                        };
                    } else {
                        return .{
                            .type = .MonthNameFirstLetter,
                            .str = res,
                        };
                    }
                },
                'G' => {
                    const res = try self._iter.consumeRepeat(4);
                    if (res.len <= 3) {
                        return .{
                            .type = .EraDesignatorShort,
                            .str = res,
                        };
                    } else {
                        return .{
                            .type = .EraDesignatorLong,
                            .str = res,
                        };
                    }
                },
                'Q' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .QuarterOrdinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }
                    const res = try self._iter.consumeRepeat(4);
                    if (res.len <= 2) {
                        return .{
                            .type = .QuarterNum,
                            .str = res,
                        };
                    } else if (res.len == 3) {
                        return .{
                            .type = .QuarterPrefixed,
                            .str = res,
                        };
                    } else {
                        return .{
                            .type = .QuarterLong,
                            .str = res,
                        };
                    }
                },
                'E' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .DayOfWeekOrdinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }
                    const res = try self._iter.consumeRepeat(6);
                    if (res.len <= 2) {
                        return .{
                            .type = .DayOfWeekNum,
                            .str = res,
                        };
                    } else if (res.len == 3) {
                        return .{
                            .type = .DayOfWeekNameShort,
                            .str = res,
                        };
                    } else if (res.len == 4) {
                        return .{
                            .type = .DayOfWeekNameFull,
                            .str = res,
                        };
                    } else if (res.len == 5) {
                        return .{
                            .type = .DayOfWeekNameFirstLetter,
                            .str = res,
                        };
                    } else {
                        return .{
                            .type = .DayOfWeekNameFirst2Letters,
                            .str = res,
                        };
                    }
                },
                'e' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .DayOfWeekOrdinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }
                    const res = try self._iter.consumeRepeat(6);
                    if (res.len <= 2) {
                        return .{
                            .type = .DayOfWeekNum,
                            .str = res,
                        };
                    } else if (res.len == 3) {
                        return .{
                            .type = .DayOfWeekNameShort,
                            .str = res,
                        };
                    } else if (res.len == 4) {
                        return .{
                            .type = .DayOfWeekNameFull,
                            .str = res,
                        };
                    } else if (res.len == 5) {
                        return .{
                            .type = .DayOfWeekNameFirstLetter,
                            .str = res,
                        };
                    } else {
                        return .{
                            .type = .DayOfWeekNameFirst2Letters,
                            .str = res,
                        };
                    }
                },
                'a' => {
                    return .{
                        .type = .TimeOfDayLocale,
                        .str = try self._iter.consumeRepeat(2),
                    };
                },
                'A' => {
                    const res = try self._iter.consumeRepeat(5);
                    if (res.len <= 2) {
                        return .{
                            .type = .TimeOfDayAM,
                            .str = res,
                        };
                    } else if (res.len == 3) {
                        return .{
                            .type = .TimeOfDay_am,
                            .str = res,
                        };
                    } else if (res.len == 4) {
                        return .{
                            .type = .TimeOfDay_a_m,
                            .str = res,
                        };
                    } else if (res.len == 5) {
                        return .{
                            .type = .TimeOfDay_ap,
                            .str = res,
                        };
                    }
                },
                'h' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .Hour12Ordinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }

                    return .{
                        .type = .Hour12Num,
                        .str = try self._iter.consumeRepeat(2),
                    };
                },
                'H' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .Hour24Ordinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }

                    return .{
                        .type = .Hour24Num,
                        .str = try self._iter.consumeRepeat(2),
                    };
                },
                'm' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .MinuteOrdinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }

                    return .{
                        .type = .MinuteNum,
                        .str = try self._iter.consumeRepeat(2),
                    };
                },
                's' => {
                    if (self._iter.peek() == 'o') {
                        return .{
                            .type = .SecondOrdinal,
                            .str = try self._iter.consumeN(2),
                        };
                    }

                    return .{
                        .type = .SecondNum,
                        .str = try self._iter.consumeRepeat(2),
                    };
                },
                'S' => {
                    return .{
                        .type = .FractionOfASecond,
                        .str = try self._iter.consumeRepeat(512),
                    };
                },
                'X' => {
                    return .{
                        .type = .TimezoneOffsetZ,
                        .str = try self._iter.consumeRepeat(5),
                    };
                },
                'x' => {
                    return .{
                        .type = .TimezoneOffset,
                        .str = try self._iter.consumeRepeat(5),
                    };
                },
                'O' => {
                    var res: Segment = .{
                        .type = .GmtOffset,
                        .str = try self._iter.consumeRepeat(4),
                    };
                    if (res.str.len == 4) {
                        res.type = .GmtOffsetFull;
                    }
                    return res;
                },
                'P' => {
                    const spos = self._iter.pos();
                    var res: Segment = .{
                        .type = .LocalizedLongDate,
                        .str = try self._iter.consumeRepeat(4),
                    };
                    if (self._iter.cur() == 'p') {
                        if (self._iter.hasRepeat(res.str.len)) {
                            _ = try self._iter.consumeRepeat(res.str.len);
                            res.str = self._iter._input[spos..self._iter.pos()];
                            res.type = .LocalizedLongDateTime;
                        }
                    }
                    return res;
                },
                'p' => {
                    return .{
                        .type = .LocalizedLongTime,
                        .str = try self._iter.consumeRepeat(4),
                    };
                },
                'C' => {
                    return .{
                        .type = .CalendarSystem,
                        .str = try self._iter.consumeN(1),
                    };
                },
                else => {
                    return .{
                        .type = .Text,
                        .str = try self._iter.consumUntilOneOf(escape, non_text),
                    };
                },
            }
        }
        return null;
    }
};

/// Parses a format string
pub fn parseFormatStr(format: []const u8) !Format {
    var res = Format{};
    var tokenizer = Tokenizer{
        ._iter = CharIter.init(format),
    };

    var counter: usize = 0;
    while (try tokenizer.next()) |s| {
        defer counter += 1;
        if (counter >= 128) {
            return ParseFormatError.TooManySegments;
        }
        try res.push(s);
    }

    return res;
}

// /// Format
// pub fn format(out_writer: anytype, date: anytype, format: []const u8) !void {
//     const fmt = try parseFormatStr(format);
// }

test {
    _ = @import("formatting/parse_tests.zig");
    _ = @import("formatting/format.zig");
}
