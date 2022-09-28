usingnamespace @import("clbridge.zig");
usingnamespace @import("volumecaster.zig");
usingnamespace @import("sumpool.zig");
usingnamespace @import("square-array.zig"); // has no tests ? 

const std = @import("std");
test "ref all" {
  std.testing.refAllDecls(@This());
}
