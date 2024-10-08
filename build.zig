const std = @import("std");

pub fn build(b: *std.Build) void {
    const lib_name = "zig_cal";

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const static_lib = b.addStaticLibrary(.{
        .name = lib_name,
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(static_lib);

    const dynamic_lib = b.addSharedLibrary(.{
        .name = lib_name,
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(dynamic_lib);

    const tests = b.addTest(.{
        .name = "test_" ++ lib_name,
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_exe = b.addRunArtifact(tests);

    const test_step = b.step("test", "Test the application");
    test_step.dependOn(&test_exe.step);
}
