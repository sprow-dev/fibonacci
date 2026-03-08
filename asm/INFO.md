# The worker is written in ASM.
I **didn't** put the main thread code into ASM.
**Making a thread sleep for 5 seconds** in ASM **is an absolute pain**.
However, under the hood, **the code that matters is in ASM**.
The **launcher is still written in C**,which is the closest you will get to ASM without ASM.
Also, strange quirk but it segfaults if you don't delete fib.txt between each run.
Make sure to go do that. I am so tired of staring at assembly for hours.
Run make to build the program. It will output to file fib.
**Note for Windows users**: you may need workarounds to build this.
I only tested on Linux.
