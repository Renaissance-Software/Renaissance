const std = @import("std");
const Stivale2 = @import("stivale2.zig");
const Serial = @import("./arch/x86_64/serial.zig");

fn stall() noreturn
{
    while (true)
    {
        asm volatile("hlt");
    }
}

const Terminal = struct
{
    var write: fn([*]const u8, usize) void = undefined;

    fn init(stivale2: *Stivale2.Struct) void
    {
        const terminal_structure_tag_ptr = stivale2.get_tag(Stivale2.StructTag.Terminal.id);
        if (terminal_structure_tag_ptr == null)
        {
            stall();
        }

        const terminal_structure_tag = @ptrCast(*Stivale2.StructTag.Terminal, terminal_structure_tag_ptr.?);
        write = @intToPtr(@TypeOf(write), terminal_structure_tag.term_write);
    }
};

pub fn print(comptime format: []const u8, args: anytype) void
{
    var buffer: [16 * 1024]u8 = undefined;
    const slice = std.fmt.bufPrint(buffer[0..], format, args) catch unreachable;
    Terminal.write(slice.ptr, slice.len);
}

export fn kernel_main(stivale2: *Stivale2.Struct) noreturn
{
    Terminal.init(stivale2);

    Serial.Port.@"1".initialize(.@"115200");
    try Serial.Port.@"1".writer().print("Hello world, serial driver\n", .{});

    stall();
}
