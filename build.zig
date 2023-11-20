const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const wepoll_dep = b.dependency("wepoll", .{
        .target = target,
        .optimize = optimize,
    });
    const lib = b.addStaticLibrary(.{
        .name = "picoev",
        .target = target,
        .optimize = optimize,
    });
    const t = lib.target_info.target;
    switch (t.os.tag) {
        .linux => {
            lib.addCSourceFile(.{
                .file = .{ .path = "src/picoev_epoll.c" },
                .flags = &.{},
            });
        },
        .macos => {
            lib.addCSourceFile(.{
                .file = .{ .path = "src/picoev_kqueue.c" },
                .flags = &.{},
            });
        },
        .windows => {
            lib.addCSourceFile(.{
                .file = .{ .path = "src/picoev_epoll.c" },
                .flags = &.{"-Wno-int-conversion"},
            });
            lib.linkLibrary(wepoll_dep.artifact("wepoll"));
        },
        else => {},
    }
    lib.addIncludePath(.{ .path = "include" });
    lib.installHeadersDirectory("include", "");
    lib.linkLibC();
    b.installArtifact(lib);

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_main_tests = b.addRunArtifact(main_tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
