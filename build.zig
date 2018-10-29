const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("JanOS", "src/main.zig");
    exe.setBuildMode(mode);
    exe.setOutputPath("janos");
    exe.setTarget(builtin.Arch.i386, builtin.Os.freestanding, builtin.Environ.gnu);
    exe.setLinkerScriptPath("src/linker.ld");

    b.default_step.dependOn(&exe.step);

    const qemu = b.step("qemu", "Run the OS in qemu");
    const run_qemu = b.addCommand(".", b.env_map, [][]const u8.{
        "qemu-system-i386",
        "-kernel",
        "janos",
    });
    qemu.dependOn(&run_qemu.step);
    run_qemu.step.dependOn(&exe.step);
}
