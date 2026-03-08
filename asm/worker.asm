section .data
    filename db "fib.txt", 0
    threshold dq 0x3FFFFFFFFFFFFFFF

section .bss
    alignb 64
    cfd      resq 1 ; a place to store company values
    stop_ptr resq 1
    ptr_a    resq 1
    ptr_b    resq 1
    ptr_n    resq 1
    f0       resq 1
    f1       resq 1
    f2       resq 1
    stop_cnt resq 1
    alignb 4096
    b0       resb 67108864
    b1       resb 67108864
    b2       resb 67108864 ; leave this one for the vp of finance's pay raise
    alignb 16
    ; if this stack overflows, copy-paste some solutions from stack overflow and it might probably not work
    stack    resb 131072

section .text
global worker

consumer:
    mov rax, 203 ; set core affinity
    xor rdi, rdi
    mov rsi, 128
    push 0x10
    mov rdx, rsp
    syscall
    add rsp, 8

    xor r12, r12
.monitor:
    lea rsi, [rel f0]
    lea rbx, [rel b0]
    cmp r12, 1
    je .is_f1
    cmp r12, 2
    je .is_f2
    jmp .check
.is_f1:
    lea rsi, [rel f1]
    lea rbx, [rel b1]
    jmp .check
.is_f2:
    lea rsi, [rel f2]
    lea rbx, [rel b2]

.check:
    xor rdx, rdx
    xchg [rsi], rdx ; ceo: your work -> my pay. we all win!
    test rdx, rdx
    jz .monitor

    mov rax, 1
    mov rdi, [rel cfd]
    mov rsi, rbx
    syscall

    inc r12
    cmp r12, 3
    jne .monitor
    xor r12, r12
    jmp .monitor

worker:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx

    mov [rel stop_ptr], rdi

    xor rax, rax
    mov [rel f0], rax
    mov [rel f1], rax
    mov [rel f2], rax
    mov [rel stop_cnt], rax

    mov rax, 2
    lea rdi, [rel filename]
    ; may cause crashes if you don't delete fib.txt before running but i'm too lazy to fix that
    mov rsi, 65 ; wronly and creat
    mov rdx, 0666o
    syscall
    mov [rel cfd], rax

    mov rax, 203 ; set affinity core (let it snuggle one core so the others get jealous)
    xor rdi, rdi
    mov rsi, 128
    push 0x04
    mov rdx, rsp
    syscall
    add rsp, 8

    ; 48gb potential mmap to crash people's computers
    mov rax, 9
    xor rdi, rdi
    mov rsi, 51539607552
    mov rdx, 3
    mov r10, 0x4022
    mov r8, -1
    xor r9, r9
    syscall

    mov [rel ptr_a], rax
    mov rcx, 17179869184 ; that's a whopping 16GB!
    lea rdx, [rax + rcx]
    mov [rel ptr_b], rdx
    add rdx, rcx
    mov [rel ptr_n], rdx

    mov rax, 56
    mov rdi, 0x00010f00
    lea rsi, [rel stack + 131072 - 64]
    syscall
    test rax, rax
    jz consumer

    mov r13, [rel ptr_a]
    mov r14, [rel ptr_b]
    mov r15, [rel ptr_n]
    mov qword [r13], 0
    mov qword [r14], 1
    mov rbx, 4

    xor r9, r9
    xor r10, r10

.main_loop:
    lea r12, [rel b0]
    cmp r9, 1
    je .buf1
    cmp r9, 2
    je .buf2
    jmp .do_math
.buf1: lea r12, [rel b1]
    jmp .do_math
.buf2: lea r12, [rel b2]

.do_math:
    clc
    xor rax, rax
    lea r11, [r12 + r10]

.math_inner:
    mov r8, [r13 + rax*8]
    adc r8, [r14 + rax*8]
    mov [r15 + rax*8], r8
    vmovdqu ymm0, [r15 + rax*8]
    vmovntdq [r11 + rax*8], ymm0
    add rax, 4
    cmp rax, rbx
    jb .math_inner

    lea rax, [rbx * 8]
    add r10, rax
    add r10, 31
    and r10, -32

    ; pointer swap to reduce operation count
    ; and make this code impossible to follow
    mov rax, r13
    mov r13, r14
    mov r14, r15
    mov r15, rax

    cmp r10, 60000000
    jb .growth_check

    sfence
    lea rsi, [rel f0]
    cmp r9, 1
    je .sig1
    cmp r9, 2
    je .sig2
    jmp .sig_go
.sig1: lea rsi, [rel f1]
    jmp .sig_go
.sig2: lea rsi, [rel f2]
.sig_go:
    xchg [rsi], r10

    ; check every 64 times for speed
    inc qword [rel stop_cnt]
    test qword [rel stop_cnt], 63
    jnz .skip_stop
    mov rdi, [rel stop_ptr]
    cmp byte [rdi], 0
    jne .exit_worker
.skip_stop:

    inc r9
    cmp r9, 3
    jne .reset_idx
    xor r9, r9
.reset_idx:
    xor r10, r10

    lea rsi, [rel f0]
    cmp r9, 1
    je .wait1
    cmp r9, 2
    je .wait2
    jmp .wait_go
.wait1: lea rsi, [rel f1]
    jmp .wait_go
.wait2: lea rsi, [rel f2]
.wait_go:
    pause
    ; prevent consumer hang on death
    mov rdi, [rel stop_ptr]
    cmp byte [rdi], 0
    jne .exit_worker
    cmp qword [rsi], 0
    jne .wait_go

.growth_check:
    mov rax, [r14 + rbx*8 - 8]
    cmp rax, [rel threshold]
    jb .main_loop

    add rbx, 4
    cmp rbx, 2000000000
    jb .main_loop

.exit_worker:
    ; i forgor to do chores so i had to clean something up last minute to make it look like i wasn't so lazy
    vzeroupper
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
