# projectMatrix

School project of second-year for the course of Microcontrollers in group of two.
Working on an STK300 developement board (Atmega 128) and coding only in AVR_ASM, we were asked to give us a project and to implement it during the next month, being passionate with LEDs, my team mate and I decided to work on an rgb matrix 8x8 of WS2812B LEDs, driven using the protocol FastLED, and try to see what we could achieve. 

At the end our program was able to perform those 4 tasks:

-Game: the tetris song is going down, in the matrix you see the notes you have to press and you have 8 buttons you can use as if you we're in front of a piano. You have three lifes, else you have to restart. At the end of the game... reward!
-Animation: crazy stuffs going on the matrix!
-Text display: write text on the computer and see it passing through the matrix.
-FFT (using the computer microphone, our version from china was buggy), audio frequency spectrum visualization on the matrix with differents colors for eight different frequencies.

All the code is assembly for the Atmega and inside you can find an interesting way of implementing a driver (made from scratch by us) capable of replacing what FastLED is for Arduino.

Hope that could be useful to somebody.

If you have any question, feel free to contact me at: ssnnca@gmail.com
