const std = @import("std");
const Stivale2 = @import("stivale2.zig");

export fn kernel_main(stivale2: *Stivale2.Struct) void
{
    const terminal_structure_tag_ptr = stivale2.get_tag(Stivale2.HeaderTag.Terminal.id);
    if (terminal_structure_tag_ptr == 0)
    {
        while (true)
        {
            asm volatile("hlt");
        }
    }

    const terminal_structure_tag = @intToPtr(*Stivale2.StructTag.Terminal, terminal_structure_tag_ptr);
    const terminal_write = @intToPtr(fn([*:0] const u8, usize) void, terminal_structure_tag.term_write);

    terminal_write("Hello world", 11);

    while (true)
    {
        asm volatile("hlt");
    }
}
