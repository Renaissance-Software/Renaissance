const std = @import("std");
const x86_64 = @import("../x86_64.zig");

const IOPort = @import("port.zig");

const COM1_base = 0x3F8;

const line_enable_DLAB = 0x80;

pub const Port = struct
{
    io: IOPort,

    const Self = @This();

    pub const @"1" = Port.new(0x3F8);
    pub const @"2" = Port.new(0x2F8);
    pub const @"3" = Port.new(0x3E8);
    pub const @"4" = Port.new(0x2E8);

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
};

const COM = enum(u16)
{

    const Self = @This();

};

const BaudRate = enum(u8)
{
    @"115200" = 1, // = 115200,
    @"57600" = 2, // = 57600,
    @"38400" = 3, // = 38400,
    @"28800" = 4, // = 28800,
};


//const Portu8 = x86_64.structures.port.Portu8;

//const DATA_READY: u8 = 1;
//const OUTPUT_READY: u8 = 1 << 5;

///// Represents a UART SerialPort with support for formatted output, no input implemented
//pub const SerialPort = struct
//{
    //z_ata_port: Portu8,
    //z_line_status_port: Portu8,

    ///// Initalize the serial port at `com_port` with the baud rate `baud_rate` 

    //inline fn waitForOutputReady(self: SerialPort) void
    //{
        //while (self.z_line_status_port.read() & OUTPUT_READY == 0)
        //{
            //x86_64.instructions.pause();
        //}
    //}

    //inline fn waitForInputReady(self: SerialPort) void
    //{
        //while (self.z_line_status_port.read() & DATA_READY == 0)
        //{
            //x86_64.instructions.pause();
        //}
    //}

    //fn sendByte(self: SerialPort, data: u8) void
    //{
        //switch (data)
        //{
            //8, 0x7F =>
            //{
                //self.waitForOutputReady();
                //self.z_data_port.write(8);
                //self.waitForOutputReady();
                //self.z_data_port.write(' ');
                //self.waitForOutputReady();
                //self.z_data_port.write(8);
            //},
            //else =>
            //{
                //self.waitForOutputReady();
                //self.z_data_port.write(data);
            //},
        //}
    //}

    //pub fn readByte(self: SerialPort) u8
    //{
        //return self.z_data_port.read();
    //}

    //pub fn readByteWait(self: SerialPort) u8
    //{
        //self.waitForInputReady();
        //return self.readByte();
    //}

    //pub const Writer = std.io.Writer(SerialPort, error{}, writerImpl);
    //pub fn writer(self: SerialPort) Writer
    //{
        //return .{ .context = self };
    //}

    ///// The impl function driving the `std.io.Writer`
    //fn writerImpl(self: SerialPort, bytes: []const u8) error{}!usize
    //{
        //for (bytes) |char|
        //{
            //self.sendByte(char);
        //}
        //return bytes.len;
    //}

    //comptime
    //{
        //std.testing.refAllDecls(@This());
    //}
//};

//comptime
//{
    //std.testing.refAllDecls(@This());
//}
//d
