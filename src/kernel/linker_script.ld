ENTRY(kernel_main)

SECTIONS
{
    .stivale2hdr 0:
    {
        QUAD(kernel_main)
        QUAD(stack_high)
        QUAD(0)
        QUAD(stivale2_tags)
    }

    . = 0xFFFFFFFF80100000;
 
    .text . :
    {
        *(.text*)
    }:text

    . = ALIGN(64K);
 
    .rodata . :
    {
        stivale2_tags = .;

        stivale2_framebuffer_tag = .;
        QUAD(0x3ecc1bc43d0f7971) // identifier
        QUAD(stivale2_framebuffer_tag_after) // next
        SHORT(0) // width
        SHORT(0) // height
        SHORT(0) // bpp
        stivale2_framebuffer_tag_after = .;

        stivale2_terminal_tag = .;
        QUAD(0xa85d499b1823be72) // identifier
        QUAD(stivale2_terminal_tag_after) // next
        QUAD(0) // flags

        stivale2_terminal_tag_after = .;

        QUAD(0xAAAAAAAAAAAAAAAA)
        QUAD(0)

        *(.rodata*)
    }:rodata
 
    . = ALIGN(64K);

    .data . :
    {
        *(.data*)
    }:data

    . = ALIGN(64K);
 
    .bss . :
    {
        stack_low = .;
        . += 64K;
        stack_high = .;

        *(.bss*)
    }
}
