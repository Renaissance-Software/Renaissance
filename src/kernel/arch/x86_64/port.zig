usingnamespace @import("../x86_64.zig");

const Port = @This();

port: u16,

pub fn new(desired_port: u16) Port
{
    return Port
    {
        .port = desired_port,
    };
}

pub fn write(self: Port, comptime T: type, value: T) callconv(.Inline) void
{
    const bytes: comptime_int = @sizeOf(T);
    switch (bytes)
    {
        1 => outb(self.port, value),
        2 => outw(self.port, value),
        4 => outl(self.port, value),
        else => @panic("incorrect size"),
    }
}

pub fn read(self: Port, comptime T: type) callconv(.Inline) T
{
    const bytes: comptime_int = @sizeOf(T);
    const result = switch (bytes)
    {
        1 => inb(self.port),
        2 => inw(self.port),
        4 => inl(self.port),
        else => @panic("incorrect size"),
    };

    return result;
}

