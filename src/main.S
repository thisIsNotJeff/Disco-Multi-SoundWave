.syntax unified
.include "src/libcomp2300/macros.S"

.global main

.type main, %function
main:
  bl init

  bl configure_lines

  ldr r0, =pitch_sequence_sender @ r0 <- start address of pitch_sequence_sender.
  @ end address of pitch_sequence_sender in r1.
  add r1, r0, 19 @ there are 19 elements of a byte, so the size is just 19.

  @ store them in a specific location to use later.
  ldr r2, =utility_room
  str r0, [r2] 
  str r1, [r2, #4]

  init_song_via_pin_sender:
    bl play_song
    GPIOx_ODR_set E, 12
    bl count_down

  init_receiver:
    b play_note

.size main, .-main


.type configure_lines, %function
configure_lines:
  push {lr}
  @ enable SYSCGF clock 
  RCC_APB2ENR_set 0 
  @ enable gpio clock for note on/of and pitch line.
  GPIOx_clock_enable E 
  GPIOx_clock_enable H

  @ set sender for note on/off line
  GPIO_configure_output_pin E, 12
  @ set sender for pitch change line
  GPIO_configure_output_pin E, 13

  @ set receiver for note on/off line and a source of inerupt
  GPIO_configure_input_pin_it H, 0
  @ set receiver for pitch change line and a source of inerupt
  GPIO_configure_input_pin_it H, 1

  @ set note on trigger
  EXTI_set_rising_edge_trigger 0
  @ set note off trigger
  EXTI_set_falling_edge_trigger 0

  @ set pitch change trigger
  EXTI_set_rising_edge_trigger 1
  

  @ enable interrupt for both receiver.
  NVIC_set ISER 6
  NVIC_set ISER 7

  @ set inetrrupt priority
  @ give pitch change higher priority than pitch on/off (while tim7 having the lowest highest)
  mov r0, 7
  mov r1, 0b0000
  bl NVIC_IPR_set_priority

  mov r0, 6
  mov r1, 0b0001
  bl NVIC_IPR_set_priority


  pop {lr}
  bx lr



@ Increase the index in a data structure 
@ by 1. If it's already 7, then it will be 0.
@ --parameters--
@ r0: address of the data structure. 
.global next_index
.type next_index, %function
next_index:

  @ find out the current note index
  ldrb r1, [r0]
  @ if it's already the last note
  @ then roll back to the index 0.
  if "cmp r1, #7", eq, to_index_0, increase_index
  @ cmp r1, #7
  @ beq to_index_0
  
  increase_index:
    @ else pick the next note
    add r1, 1
    @ update the index
    strb r1, [r0]
    bx lr

  to_index_0:
    mov r1, 0
    strb r1, [r0]
    bx lr





