.extern printf

.section .data
res_str: .string "Result: %ld\n"
buffer: .byte 0 # single byte buffer for input loop

.section .text
.globl _start
_start:
    # use r12 to track current min range
    pushq %r12
    # use r13 to track current max range
    pushq %r13
    # clobering r14
    pushq %r14
    # use r15 to track sum of invalid numbers
    pushq %r15

    # clear sum
    xor %r15, %r15

new_range:
    # clear min and max
    xor %r12, %r12
    xor %r13, %r13

parse_min:
    # read until '-'
    # read char
    mov $0, %rax # sys_read
    mov $0, %rdi # stdin
    lea buffer(%rip), %rsi
    mov $1, %rdx
    syscall
    
    cmp $0, %rax # check for EOF
    je print_res

    mov buffer(%rip), %rax

    cmp $'-', %rax
    je parse_max

    # if rax is not a hyphen, it is an ascii number
    sub $48, %rax # convert to decimal

    # accumulate the min
    imul $10, %r12
    add %rax, %r12

    jmp parse_min

parse_max:
    # read until ',' or newline
    # read char
    mov $0, %rax # sys_read
    mov $0, %rdi # stdin
    lea buffer(%rip), %rsi
    mov $1, %rdx
    syscall

    mov buffer(%rip), %rax

    cmp $',', %rax
    je iterate_range

    cmp $10, %rax # newline
    je iterate_range

    # if rax is not a comma or newline, it is an ascii number
    sub $48, %rax # convert to decimal

    # accumulate the max
    imul $10, %r13
    add %rax, %r13

    jmp parse_max

iterate_range:
    # min (r12) is incremented and used as the current value
    # if min > max then the entire range has been checked
    cmp %r13, %r12
    jg new_range

    mov %r12, %rax # pass current value to function
    call check_valid

    cmp $1, %rax
    je inc_loop # 1 means number was valid

    add %r12, %r15 # invalid, add to sum
inc_loop:
    inc %r12
    jmp iterate_range

check_valid:
    mov %rax, %r8 # keep a copy of number in r8

    # count number of digits
    call count_digits
    # keep a copy of num digits in r9
    mov %rax, %r9

    # div number of digits by 2
    xor %rdx, %rdx
    mov $2, %rbx
    div %rbx

    # loop through all numbers up to floor(length/2)
    # use r14 to track this
    mov %rax, %r14
loop_factors:
    cmp $0, %r14
    # if we are here, no pattern was found
    je valid

    # check if the number is a factor (div remainder is 0)
    mov %r9, %rax
    xor %rdx, %rdx
    mov %r14, %rbx
    div %rbx
    
    cmp $0, %rdx
    je process_factor

    dec %r14
    jmp loop_factors

process_factor:
    # if it is a factor, construct the number
    # and do division trick to check for remainder
    # find 10^rax
    mov $1, %rcx
    dec %rax
build_num:
    cmp $0, %rax
    je div_pattern
    mov %r14, %rbx

mult10:
    cmp $0, %rbx
    je add_one

    imul $10, %rcx
    dec %rbx
    jmp mult10

add_one:
    # add 1 to divisor
    inc %rcx

    dec %rax
    jmp build_num

div_pattern:
    # divide by pattern
    xor %rdx, %rdx
    mov %r8, %rax
    mov %rcx, %rbx
    div %rbx

    # if no remainder, number has a pattern
    cmp $0, %rdx
    je invalid

    dec %r14
    jmp loop_factors

valid:
    mov $1, %rax
    ret
invalid:
    xor %rax, %rax
    ret

count_digits:
    # use r9 to track the number of digits
    xor %r9, %r9

div10:
    xor %rdx, %rdx # clear high register
    mov $10, %rbx # divisor
    div %rbx

    inc %r9 # increment digit counter

    cmp $0, %rax
    jne div10
#out
    mov %r9, %rax
    ret

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

    mov $60, %rax # sys_exit
    mov $0, %rdi
    syscall
