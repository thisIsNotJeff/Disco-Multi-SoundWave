.syntax unified

.include "src/libcomp2300/macros.S"

@ This function will play the notes based on the
@ current index at first byte of the pitch_sequence_receiver
@ --parameters--
@ none
.global play_note
.type play_note, %function
play_note:
  ldr r1, =pitch_sequence_receiver
  ldrb r2, [r1], #1 @ <- r2 has the index of current note
  
  find_note:
    @ compare the current index with index in the sequene
    @ out put the node when the note is found.
    ldrh r3, [r1]

    if "cmp r2, r3", eq, output_note, find_next
    @ cmp r2, r3
    @ beq output_note

    find_next:
      @else find next index in the sequence
      add r1, 4 @update pointer
      b find_note

  output_note:
    ldr r3, [r1, #2] @ r3 <- frequency * 100

    ldr r0, =current_amplitude
    ldrh r1, [r0] @ r1 <- current amplitude of wave.
    mov r1, r0 @ r1 <- amplitude
    mov r0, r3 
    bl wave_change

    maintain_output_node:
    bl wave_play_next_sample
    b play_note

@ handler for both note on and off line 
.global EXTI0_IRQHandler
.type EXTI0_IRQHandler, % function
EXTI0_IRQHandler:
  push {lr}
  EXTI_PR_clear_pending 0
  @ figure out what kind of edge triggered the handler
  GPIOx_IDR_read H, 0

  @ if the PH0 is 1, that means the note is being turned on.
  @ cmp r0, 1
  @ beq note_on
  if "cmp r0, 1", eq, note_on, note_off
  @ else, it's being turned off.
  note_off:
    ldr r0, =current_amplitude
    mov r1, 0
    strh r1, [r0] @ update the current_amplitude
    pop {lr}
    bx lr

  note_on:
    ldr r0, =current_amplitude
    ldr r1, =0x7fff
    strh r1, [r0] @ update the current_amplitude
    pop {lr}
    bx lr


  
@ handler for pitch change line  
.global EXTI1_IRQHandler
.type EXTI0_IRQHandler, %function
EXTI1_IRQHandler:
  push {lr}
  EXTI_PR_clear_pending 1
  ldr r0, =pitch_sequence_receiver
  bl next_index
  pop {lr}
  bx lr

.data
@ pitch sequence table in p2300
pitch_sequence_receiver:
  .byte 0 @ this is the index of the note currently playing (This is only visable in the receiver's side)
  .hword 0, 22000  @ First half-word in is pitch sequence index,seconde half-word is the corresponding pitch.
  .hword 1, 24694
  .hword 2, 26163
  .hword 3, 29366
  .hword 4, 32963
  .hword 5, 36999
  .hword 6, 39200
  .hword 7, 44000

current_amplitude:
  .hword 0  
.text