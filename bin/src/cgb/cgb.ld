ENTRY (_start)

SECTIONS {
  . = 0x400000 + SIZEOF_HEADERS;
  .note.gnu.build-id : { *(.note.gnu.build-id) }

  /* Don't be silly and use proper alignment. */
  . = ALIGN (CONSTANT (MAXPAGESIZE));

  /* The /cgb/ program does not define any .rodata itself, but the compiler
   * generates some .rodata.* constants for its own purposes - merge them into
   * the .text section. */
  .text : { *(.text) *(.rodata.*) }
  .comment : { *(.comment) }

  /DISCARD/ : { *(.*) }
}
