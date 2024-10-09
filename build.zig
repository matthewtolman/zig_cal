const std = @import("std");

pub fn build(b: *std.Build) void {
    const lib_name = "zig_cal";

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const utils_lib = b.addStaticLibrary(.{
        .name = "zig_cal_utils",
        .root_source_file = b.path("src/utils.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(utils_lib);

    const static_lib = b.addStaticLibrary(.{
        .name = lib_name,
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    static_lib.linkLibrary(utils_lib);

    b.installArtifact(static_lib);

    const dynamic_lib = b.addSharedLibrary(.{
        .name = lib_name,
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(dynamic_lib);

    const tests = [_]*std.Build.Step.Run{
        b.addRunArtifact(b.addTest(.{
            .name = "tests_" ++ lib_name,
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
        })),
    };

    const test_step = b.step("test", "Test the application");

    for (tests) |t| {
        test_step.dependOn(&t.step);
    }
}
