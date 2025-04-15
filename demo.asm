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

; This is the operating system code for implementing preemptive multitasking.
; Thankfully, the loader in LC3Tools allows modifying privileged memory
.orig x0181
.fill PREEMPT
.end

.orig x0400
SAVED_USP   .fill xFFFA
CUR_TASK    .fill 0
TASK0_OS_SP .fill x3000
TASK0_PC    .fill x3000
TASK0_PSR   .fill x8002
TASK0_REGS  .blkw 8
TASK1_OS_SP .fill x2000
TASK1_PC    .fill x4000
TASK1_PSR   .fill x8002
TASK1_REGS  .blkw 8

PREEMPT:
    ; Back up R0
    add r6, r6, -1
    str r0, r6, 0
    ; Back up R1
    add r6, r6, -1
    str r1, r6, 0

    ; otherwise we are in a user task
    ld r0, CUR_TASK
    brz SWAP_TO_TASK1

    ; This is task 1. Swap to task 0 now
    ldr r0, r6, 2 ; r0 <- PC
    st r0, TASK1_PC ; back up Task 1 PC
    ldr r0, r6, 3 ; r0 <- PSR
    st r0, TASK1_PSR ; back up Task 1 PSR
    ; Back up Task 1 R2-R5 and R7
    lea r0, TASK1_REGS
    str r2, r0, 2
    str r3, r0, 3
    str r4, r0, 4
    str r5, r0, 5
    str r7, r0, 7
    ; Back up Task 1 R6
    ldr r1, r6, 3 ; r1 <- PSR
    brn TASK1_WAS_USER
        ; Task 1 was privileged
        add r1, r6, 2 ; recover old r6
        st r6, TASK1_OS_SP
        br SKIP_TASK1_WAS_USER
    TASK1_WAS_USER
        ldi r1, SAVED_USP
        str r1, r0, 6
    SKIP_TASK1_WAS_USER
    ; Back up Task 1 R1
    ldr r1, r6, 0
    str r1, r0, 1
    ; Back up Task 1 R0
    ldr r0, r6, 1
    st r0, TASK1_REGS
    ; Now swap to task 0
    lea r0, TASK0_REGS
    ; Restore R2-R5 and R7
    ldr r2, r0, 2
    ldr r3, r0, 3
    ldr r4, r0, 4
    ldr r5, r0, 5
    ldr r7, r0, 7
    ; Restore R6
    ld r1, TASK0_PSR ; r1 <- task1 PSR
    brzp TASK0_IS_PRIV
        ; We are swapping into a user process. Need to set its USSP
        ldr r1, r0, 6
        sti r1, SAVED_USP
    TASK0_IS_PRIV
    ; Restore R1 to stack
    ldr r1, r0, 1
    str r1, r6, 0
    ; Restore R0 to stack
    ld r0, TASK0_REGS
    str r0, r6, 1
    ; Push PC and PSR onto other process's supervisor stack
    ld r1, TASK0_OS_SP
    ; Push PSR first
    ld r0, TASK0_PSR
    add r1, r1, -1
    str r0, r1, 0
    ; Then push PC
    ld r0, TASK0_PC
    add r1, r1, -1
    str r0, r1, 0
    ; Make sure the ld below uses the updated SSP
    st r1, TASK0_OS_SP
    ; Scribble down that we are now in task 0
    and r0, r0, 0
    st r0, CUR_TASK
    ; WRAP UP
    ; Pop R1
    ldr r1, r6, 0
    add r6, r6, 1
    ; Pop R0
    ldr r0, r6, 0
    add r6, r6, 1
    ; Pop both PC and PSR from this thread's stack
    add r6, r6, 2
    ; Crucial: make sure Saved_SSP is right
    st r6, TASK1_OS_SP
    ld r6, TASK0_OS_SP
    rti

    SWAP_TO_TASK1
    ; This is task 0. Swap to task 1 now
    ldr r0, r6, 2 ; r0 <- PC
    st r0, TASK0_PC ; back up Task 0 PC
    ldr r0, r6, 3 ; r0 <- PSR
    st r0, TASK0_PSR ; back up Task 0 PSR
    ; Back up Task 0 R2-R5 and R7
    lea r0, TASK0_REGS
    str r2, r0, 2
    str r3, r0, 3
    str r4, r0, 4
    str r5, r0, 5
    str r7, r0, 7
    ; Back up Task 0 R6
    ldr r1, r6, 3 ; r1 <- PSR
    brn TASK0_WAS_USER
        ; Task 1 was privileged
        add r1, r6, 2 ; recover old r6
        br SKIP_TASK0_WAS_USER
    TASK0_WAS_USER
        ldi r1, SAVED_USP
    SKIP_TASK0_WAS_USER
        str r1, r0, 6
    ; Back up Task 0 R1
    ldr r1, r6, 0
    str r1, r0, 1
    ; Back up Task 0 R0
    ldr r0, r6, 1
    st r0, TASK0_REGS
    ; Now swap to task 1
    lea r0, TASK1_REGS
    ; Restore R2-R5 and R7
    ldr r2, r0, 2
    ldr r3, r0, 3
    ldr r4, r0, 4
    ldr r5, r0, 5
    ldr r7, r0, 7
    ; Restore Task 1 R6
    ld r1, TASK1_PSR ; r1 <- task 1 PSR
    brzp TASK1_IS_PRIV
        ; We are swapping into a user process. Need to set its USSP
        ldr r1, r0, 6
        sti r1, SAVED_USP
    TASK1_IS_PRIV
    ; Restore Task 1 R1 to stack
    ldr r1, r0, 1
    str r1, r6, 0
    ; Restore Task 1 R0 to stack
    ld r0, TASK1_REGS
    str r0, r6, 1
    ; Push PC and PSR onto other process's supervisor stack
    ld r1, TASK1_OS_SP
    ; Push PSR first
    ld r0, TASK1_PSR
    add r1, r1, -1
    str r0, r1, 0
    ; Then push PC
    ld r0, TASK1_PC
    add r1, r1, -1
    str r0, r1, 0
    ; Make sure the ld below uses the updated SSP
    st r1, TASK1_OS_SP
    ; Scribble down that we are now in task 1
    and r0, r0, 0
    add r0, r0, 1
    st r0, CUR_TASK
    ; WRAP UP
    ; Pop R1
    ldr r1, r6, 0
    add r6, r6, 1
    ; Pop R0
    ldr r0, r6, 0
    add r6, r6, 1
    ; Pop both PC and PSR from this thread's stack
    add r6, r6, 2
    ; Crucial: make sure Saved_SSP is right
    st r6, TASK0_OS_SP
    ld r6, TASK1_OS_SP
    rti
.end
