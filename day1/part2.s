.extern printf

.section .data
res_str: .string "Result: %d\n"
buffer: .byte 0 # single byte buffer for input loop

.section .text
.globl _start
_start:
    # use r12 to track direction
    push %r12
    # use r13 to track number of rotations left
    push %r13
    # use r14 to track dial
    push %r14
    # use r15 to track number of zeros seen
    push %r15

    # clear counter
    xor %r15, %r15
    # set dial to 50
    mov $50, %r14

newline:
    # read char
    mov $0, %rax # sys_read
    mov $0, %rdi # stdin
    lea buffer(%rip), %rsi
    mov $1, %rdx
    syscall

    # clear the rotation on each line
    xor %r13, %r13
    
    # newline will always be followed by EOF, 'L', or 'R'

    cmp $0, %rax # check for EOF
    je print_res

    mov buffer(%rip), %rax

    cmp $'L', %rax
    je mark_left

    cmp $'R', %rax
    je mark_right
    
    jmp exit

mark_left:
    # use 0 to represent left
    xor %r12, %r12
    jmp parse_number

mark_right:
    # use 1 to represent right
    mov $1, %r12
    jmp parse_number

parse_number:
    # read until newline

    # read char
    mov $0, %rax # sys_read
    mov $0, %rdi # stdin
    lea buffer(%rip), %rsi
    mov $1, %rdx
    syscall

    mov buffer(%rip), %rax

    cmp $10, %rax # newline
    je rotate_dial

    # if rax is not a newline, it is an ascii number
    sub $48, %rax # convert to decimal

    # accumulate the number
    imul $10, %r13
    add %rax, %r13

    jmp parse_number

rotate_dial:
    # repeat instruction (left or right) until counter depletes (r13)
    cmp $0, %r13
    je newline

    # check if left or right
    cmp $0, %r12 # 0 is left
    je rotate_left
    jmp rotate_right

rotate_left:
    sub $1, %r14
    cmp $0, %r14 # first check if dial is at 0
    jne check_neg
    # dial is at 0
    add $1, %r15
    jmp dec_count
check_neg:
    cmp $-1, %r14
    jne dec_count
    # negative, wrap around
    add $100, %r14
    jmp dec_count

rotate_right:
    add $1, %r14
    cmp $100, %r14
    jne dec_count
    # 100, wrap around
    sub $100, %r14
    # now at 0, add 1 to the counter
    add $1, %r15
    jmp dec_count

dec_count:
    sub $1, %r13
    jmp rotate_dial

print_res:
    mov %r15, %rsi
    lea res_str(%rip), %rdi
    call printf

exit:
    # restore registers
    pop %r15
    pop %r14
    pop %r13
    pop %r12

    mov $60, %rax # sys_exit
    mov $0, %rdi
    syscall
