SECTIONS
{
  .rodata.tase_records ALIGN(0x10) :
  {
    tase_global_records = .;
    KEEP (*(.rodata.tase_records))
    tase_num_global_records = .;
    QUAD((tase_num_global_records - tase_global_records) / 8)
  }


  .rodata.tase_live_flags_block_records ALIGN(0x10) :
    {
     tase_live_flags_block_records = .;
     KEEP (*(.rodata.tase_live_flags_block_records))
     tase_num_live_flags_block_records = .;
     QUAD((tase_num_live_flags_block_records  - tase_live_flags_block_records) / 8)
   }


  .rodata.tase_kill_flags_block_records ALIGN(0x10) :
   {
    tase_kill_flags_block_records = .;
    KEEP (*(.rodata.tase_kill_flags_block_records))
    tase_num_kill_flags_block_records = .;
    QUAD((tase_num_kill_flags_block_records - tase_kill_flags_block_records) / 4)
  }
  
} INSERT AFTER .rodata;
