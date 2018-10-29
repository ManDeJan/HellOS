pub const Color = packed enum(u4).{
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


const ColorPair = packed struct.{
    fg: Color,
    bg: Color,
};

pub fn entry_color(fg: Color, bg: Color) ColorPair {
    return ColorPair.{.bg=bg, .fg=fg};
}

const Entry = packed struct.{
    char:   u8,
    color:  ColorPair,
};

pub fn entry(char: u8, color: ColorPair) Entry {
    return Entry.{.color=color, .char=char};
}

const WIDTH  = 80;
const HEIGHT = 25;

pub const terminal = struct.{
    var row    = usize(0);
    var column = usize(0);
    var color  = entry_color(Color.light_grey, Color.black);

    const buffer = @intToPtr([*]volatile u16, 0xB8000);

    fn initialize() void {
        var y = usize(0);
        while (y < HEIGHT) : (y += 1) {
            var x = usize(0);
            while (x < WIDTH) : (x += 1) {
                putCharAt(' ', color, x, y);
            }
        }
    }

    fn setColor(new_color: ColorPair) void {
        color = new_color;
    }

    fn putCharAt(c: u8, new_color: ColorPair, x: usize, y: usize) void {
        const index = y * WIDTH + x;
        // I have to do align otherwise the ptrCast fails
        const new_entry align(2) = entry(c, new_color);
        // I dont know why bitcast here fails, but this seems to work
        buffer[index] = @ptrCast(*const u16, &new_entry).*;
        // buffer[index] = @bitCast(u16, new_entry);
    }

    fn putChar(c: u8) void {
        putCharAt(c, color, column, row);
        column += 1;
        if (column == WIDTH) {
            column = 0;
            row += 1;
            if (row == HEIGHT)
                row = 0;
        }
    }

    fn write(data: []const u8) void {
        for (data) |c| putChar(c);
    }
};
