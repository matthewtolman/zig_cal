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

    const mod = b.addModule("zcalendar", .{
        .root_source_file = b.path("src/lib.zig"),
    });

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

    const test_unit_step = b.step("test-unit", "Test the library (unit tests only_");
    const test_step = b.step("test", "Test the library");

    for (tests) |t| {
        test_unit_step.dependOn(&t.step);
        test_step.dependOn(&t.step);
    }

    const examples = [_]struct {
        file: []const u8,
        name: []const u8,
        libc: bool = false,
    }{
        .{ .file = "examples/01_basic.zig", .name = "example_1" },
    };
    {
        for (examples) |example| {
            const exe = b.addExecutable(.{
                .name = example.name,
                .target = target,
                .optimize = optimize,
                .root_source_file = b.path(example.file),
            });
            exe.root_module.addImport("zcalendar", mod);
            if (example.libc) {
                exe.linkLibC();
            }
            b.installArtifact(exe);

            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(b.getInstallStep());
            if (b.args) |args| {
                run_cmd.addArgs(args);
            }

            const run_step = b.step(example.name, example.file);
            run_step.dependOn(&run_cmd.step);

            test_step.dependOn(&run_cmd.step);
        }
    }
}
