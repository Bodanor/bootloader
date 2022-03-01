SECTIONS
{
   .stage1 0x7c00 : AT(0) {
      *(.sector1)
   }
   .stage2 0x8000 : AT(0x200) {
      *(.sector2)
   }
}