ENTRY(_start)
SECTIONS {
    .text :
    {
        *(.text)
    }

    .rodata :
    {
        *(.rodata)
    }
}