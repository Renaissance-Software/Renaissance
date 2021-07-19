const std = @import("std");
const x86_64 = @import("../x86_64.zig");

const IOPort = @import("port.zig");


pub const Port = struct
{
    io: IOPort,

    const Self = @This();

    pub const COM = [5]Self
    {
        undefined,
        Port.new(0x3F8),
        Port.new(0x2F8),
        Port.new(0x3E8),
        Port.new(0x2E8),
    };

    const data = 1;
    const output = 1 << 5;

    inline fn new(p: u16) Port
    {
        return Port { .io = IOPort.new(p), };
    }

    inline fn get_value(self: Port) u16
    {
        return self.io.port;
    }

    fn from_offset(self: Self, comptime offset: comptime_int) Port
    {
        return Port
        {
            .io = IOPort
            {
                .port = self.io.port + offset,
            }
        };
    }

    fn write(self: Self, byte: u8) void
    {
        self.io.write(u8, byte);
    }

    fn read(self: Self) u8
    {
        return self.io.read(u8);
    }

    fn msb_divisor(self: Self) Self
    {
        return self.from_offset(1);
    }

    fn interrupt_identification_and_FIFO_control(self: Self) Self
    {
        return self.from_offset(2);
    }

    fn line_control(self: Self) Self
    {
        return self.from_offset(3);
    }

    fn modem_control(self: Self) Self
    {
        return self.from_offset(4);
    }

    fn line_status(self: Self) Self
    {
        return self.from_offset(5);
    }

    fn modem_status(self: Self) Self
    {
        return self.from_offset(6);
    }

    fn scratch(self: Self) Self
    {
        return self.from_offset(7);
    }

    pub fn initialize(self: Self, baud_rate: BaudRate) void
    {
        const interrupt_switch_port = self.msb_divisor(); // 1
        const FIFO_control_port = self.interrupt_identification_and_FIFO_control(); // 2
        const line_control_port = self.line_control(); // 3
        const modem_control_port = self.modem_control(); // 4

        interrupt_switch_port.write(0x00);

        line_control_port.write(0x80);
        self.write(@enumToInt(baud_rate));
        interrupt_switch_port.write(0x01);

        line_control_port.write(0x03);

        FIFO_control_port.write(0xc7);

        modem_control_port.write(0x0b);

        interrupt_switch_port.write(0x01);
    }

    fn line_status_port(self: Self) Port
    {
        return self.from_offset(5);
    }

    fn wait_for(self: Self, comptime what: comptime_int) void
    {
        while (self.line_status_port().read() & what == 0)
        {
            x86_64.pause();
        }
    }

    fn send_byte(self: Self, byte: u8) void
    {
        switch (byte)
        {
            0x08, 0x7f => 
            {
                self.wait_for(output);
                self.write(0x08);
                self.wait_for(output);
                self.write(' ');
                self.wait_for(output);
                self.write(0x08);
            },
            else =>
            {
                self.wait_for(output);
                self.write(byte);
            },
        }
    }

    fn read_byte(self: Self) u8
    {
        return self.read();
    }

    fn read_byte_waiting(self: Self) u8
    {
        self.wait_for(input);
        return self.read_byte();
    }

    pub const Writer = std.io.Writer(Self, error{}, writer_implementation);

    pub fn writer(self: Self) Writer
    {
        return .{ .context = self };
    }

    fn writer_implementation(self: Self, bytes: []const u8) !usize
    {
        for (bytes) |byte|
        {
            self.send_byte(byte);
        }

        return bytes.len;
    }

    const BaudRate = enum(u8)
    {
        @"115200" = 1, // = 115200,
        @"57600" = 2, // = 57600,
        @"38400" = 3, // = 38400,
        @"28800" = 4, // = 28800,
    };
};
