.syntax unified
.global main

.type main, %function
main:
  @ b exercise_3

  @ Your code goes here

@ a simple infinite loop
end_loop:
  nop
  b end_loop
.size main, .-main

@ a place for your to complete exercise 3. uncomment line 6 when you're ready to start working on it!
exercise_3:
  @ set the negative flag
  @... your instruction(s) go here ...

  @ set the zero flag
  @... your instruction(s) go here ...

  @ set the carry flag
  @... your instruction(s) go here ...

  @ set the overflow flag
  @... your instruction(s) go here ...
  
  nop

  b exercise_3 @ loop back to the beginning of this section--we don't want to fall off the end of the world!