.syntax unified

.include "src/libcomp2300/macros.S"

@ This function will play the notes based on the
@ index 
@
.type play_note, %function
play_note:
  ldr r0, =pitch_sequence
  ldrb r1, [r0], #1 @ <- r1 has the index of current note
  
  find_note:
   @ compare the current index with index in the sequene
   @ out put the node when the note is found.
    ldrh r2, [r0]
    cmp r1, r2
    beq output_note

    @else find next index in the sequence
    add r0, 4 @update pointer
    b find_note

  output_note:
    ldr r2, [r0, #2] @ r2 <- frequency * 100




@ handler for both note on and off line 
.global EXTI0_IRQHandler
.type EXTI0_IRQHandler, % function
EXTI0_IRQHandler:
  EXTI_PR_clear_pending 0
  @ figure out what kind of edge triggered the handler
  GPIOx_IDR_read H, 0

  @ if the PH0 is 1, that means the note is being turned on.
  cmp r0, 1
  beq note_on
  @ else, it's being turned off.
  note_off:
    nop
    b note_off

  note_on:
    b play_note

  
@ handler for pitch change line  
.global EXTI1_IRQHandler
.type EXTI0_IRQHandler, %function
EXTI1_IRQHandler:
  push {lr}
  EXTI_PR_clear_pending 1
  ldr r0, =pitch_sequence
  bl next_index
  pop {lr}
  bx lr

.data
@ pitch sequence table in p2300
pitch_sequence_receiver:
  .byte 0 @ this is the index of the note currently playing (This is only visable in the receiver's side)
  .hword 0, 22000  @ First byte in is pitch sequence index,seconde byte is the corresponding pitch.
  .hword 1, 24694
  .hword 2, 26163
  .hword 3, 29366
  .hword 4, 32963
  .hword 5, 36999
  .hword 6, 39200
  .hword 7, 44000
.text