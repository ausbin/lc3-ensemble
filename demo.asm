.orig x3000
ld r0, ASCII_A
LOOP_A
    putc
    br LOOP_A

ASCII_A .fill x41
.end

.orig x4000
ld r0, ASCII_B
LOOP_B
    putc
    br LOOP_B

ASCII_B .fill x42
.end
