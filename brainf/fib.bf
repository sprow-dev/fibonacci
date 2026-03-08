(Cell 0: Loop Control | Cell 1: A | Cell 2: B | Cell 3: Temp)
+ (Set Cell 0 to 1)
> + (Set Cell 1 to 1)
> + (Set Cell 2 to 1)
<< (Return to Cell 0)

[
    > (Move to Cell 1/A)
    [ - > + > + << ] (Move A to B and Temp)
    >> [ - << + >> ] (Move Temp back to A)
    < [ - > + < ]    (Add B to A)

    . (Output Cell 2)

    (Output Comma ASCII 44)
    > ++++++++++++++++++++++++++++++++++++++++++++ .
    [-] (Clear Comma cell)

    <<< (Back to Cell 0)
]
