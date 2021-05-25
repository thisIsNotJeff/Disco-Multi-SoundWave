.syntax unified

.include "src/libcomp2300/macros.S"

@ This function will play the notes based on the
@ current index at first byte of the pitch_sequence_receiver
@ --parameters--
@ none
.global play_note
.type play_note, %function
play_note:
    bl find_pitch @ r0 <- frequency of the current pitch index. 

    ldr r1, =current_amplitude
    ldrh r2, [r1] 
    mov r1, r2 @ r1 <- current amplitude of wave.

    push {r0,r1} @ save the amplitude and frequency on the stack.

    bl wave_change @ don't need to change wave every cycle, otherwise the wave is not a wave  at all!!

    b output_note @ jump right to play the node, since it's safe to assume the amplitude and pitch are up-to-date.

    maintain_output_note:

    ldr r1, =current_amplitude
    ldrh r3, [r1] @ the current amplitude, it could be changed due to the pitch on/off interruption

    bl find_pitch @ the current pitch, it could be changed due to the pitch change interruption.
    mov r2, r0
    pop {r0,r1}

    cmp r0, r2 @ check if the last pitch is the same as the current one.
    bne update_wave

    cmp r1, r3 @ check if the last amplitude is the same as the current one.
    beq push_before_output_note

    update_wave:
      mov r0, r2
      mov r1, r3
      push {r0,r1} @ save the new pitch and amplitude on the stack.
      bl wave_change @ change the wave into the new one.
      b output_note

    push_before_output_note:
      push {r0,r1}

    output_note:
      bl wave_play_next_sample
      b maintain_output_note @ don't need to change wave every cycle, otherwise the wave is not a wave  at all!!


@ This function will find the pitch of the current pitch index
@ in the pitch_sequence_receiver.
@ --parameters--
@ none
@ --return--
@ r0: pitch (frequence * 100) of the current pitch index.
.type find_pitch, %function
find_pitch:
  ldr r0, =current_pitch_index_receiver
  ldrb r1, [r0] @ r1 <- current pitch index.

  ldr r0, =pitch_sequence_receiver

  find:
    @ compare the current index with index in the pitch_sequence_receiver.
    ldrh r2, [r0] @ r2 <- pitch index in the current_pitch_sequence_receiver.

    if "cmp r1, r2", eq, return_pitch, find_next

    find_next:
      @else find next index in the sequence
      add r0, 4 @update pointer
      b find
    
    return_pitch:
      ldrh r1, [r0, #2]
      mov r0, r1 @ leave correct pitch in r0.
      bx lr 


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
.type EXTI1_IRQHandler, %function
EXTI1_IRQHandler:
  push {lr}
  EXTI_PR_clear_pending 1
  ldr r0, =current_pitch_index_receiver
  bl next_index
  pop {lr}
  bx lr

.data
@ pitch sequence table in p2300.
pitch_sequence_receiver:
  .hword 0, 22000  @ First half-word in is pitch sequence index,seconde half-word is the corresponding pitch.
  .hword 1, 24694
  .hword 2, 26163
  .hword 3, 29366
  .hword 4, 32963
  .hword 5, 36999
  .hword 6, 39200
  .hword 7, 44000

@ current pitch index for receiver's side.
current_pitch_index_receiver:
  .byte 0 @ this is the index of the note currently playing (This is only visable in the receiver's side)

current_amplitude:
  .hword 0  
.text