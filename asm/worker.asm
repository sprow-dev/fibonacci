section .data
    f_nm db "fib.txt", 0
    lim  dq 0x3FFFFFFFFFFFFFFF

section .bss
    alignb 64
    fd       resq 1
    s_ptr    resq 1
    p_a      resq 1
    p_b      resq 1
    p_n      resq 1
    f0       resq 1
    f1       resq 1
    f2       resq 1
    alignb 4096
    b0       resb 67108864
    b1       resb 67108864
    b2       resb 67108864
    alignb 16
    stk      resb 65536

section .text
global worker

c_proc:
    ; set affinity 0x10
    mov rax, 203
    xor rdi, rdi
    mov rsi, 128
    push 0x10
    mov rdx, rsp
    syscall
    add rsp, 8
    xor r12, r12
.l0:
    mov rdi, [rel s_ptr]
    movzx eax, byte [rdi]
    test eax, eax
    jnz .done
    lea rsi, [rel f0]
    lea rbx, [rel b0]
    cmp r12, 1
    je .s1
    cmp r12, 2
    je .s2
    jmp .chk
.s1:
    lea rsi, [rel f1]
    lea rbx, [rel b1]
    jmp .chk
.s2:
    lea rsi, [rel f2]
    lea rbx, [rel b2]
.chk:
    xor rdx, rdx
    xchg [rsi], rdx ; xchg lock
    test rdx, rdx
    jz .l0
    ; io write
    mov rax, 1
    mov rdi, [rel fd]
    mov rsi, rbx
    syscall
    inc r12
    cmp r12, 3
    jne .l0
    xor r12, r12
    jmp .l0
.done:
    mov rax, 3
    mov rdi, [rel fd]
    syscall
    ret

worker:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    mov [rel s_ptr], rdi
    ; zero out signals
    mov qword [rel f0], 0
    mov qword [rel f1], 0
    mov qword [rel f2], 0
    ; open/create
    mov rax, 2
    lea rdi, [rel f_nm]
    mov rsi, 65
    mov rdx, 0666o
    syscall
    mov [rel fd], rax
    ; set affinity 0x04
    mov rax, 203
    xor rdi, rdi
    mov rsi, 128
    push 0x04
    mov rdx, rsp
    syscall
    add rsp, 8
    ; mmap 48mb
    mov rax, 9
    xor rdi, rdi
    mov rsi, 50331648
    mov rdx, 3
    mov r10, 34
    mov r8, -1
    xor r9, r9
    syscall
    mov [rel p_a], rax
    add rax, 16777216
    mov [rel p_b], rax
    add rax, 16777216
    mov [rel p_n], rax
    ; clone consumer
    mov rax, 56
    mov rdi, 0x00010f00
    lea rsi, [rel stk + 65536 - 64]
    syscall
    test rax, rax
    jz c_proc
    ; init big-int pointers
    mov r13, [rel p_a]
    mov r14, [rel p_b]
    mov r15, [rel p_n]
    mov qword [r13], 0
    mov qword [r14], 1
    mov rbx, 4
    xor r9, r9
    xor r10, r10
.loop:
    lea r12, [rel b0]
    cmp r9, 1
    je .t1
    cmp r9, 2
    je .t2
    jmp .m
.t1: lea r12, [rel b1]
    jmp .m
.t2: lea r12, [rel b2]
.m:
    clc
    xor rax, rax
    lea r11, [r12 + r10]
.inner:
    mov r8, [r13 + rax*8]
    adc r8, [r14 + rax*8]
    mov [r15 + rax*8], r8
    ; nt-stores
    vmovdqu ymm0, [r15 + rax*8]
    vmovntdq [r11 + rax*8], ymm0
    add rax, 4
    cmp rax, rbx
    jb .inner
    lea rax, [rbx * 8]
    add r10, rax
    add r10, 31
    and r10, -32
    ; ptr rotation
    mov rax, r13
    mov r13, r14
    mov r14, r15
    mov r15, rax
    cmp r10, 60000000
    jb .ovf
    sfence
    lea rsi, [rel f0]
    cmp r9, 1
    je .g1
    cmp r9, 2
    je .g2
    jmp .g0
.g1: lea rsi, [rel f1]
    jmp .g0
.g2: lea rsi, [rel f2]
.g0:
    xchg [rsi], r10 ; signal consumer
    inc r9
    cmp r9, 3
    jne .rst
    xor r9, r9
.rst:
    xor r10, r10
    lea rsi, [rel f0]
    cmp r9, 1
    je .w1
    cmp r9, 2
    je .w2
    jmp .w0
.w1: lea rsi, [rel f1]
    jmp .w0
.w2: lea rsi, [rel f2]
.w0:
    pause
    cmp qword [rsi], 0
    jne .w0
.ovf:
    mov rdi, [rel s_ptr]
    movzx eax, byte [rdi]
    test eax, eax
    jnz .exit
    mov rax, [r14 + rbx*8 - 8]
    cmp rax, [rel lim]
    jb .loop
    add rbx, 4
    cmp rbx, 1000000
    jb .loop
.exit:
    vzeroupper
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
