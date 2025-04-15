; To run this demo, you need to do the following:
; 1. Build LC3Tools with this branch (wip/multitask) of my fork of
;    lc3-ensemble: https://github.com/ausbin/lc3-ensemble/tree/wip/multitask
;    (To do that, clone my fork there, check out the wip/multitask branch, and
;     then also clone the LC3Tools repository
;     https://github.com/gt-cs2110/lc3tools, and then go to
;     src/backend/Cargo.toml inside the LC3Tools repository and make the
;     following change:
;        #lc3-ensemble = "0.9.2"
;        lc3-ensemble = { path = "path/to/your/lc3-ensemble/dir" }
;     and then follow the rest of Henry's instructions for building LC3Tools.)
; 2. Open demo.asm in LC3Tools, assemble it as usual
; 3. Before running demo.obj in the LC3Tools simulator, click the timer
;    interrupt icon in the top right and configure it as follows:
;        Vector -> x81 (the default)
;        Priority -> 7 (CRITICAL, otherwise the preemption code could preempt
;                       itself)
;        Repeat -> Something big like 250 instructions
; 4. Run it! You should see "AAAAAABBBBBAAAAABBBBBBAAAAAA..." in the console.

; TASK #0
.orig x3000
ld r0, ASCII_A
LOOP_A
    putc
    br LOOP_A

ASCII_A .fill x41
.end

; TASK #1
.orig x4000
ld r0, ASCII_B
LOOP_B
    putc
    br LOOP_B

ASCII_B .fill x42
.end
