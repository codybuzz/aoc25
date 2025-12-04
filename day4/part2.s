.extern printf

.section .data
res_str: .string "Result: %ld\n"
char: .byte 0

.section .bss
buffer: .zero 32768 # forgive me

.section .text
.globl _start
_start:
    pushq %r8
    pushq %r9 # store buffer addr
    pushq %r10
    pushq %r12 # track the size of the grid
    pushq %r13 # track num rows
    pushq %r14 # track num cols
    pushq %r15 # store result
    pushq %r15 # odd numbers of regs pushed to stack causes seg fault

    # store buffer addr in r9
    lea buffer(%rip), %r9

    # another painful lesson, memory is random, make sure you clear these
    xor %r8, %r8
    xor %r10, %r10
    xor %r12, %r12
    xor %r13, %r13
    xor %r14, %r14
    xor %r15, %r15

read_char:
    # read until EOF
    # read char
    mov $0, %rax # sys_read
    mov $0, %rdi # stdin
    lea char(%rip), %rsi
    mov $1, %rdx
    syscall # hard lesson learnt: syscall clobbers r11, so either save this reg, or don't use it

    cmp $0, %rax # check for EOF
    je calc_cols

    # move byte from char to rax
    movzb char(%rip), %rax

    cmp $10, %rax # newline
    je count_rows
    # only store non-newlines
    mov %rax, (%r9,%r12) # put byte in buffer
    jmp cont_read
count_rows:
    incq %r13
    jmp read_char
cont_read:
    incq %r12 #increment grid counter
    jmp read_char

calc_cols:
    xor %rdx, %rdx
    mov %r12, %rax
    mov %r13, %rbx
    div %rbx
    mov %rax, %r14
    jmp main

main:
    call process_grid
    cmp $0, %rcx
    je print_res
    add %rcx, %r15
    jmp main

process_grid:
    push %rbp
    mov %rsp, %rbp
    # iterate through row (rax), col (rbx)
    xor %r8, %r8
    xor %rax, %rax
    xor %rbx, %rbx
loop_row:
    cmp %rax, %r13
    je finish_rows
loop_col:
    cmp %rbx, %r14
    je finish_cols

    # read char
    call get_idx # idx in rcx
    movzb (%r9,%rcx), %rdx

    # check if char is '@'
    cmp $'@', %rdx
    jne next_col

    # count_neighbours returns to rcx, so save idx to rdx
    mov %rcx, %rdx

    # count neighbours
    call count_neighbours

    # if at least 4 neighbours, skip
    cmp $4, %rcx
    jge next_col

    # save the idx on the stack
    pushq %rdx

    # increase number of rolls
    inc %r8

next_col:
    inc %rbx # move to next col
    jmp loop_col
finish_cols:
    inc %rax # move to next row
    xor %rbx, %rbx # back to first col
    jmp loop_row
finish_rows:
    # pop each idx off the stack and remove the roll of paper '@'
    movq %r8, %rcx # make sure to return the num rolls in rcx
remove_roll:
    cmp $0, %r8
    je finish

    popq %rdx
    movb $'.', (%r9,%rdx) # put '.' in buffer
    dec %r8
    jmp remove_roll

finish:
    leave
    ret

# helper function used to convert row, col to an index
# takes row in rax, col in rbx, and places res in rcx
# assumes num cols is stored in r14
get_idx:
    push %rbp
    mov %rsp, %rbp
    # idx = num_cols * rows + cols
    mov %r14, %rcx
    imul %rax, %rcx
    add %rbx, %rcx
    leave
    ret

# helper function to check if a row, col is in bounds
# takes row in rax, col in rbx, and places res in rcx -> 0 for out of bounds, 1 for in bounds
# assumes num rows is stored in r13 and num cols is stored in r14
check_bounds:
    push %rbp
    mov %rsp, %rbp

    # check if row or col is negative
    test %rax, %rax
    js out_of_bounds
    test %rbx, %rbx
    js out_of_bounds
    
    # check if row is greater than or equal to num rows
    cmp %r13, %rax
    jge out_of_bounds

    # check if col is greater than or equal to num cols
    cmp %r14, %rbx
    jge out_of_bounds

    jmp in_bounds
in_bounds:
    mov $1, %rcx
    leave
    ret
out_of_bounds:
    xor %rcx, %rcx
    leave
    ret

# helper function to count how many '@' symbols are in adjacent positions
# takes row in rax and col in rbx, returns res in rcx
count_neighbours:
    push %rbp
    mov %rsp, %rbp

    # save registers that will be clobbered
    pushq %rdx
    pushq %r8 # track neighbours
    pushq %r10 # track row dir
    pushq %r11 # track col dir
    pushq %r12 # copy of rax
    pushq %r15 # copy of rbx

    xor %r8, %r8
    mov %rax, %r12
    mov %rbx, %r15

    # check all combinations of row and col
    mov $-1, %r10
    mov $-1, %r11

row_dirs:
    cmp $2, %r10
    je fin_row_dir
col_dirs:
    cmp $2, %r11
    je fin_col_dir

    # skip row,col
    cmp $0, %r10
    jne dont_skip
    cmp $0, %r11
    jne dont_skip
skip:
    inc %r11
    jmp col_dirs
dont_skip:
    # load row+row_dir,col+col_dir
    mov %r12, %rax
    add %r10, %rax
    mov %r15, %rbx
    add %r11, %rbx

    # make sure pos is in bounds
    call check_bounds
    cmp $0, %rcx
    je skip

    # get char
    call get_idx
    movzb (%r9,%rcx), %rdx

    # check if char is '@'
    cmp $'@', %rdx
    jne skip
    inc %r8
    jmp skip
fin_col_dir:
    mov $-1, %r11 # reset col dir to -1
    inc %r10 # next row dir
    jmp row_dirs
fin_row_dir:
    # restore rax and rbx
    mov %r12, %rax
    mov %r15, %rbx
    # put res in rcx and restore regs
    mov %r8, %rcx
    popq %r15
    popq %r12
    popq %r11
    popq %r10
    popq %r8
    popq %rdx

    leave
    ret

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
    popq %r10
    popq %r9
    popq %r8

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
