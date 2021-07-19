const std = @import("std");
const Stivale2 = @import("stivale2.zig");
const Serial = @import("arch/x86_64/serial.zig");

fn stall() noreturn
{
    while (true)
    {
        asm volatile("hlt");
    }
}

pub fn kpanic(comptime fmt: []const u8, args: anytype) noreturn
{
    var message: [8192]u8 = undefined;
    panic(std.fmt.bufPrint(message[0..], fmt, args) catch unreachable, null);
}

pub fn panic(message: []const u8, stack_trace: ?*std.builtin.StackTrace) noreturn
{
    writer.writeAll("Panic:\t") catch unreachable;
    writer.writeAll(message) catch unreachable;
    stall();
}

const serial_port = Serial.Port.COM[1];
const writer = serial_port.writer();

export fn kernel_main(stivale2: *Stivale2.Struct) noreturn
{
    serial_port.initialize(.@"115200");

    try writer.print("Hello world, serial driver\n", .{});

    const smp_info_bsp = blk:
    {
        if (stivale2.get_tag(Stivale2.StructTag.SMP.id)) |smp_struct_tag_ptr|
        {
            const smp_struct_tag = @ptrCast(*const Stivale2.StructTag.SMP, smp_struct_tag_ptr);
            const smp_info = smp_struct_tag.get_smp_info();
            for (smp_info) |smp, i|
            {
                if (smp_struct_tag.BSP_LAPIC_ID == smp.lapic_id)
                {
                    break :blk smp;
                }
            }

            unreachable;
        }
        else
        {
            kpanic("Not found...\n", .{});
        }
    };
    try writer.print("BSP: {}\n", .{smp_info_bsp});
    stall();
}
