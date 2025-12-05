.extern printf

.section .data
res_str: .string "Result: %ld\n"
char: .byte 0

.section .bss
buffer: .zero 32768 # forgive me

.section .text
.globl _start
_start:
    push %rbp
    mov %rsp, %rbp

    pushq %r8
    pushq %r9 # store buffer addr
    pushq %r10 # current ingredient
    pushq %r12 # min of range
    pushq %r13 # max of range
    pushq %r14 # track number of ranges
    pushq %r15 # final res/counter

    # store buffer addr in r9
    lea buffer(%rip), %r9

    # another painful lesson, memory is random, make sure you clear these
    xor %r8, %r8
    xor %r10, %r10
    xor %r12, %r12
    xor %r13, %r13
    xor %r14, %r14
    xor %r15, %r15
    jmp new_range

new_range:
    # clear min and max
    xor %r12, %r12
    xor %r13, %r13

parse_min:
    # read until '-'
    # read char
    mov $0, %rax # sys_read
    mov $0, %rdi # stdin
    lea char(%rip), %rsi
    mov $1, %rdx
    syscall

    # assuming puzzle input structure, EOF cant be found while parsing min
    movzb char(%rip), %rax
    # if a newline is found while parsing min, then ranges input is done
    cmp $10, %rax # newline
    je parse_ingredients

    cmp $'-', %rax
    je parse_max

    # if rax is not a hyphen, it is an ascii number
    sub $48, %rax # convert to decimal

    # accumulate the min
    imul $10, %r12
    add %rax, %r12

    jmp parse_min

parse_max:
    # read until newline
    # read char
    mov $0, %rax # sys_read
    mov $0, %rdi # stdin
    lea char(%rip), %rsi
    mov $1, %rdx
    syscall

    movzb char(%rip), %rax

    cmp $10, %rax # newline
    je process_range

    # if rax is not a newline, it is an ascii number
    sub $48, %rax # convert to decimal

    # accumulate the max
    imul $10, %r13
    add %rax, %r13

    jmp parse_max

process_range:
    # TODO found a problem in logic, once a range gets updated, need to remove that range and check against all existing ranges, and repeat until no more change
    #      will be fine for part1, but work needed for part2
    mov %r14, %rax # use rax to iterate through number of ranges saved
    xor %rbx, %rbx # use rbx as the buffer idx

loop_existing_ranges:
    cmp $0, %rax
    je add_new_range

    movq (%r9,%rbx), %rcx # put min range in rcx
    movq 8(%r9,%rbx), %rdx # put max range in rdx

    # if new min is greater than max, ranges dont overlap
    cmp %rdx, %r12
    jg continue_loop

    # if new max is less than min, ranges dont overlap
    cmp %rcx, %r13
    jl continue_loop

check_min:
    # if new min is less than min, update min
    cmp %rcx, %r12
    jl update_min
check_max:
    # if new max is greater than max, update max
    cmp %rdx, %r13
    jg update_max

    # entire range is already encompassed
    jmp new_range

update_min:
    # min is at rbx
    movq %r12, (%r9,%rbx)
    # check max
    cmp %rdx, %r13
    jg update_max
    jmp new_range

update_max:
    # max is at rbx+8
    movq %r13, 8(%r9,%rbx)
    jmp new_range

continue_loop:
    add $16, %rbx
    dec %rax
    jmp loop_existing_ranges

add_new_range:
    # add new range
    # rbx already has the correct idx
    inc %r14 # counts num ranges
    movq %r12, (%r9,%rbx)
    movq %r13, 8(%r9,%rbx)
    jmp new_range

reset_parse:
    xor %r10, %r10
parse_ingredients:
    # read until EOF
    # read char
    mov $0, %rax # sys_read
    mov $0, %rdi # stdin
    lea char(%rip), %rsi
    mov $1, %rdx
    syscall # hard lesson learnt: syscall clobbers r11, so either save this reg, or don't use it

    cmp $0, %rax # check for EOF
    je print_res

    # move byte from char to rax
    movzb char(%rip), %rax

    cmp $10, %rax # newline
    je setup_check_ranges

    # if rax is not a newline, it is an ascii number
    sub $48, %rax # convert to decimal

    # accumulate the current ingredient
    imul $10, %r10
    add %rax, %r10

    jmp parse_ingredients

setup_check_ranges:
    mov %r14, %rax
    xor %rbx, %rbx
check_ranges:
    cmp $0, %rax
    je reset_parse

    movq (%r9,%rbx), %rcx # put min range in rcx
    movq 8(%r9,%rbx), %rdx # put max range in rdx

    cmp %rcx, %r10
    jge check_next
    jmp cont_check_ranges
check_next:
    cmp %rdx, %r10
    jle in_range
    jmp cont_check_ranges
in_range:
    inc %r15
    jmp reset_parse
cont_check_ranges:
    add $16, %rbx
    dec %rax
    jmp check_ranges

print_res:
    mov %r15, %rsi
    lea res_str(%rip), %rdi
    call printf

exit:
    # restore registers
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %r10
    popq %r9
    popq %r8

    leave

    mov $60, %rax # sys_exit
    mov $0, %rdi
    syscall

## useful for debugging: copy paste into function
######DEBUG#####
#pushq %rax
#pushq %rcx
#pushq %rdx
#pushq %r8
#pushq %r9
#pushq %r10
#pushq %r11
#xor %rax, %rax
#mov %rcx, %rsi
#lea res_str(%rip), %rdi
#call printf
#popq %r11
#popq %r10
#popq %r9
#popq %r8
#popq %rdx
#popq %rcx
#popq %rax
################
