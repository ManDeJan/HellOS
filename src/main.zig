const builtin = @import("builtin");

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
    terminal.write("Hello, kernel World!");

    var fg: u4 = 0;
    var bg: u4 = 8;
    var i: usize = 0;
    while (i < 25*80) : ({i+=1; fg +%= 1; bg +%= 1;}) {
        const nc = vga_entry_color(@intToEnum(VgaColor, fg), @intToEnum(VgaColor, bg));
        terminal.setColor(nc);
        terminal.write("\xDC");
    }
}


const VgaColor = packed enum(u4).{
    black        ,
    blue         ,
    green        ,
    cyan         ,
    red          ,
    magenta      ,
    brown        ,
    light_grey   ,
    dark_grey    ,
    light_blue   ,
    light_green  ,
    light_cyan   ,
    light_red    ,
    light_magenta,
    light_brown  ,
    white        ,
};


const VgaColorPair = packed struct.{
    fg: VgaColor,
    bg: VgaColor,
};

fn vga_entry_color(fg: VgaColor, bg: VgaColor) VgaColorPair {
    return VgaColorPair.{.bg=bg, .fg=fg};
}

const VgaEntry = packed struct.{
    char:   u8,
    color:  VgaColorPair,
};

fn vga_entry(char: u8, color: VgaColorPair) VgaEntry {
    return VgaEntry.{.color=color, .char=char};
}

const VGA_WIDTH  = 80;
const VGA_HEIGHT = 25;

const terminal = struct.{
    var row    = usize(0);
    var column = usize(0);
    var color  = vga_entry_color(VgaColor.light_grey, VgaColor.black);

    const buffer = @intToPtr([*]volatile u16, 0xB8000);

    fn initialize() void {
        var y = usize(0);
        while (y < VGA_HEIGHT) : (y += 1) {
            var x = usize(0);
            while (x < VGA_WIDTH) : (x += 1) {
                putCharAt(' ', color, x, y);
            }
        }
    }

    fn setColor(new_color: VgaColorPair) void {
        color = new_color;
    }

    fn putCharAt(c: u8, new_color: VgaColorPair, x: usize, y: usize) void {
        const index = y * VGA_WIDTH + x;
        const entry align(2) = vga_entry(c, new_color);
        buffer[index] = @ptrCast(*const u16, &entry).*;
    }

    fn putChar(c: u8) void {
        putCharAt(c, color, column, row);
        column += 1;
        if (column == VGA_WIDTH) {
            column = 0;
            row += 1;
            if (row == VGA_HEIGHT)
                row = 0;
        }
    }

    fn write(data: []const u8) void {
        for (data) |c| putChar(c);
    }
};
