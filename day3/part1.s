.extern printf

.section .data
res_str: .string "Result: %ld\n"
num_batteries: .byte 2 # Change this to 12 for part2

.section .bss
buffer: .zero 256 # making the assumption a line wont be longer than this

.section .text
.globl _start
_start:
    # use r9 to store the buffer address for faster access
    pushq %r9
    # use r10 to track idx of current max
    pushq %r10
    # use r8 to track current max
    pushq %r8
    # use r12 to track line length
    pushq %r12
    # use r13 to track current idx
    pushq %r13
    # use r14 to track current jolts
    pushq %r14
    # use r15 to track sum
    pushq %r15
    pushq %r15 # odd numbers of regs pushed to stack causes seg fault

    # store buffer addr in r9
    lea buffer(%rip), %r9
    # clear sum
    xor %r15, %r15

newline:
    # clear line length, max and idx
    xor %r10, %r10
    xor %r8, %r8
    xor %r12, %r12
    xor %r13, %r13
    xor %r14, %r14

read_line:
    # read until '\n'
    # find the address of the next char (i.e. buffer[idx])
    lea (%r9,%r12), %rsi
    # read char
    mov $0, %rax # sys_read
    mov $0, %rdi # stdin
    mov $1, %rdx
    syscall # hard lesson learnt: syscall clobbers r11, so either save this reg, or don't use it
    
    cmp $0, %rax # check for EOF
    je print_res

    movzb (%r9,%r12), %rax

    cmp $10, %rax # newline
    je process_line

    incq %r12 #increment str len counter

    jmp read_line

process_line:
    # use rax to track num batteries left
    movzb num_batteries(%rip), %rax
    sub %rax, %r12 # the max can only be searched until (end - num batteries)
    jmp battery_loop

battery_loop:
    cmp $0, %rax
    je process_jolts

max_loop:
    cmp %r12, %r13
    jg finish_max_loop # if current idx (r13) > line length (r12)

    # check if current idx is greater than current max
    movzb (%r9,%r13), %rbx # fetch the current val
    cmp %rbx, %r8
    jge continue_loop
    # if here, update max
    mov %rbx, %r8 # max
    mov %r13, %r10 # max idx
continue_loop:
    incq %r13 # increment current idx
    jmp max_loop

finish_max_loop:
    # process max
    sub $48, %r8
    imul $10, %r14 # accumulate value
    add %r8, %r14
    xor %r8, %r8 # clear max
    # current idx = idx max
    inc %r10
    mov %r10, %r13 # set the new start idx to the idx of the previous max + 1
    inc %r12 # the max can now be searched for one closer to the end
    dec %rax # decrease batteries remaining
    jmp battery_loop

process_jolts:
    # add jolts to sum
    add %r14, %r15
    jmp newline

print_res:
    mov %r15, %rsi
    lea res_str(%rip), %rdi
    call printf

exit:
    # restore registers
    popq %r15
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %r8
    popq %r10
    popq %r9

    mov $60, %rax # sys_exit
    mov $0, %rdi
    syscall
