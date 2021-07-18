pub fn outb(port: u16, value: u8) void
{
    asm volatile("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "N{dx}" (port));
}
pub fn outw(port: u16, value: u16) void
{
    asm volatile("outw %[value], %[port]"
        :
        : [value] "{ax}" (value),
          [port] "N{dx}" (port));
}
pub fn outl(port: u16, value: u32) void
{
    asm volatile("outl %[value], %[port]"
        :
        : [value] "{eax}" (value),
          [port] "N{dx}" (port));
}

pub fn inb(port: u16) u8
{
    return asm volatile("inb %[port], %[ret]"
        : [ret] "={al}" (-> u8)
        : [port] "N{dx}" (port));
}
pub fn inw(port: u16) u16
{
    asm volatile("inw %[port], %[ret]"
        : [ret] "={ax}" (-> u16)
        : [port] "N{dx}" (port));
}
pub fn inl(port: u16) u32
{
    asm volatile("inl %[port], %[ret]"
        : [ret] "={eax}" (-> u32),
        : [port] "N{dx}" (port));
}

pub fn pause() void
{
    asm volatile ("pause" ::: "memory");
}
