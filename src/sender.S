.syntax unified
.include "src/libcomp2300/macros.S"

.global play_song
.type play_song, %function
play_song:
  push {r4,lr} 
  
  ldr r0, =current_pitch_index_sender
  ldrb r1, [r0] @ r1 <- current pitch index on sender's side

  ldr r4, =utility_room
  ldr r2, [r4] @ r2 <- next address to be used in pitch_sequence_sender.
  ldr r3, [r4, #4] @ r3 <- end address of pitch_sequence_sender.
  mov r4, 0 @ r4 <- the number of times for the receiver's side to uodate it's current index. Init it with 0.

  adjust_current_pitch_index_sender:
    @ If the end address is reached, start over
    @ else adjust the pitch index to the correct one in the pitch_sequence_sender
    @ by sending the signal to receiver at PH1 
    @ updating theirs index and mine index. 
    if "cmp r2, r3", eq, start_over, is_index_equal

    start_over:
      ldr r2, =pitch_sequence_sender
      b adjust_current_pitch_index_sender

    is_index_equal:
      ldrb r0, [r2]  @ r0 <- the pitch index of the pitch in the sequence should be played on the receiver's side 
      if "cmp r1, r0", eq, play_note_by_sending_signal, adjust_and_sync_current_pitch_index_on_both_side
 
    @ adjust the sender side's current pitch index.
    @ and receiver side's current pitch index (through the interrupt from PH1).
    adjust_and_sync_current_pitch_index_on_both_side:
      @ update the current pitch sequence index on sender's side.
      ldr r0, =current_pitch_index_sender
      bl next_index 

      ldr r0, =current_pitch_index_sender
      ldrb r1, [r0] @ r1 <- updated index still in r1
      
      @ update current pitch index on receiver's side.
      push {r1,r2}
      GPIOx_ODR_set E, 13 @ to next pitch.
      GPIOx_ODR_clear E, 13 @ clear it to trigger interrupt next time.
      pop {r1,r2}
      
      b is_index_equal

    play_note_by_sending_signal:
      add r2, #1 @ update the next address in the pitch_sequence_sender.
      ldr r1, =utility_room 
      str r2, [r1] @ store it in the corresponding location.

      mov r2, 1 @ this time we played an audibly pitch.
      strb r2, [r1, #8] @ store it to indicate that. 

      pop {r4, lr}
      bx lr

@ This function will delay 0.25 seconds before a corresponding interrupt being triggered.
.global count_down
.type count_down, % function
count_down:
  push {lr}
  ldr r0, =5000
  ldr r1, =4000
  bl tim7_init
  pop {lr}
  bx lr
  

.global utility_room
.global pitch_sequence_sender
.global utility_room
.data
current_pitch_index_sender:
  .byte 0 @ this is the index of the note currently playing (This is only visable in the sender's side)

utility_room:
  .word 0 @ this word is the next address to be used in the pitch_sequence_sender for play_song.
  .word 0 @ this word is the end address of pitch_sequence_sender.
  .byte 0 @ this byte indicates whether last time is an audibly pitch or slience.  1->audibly pitch \ 0->slience. 

@ Between each pitch sequence index, there is a gap (slience).
pitch_sequence_sender:
  .byte 0
  .byte 2
  .byte 1
  .byte 3
  .byte 2
  .byte 4
  .byte 3
  .byte 5
  .byte 4
  .byte 6
  .byte 5
  .byte 7
  .byte 6
  .byte 5
  .byte 4
  .byte 3
  .byte 2
  .byte 1
  .byte 0
.text
