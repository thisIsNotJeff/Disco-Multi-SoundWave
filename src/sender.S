.syntax unified
.include "src/libcomp2300/macros.S"

.global play_song
.type play_song, %function
play_song:
  @ ldr r0, =utility_room
  @ ldr r1, [r0, #8] @ r1 <- whether we played a pitch or remained slient last time.
  @ cmp r1, #1
  @ beq slient

  push {r4,lr} 
  
  ldr r0, =pitch_index_sender
  ldrb r1, [r0] @ r1 <- current pitch index on sender's side

  ldr r4, =utility_room
  ldr r2, [r4] @ r2 <- next address to be used in pitch_sequence_sender.
  ldr r3, [r4, #4] @ r3 <- end address of pitch_sequence_sender.
  mov r4, 0 @ r4 <- the number of times for the receiver's side to uodate it's current index. Init it with 0.
  
  @ ldr r2, =pitch_sequence_sender
  
  @ mov r3, 19 @ r3 <- number of elements in the sequence 
  @ add r3, r2 @ end address of the sequence, since each element is a byte, add 19 

  
  adjust_pitch_index_sender:
    @ If the end address is reached, start over
    @ else adjust the pitch index to the correct one in the pitch_sequence_sender
    @ by sending the signal to receiver at PH1 
    @ updating theirs index and mine index. 
    if "cmp r2, r3", eq, start_over, is_index_equal

    start_over:
      ldr r2, =pitch_sequence_sender
      b adjust_pitch_index_sender

    @ is_slience:
    @   ldrb r0, [r2], #1 @ r0 <- the pitch index of the pitch in the sequence should be played on the receiver's side 
    @   cmp r0, #8 
    @   beq slience
    @   b is_index_equal 
      
    @ slience:
    @   bl count_down
    @   push {r0,r1,r2,r3}
    @   GPIOx_ODR_clear E, 12


    is_index_equal:
      ldrb r0, [r2]  @ r0 <- the pitch index of the pitch in the sequence should be played on the receiver's side 
      
      if "cmp r1, r0", eq, adjust_receiver, adjust_sender
 
    @ adjust the sender side's current pitch index.
    adjust_sender:
      @ update the current pitch sequence index on sender's side.
      ldr r0, =pitch_index_sender
    
      bl next_index 
      ldr r0, =pitch_index_sender
      ldrb r1, [r0] @ r1 <- updated index still in r1
      
      add r4, 1 @ increase the number of increament of receiver's side by 1.

      b is_index_equal
    
    @ adjust the receiver side's current pitch index.
    adjust_receiver:
      cmp r4, 0
      beq play_note_by_sending_signal

      cmp r4, 1
      beq switch

      @ @ note off for starting skip.
      @ GPIOx_ODR_clear E, 12

      @ to “skip” a note in the sequence the sender should send a note off messages, 
      @ then send two pitch change messages, then send the next note on message.
      skip:
        @ cmp r4, 0
        @ beq play_note_by_sending_signal
        @ cmp r4, 1
        @ beq switch
        
        push {r2}
        @ first pitch change.
        GPIOx_ODR_set E, 13 @ to next pitch.
        GPIOx_ODR_clear E, 13 @ clear it to trigger interrupt next time.
        @ second pitch change.
        GPIOx_ODR_set E, 13 
        GPIOx_ODR_clear E, 13 
        pop {r2}

        @ decrease 2 since I pitch change twice.
        sub r4, 2

        b adjust_receiver

      switch:
        push {r2}
        @ increase pitch directly.
        GPIOx_ODR_set E, 13
        @ clean it in order to set it next time.
        GPIOx_ODR_clear E, 13
        pop {r2}
        @ pop {r4} @??????????????????????????????

    play_note_by_sending_signal:
      add r2, #1 @ update the next address in the pitch_sequence_sender.
      ldr r1, =utility_room 
      str r2, [r1] @ store it in the corresponding location.

      mov r2, 1 @ this time we played an audibly pitch.
      strb r2, [r1, #8] @ store it to indicate that. 

      pop {r4, lr}
      bx lr
      @ bl count_down @ count down for 0.25 seconds @???????????????????????????????? do I need to do this here instead of in the main?
        
      @ GPIOx_ODR_set E, 12 @ send the on signal to PH0

    @ slient:
    @   mov r2, 0 @ this time we remain slient.
    @   strb r2, [r1, #8] @ store it to indicate that. 
    @   bx lr

      @ bl count_down
      @ GPIOx_ODR_clear E, 12


@ This function will delay 0.25 seconds before a corresponding interrupt being triggered.
.global count_down
.type count_down, % function
count_down:
  push {lr}
  ldr r0, =50000
  ldr r1, =400
  bl tim7_init
  pop {lr}
  bx lr
  

.global utility_room
.global pitch_sequence_sender
.global utility_room
.data
pitch_index_sender:
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
