.syntax unified
.include "src/libcomp2300/macros.S"


.data
pitch_index_sender:
  .byte 0 @ this is the index of the note currently playing (This is only visable in the sender's side) 
.text
