pub const Anchor = packed struct
{
    anchor: [15]u8,
    bits: u8,
    phys_load_addr: u64,
    phys_bss_start: u64,
    phys_bss_end: u64,
    phys_stivale2hdr: u64,
};

pub const Tag = packed struct
{
    id: u64,
    next: ?*@This(),
};
pub const Header = packed struct
{
    entry_point: u64,
    stack: u64,
    flags: u64,
    tags: *Tag
};

pub const HeaderTag = struct
{
    pub const AnyVideo = packed struct
    {
        tag: Tag,
        preference: u64,
    };
    pub const Framebuffer = packed struct
    {
        tag: Tag,
        width: u16,
        height: u16,
        bpp: u16,

        pub const id = 0x3ecc1bc43d0f7971;
    };
    pub const Terminal = packed struct
    {
        tag: Tag,
        flags: u64,

        pub const id = 0xa85d499b1823be72;
    };
    pub const SMP = packed struct
    {
        tag: Tag,
        flags: u64,
    };
};

pub const Struct = packed struct
{
    bootloader_brand: [64]u8,
    bootloader_version: [64]u8,
    tags: ?*Tag,

    pub fn get_tag(self: *@This(), id: u64) ?*Tag
    {
        var current_tag = self.tags;

        while (current_tag) |tag| : (current_tag = tag.next)
        {
            if (tag.id == id) return tag;
        }

        return null;
    }
};

pub const StructTag = struct
{
    pub const CommandLine = packed struct
    {
        tag: Tag,
        cmdline: u64,
    };
    pub const MemoryMap = opaque {};
    pub const Framebuffer = packed struct
    {
        tag: Tag,
        framebuffer_addr: u64,
        framebuffer_width: u16,
        framebuffer_height: u16,
        framebuffer_pitch: u16,
        framebuffer_bpp: u16,
        memory_model: u8,
        red_mask_size: u8,
        red_mask_shift: u8,
        green_mask_size: u8,
        green_mask_shift: u8,
        blue_mask_size: u8,
        blue_mask_shift: u8,
    }; // stivale2.h:136:14: warning: struct demoted to opaque type - has variable length array
    pub const EDID = opaque {};
    pub const TextMode = packed struct
    {
        tag: Tag,
        address: u64,
        unused: u16,
        rows: u16,
        cols: u16,
        bytes_per_char: u16,
    };
    pub const Terminal = packed struct
    {
        tag: Tag,
        flags: u32,
        cols: u16,
        rows: u16,
        term_write: u64,
        max_length: u64,

        pub const id = 0xc2b3f4c3233b0974;
    };
    pub const Modules = opaque {};
    pub const RSDP = packed struct
    {
        tag: Tag,
        rsdp: u64,
    };
    pub const Epoch = packed struct
    {
        tag: Tag,
        epoch: u64,
    };
    pub const Firmware = packed struct
    {
        tag: Tag,
        flags: u64,
    };
    pub const EFISystemTable = packed struct
    {
        tag: Tag,
        system_table: u64,
    };
    pub const KernelFile = packed struct
    {
        tag: Tag,
        kernel_file: u64,
    };
    pub const KernelSlide = packed struct
    {
        tag: Tag,
        kernel_slide: u64,
    };
    pub const SMBIOS = packed struct
    {
        tag: Tag,
        flags: u64,
        smbios_entry_32: u64,
        smbios_entry_64: u64,
    };
    pub const SMP = opaque {};
    pub const PXEServerInfo = packed struct
    {
        tag: Tag,
        server_ip: u32,
    };
    pub const MMIO32_UART = packed struct
    {
        tag: Tag,
        addr: u64,
    };
    pub const DTB = packed struct
    {
        tag: Tag,
        addr: u64,
        size: u64,
    };
    pub const VMap = packed struct
    {
        tag: Tag,
        addr: u64,
    };
};

pub const MemoryMapEntry = packed struct
{
    base: u64,
    length: u64,
    type: u32,
    unused: u32,
}; // stivale2.h:108:32: warning: struct demoted to opaque type - has variable length array

pub const Module = packed struct
{
    begin: u64,
    end: u64,
    string: [128]u8,
}; // stivale2.h:176:28: warning: struct demoted to opaque type - has variable length array
pub const SMPInfo = packed struct
{
    processor_id: u32,
    lapic_id: u32,
    target_stack: u64,
    goto_address: u64,
    extra_argument: u64,
}; // stivale2.h:248:30: warning: struct demoted to opaque type - has variable length array
