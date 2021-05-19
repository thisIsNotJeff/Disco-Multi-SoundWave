.syntax unified
.include "src/libcomp2300/macros.S"

.global main

.type main, %function
main:
  bl init

  ldr r0, = 20000
  ldr r1, = 0x7fff
  bl wave_change
  play:
    bl wave_play_next_sample
    b play

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
  pop {lr}
  bx lr



@ Increase the index in a data structure 
@ by 1. If it's already 7, then it will be 0.
@ --parameters--
@ r0: address of the data structure. 
.global next_index
.type next_index, %function
next_index:
  @ ldr r0, =pitch_sequence
  @ find out the currently note index
  ldrb r1, [r0]
  @ if it's already the last note
  @ then roll back to the index 0.
  cmp r1, #7
  beq to_index_0

  @ else pick the next note
  add r1, 1
  @ update the index
  strb r1, [r0]
  bx lr

  to_index_0:
    mov r1, 0
    strb r1, [r0]
    bx lr





