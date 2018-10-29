const builtin = @import("builtin");
const vga = @import("vga.zig");
const terminal = vga.terminal;

const MultiBoot = packed struct.{
    magic:    i32,
    flags:    i32,
    checksum: i32,
};

const ALIGN   = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC   = 0x1BADB002;
const FLAGS   = ALIGN | MEMINFO;

export var multiboot align(4) section(".multiboot") = MultiBoot.{
    .magic = MAGIC,
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

export var stack_bytes: [16 * 1024]u8 align(16) section(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];

export nakedcc fn _start() noreturn {
    @newStackCall(stack_bytes_slice, kmain);
    while (true) {}
}

pub fn panic(msg: []const u8, error_return_trace: ?*builtin.StackTrace) noreturn {
    @setCold(true);
    terminal.write("KERNEL PANIC: ");
    terminal.write(msg);
    while (true) {}
}

fn kmain() void {
    terminal.initialize();
    terminal.write("Hello, kernel World!"); // HI!

    var fg: u4 = 0;
    var bg: u4 = 8;

    // Seizure inducing graphics
    while (true) : ({fg +%= 1; bg +%= 1;}) {
        const nc = vga.entry_color(@intToEnum(vga.Color, fg), @intToEnum(vga.Color, bg));
        terminal.setColor(nc);
        // https://en.wikipedia.org/wiki/Code_page_437
        terminal.write("\xDD\xDE");
    }
}
