const std = @import("std");
const SegmentType = @import("spec.zig").SegmentType;

/// Token segment
pub const Segment = struct {
    type: SegmentType,
    str: []const u8,
    pub fn format(
        self: @This(),
        comptime f: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = f;
        _ = options;
        try writer.writeAll("Segment{.type=");
        try writer.writeAll(std.enums.tagName(SegmentType, self.type).?);
        try writer.writeAll(", .str=\"");
        try writer.writeAll(self.str);
        try writer.writeAll("\"}");
    }
};

/// Parse error
pub const ParseFormatError = error{
    TooManySegments,
    UnexpectedEndOfFile,
    LoopTooLong,
};

/// Parsed date format
pub const Format = struct {
    _segs_len: usize = 0,
    _segs: [128]Segment = undefined,

    /// Creates a format from segments
    pub fn from(segs: []const Segment) @This() {
        var res = @This(){};
        std.debug.assert(segs.len <= res._segs.len);

        std.mem.copyForwards(Segment, &res._segs, segs);
        res._segs_len = segs.len;
        return res;
    }

    /// Pushes a segment onto a format (errors if at max limit)
    pub fn push(self: *@This(), s: Segment) ParseFormatError!void {
        if (self._segs_len < self._segs.len) {
            self._segs[self._segs_len] = s;
            self._segs_len += 1;
        } else {
            return ParseFormatError.TooManySegments;
        }
    }
};
