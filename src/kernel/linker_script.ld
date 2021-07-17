/* Tell the linker that we want the symbol _start to be our entry point */
ENTRY(kernel_main)

/*PHDRS*/
/*{*/
  /*none   PT_NULL FLAGS(0);*/
  /*text   PT_LOAD FLAGS((1 << 2) | (1 << 0) [> Readable | Executable <]);*/
  /*rodata PT_LOAD FLAGS((1 << 2)            [> Readable <]);*/
  /*data   PT_LOAD FLAGS((1 << 2) | (1 << 1) [> Readable | Writeable  <]);*/
/*} */
SECTIONS
{
    .stivale2hdr 0:
    {
        QUAD(kernel_main)
        QUAD(stack_high)
        QUAD(1 << 1) // flags // higher half
        QUAD(stivale2_tags)
    }

    . = 0xffffffff80200000;
 
    /* Then let's place all the other traditional executable sections afterwards. */
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
        QUAD(0) // flags
        QUAD(0) // width
        QUAD(0) // height
        QUAD(0) // bpp
        stivale2_framebuffer_tag_after = .;

        stivale2_terminal_tag = .;
        QUAD(0xa85d499b1823be72) // identifier
        QUAD(0) // next
        QUAD(0) // flags

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
