        .data
text1:  .asciiz "Enter first double: "
text2:  .asciiz "Enter second double: "
text3:  .asciiz "Result: "
quest:  .asciiz "\nIf you want to continue enter 1, otherwise enter 0: "
num1a:  .word       0           # sign, exponent and part of the mantissa 
num1b:  .word       0           # second part of the mantissa
num2a:  .word       0           # sign, exponent and part of the mantissa
num2b:  .word       0           # second part of the mantissa
        .text
        .globl input
main:
input:  
    #print "Enter first double: "
    la  $a0, text1
    li  $v0, 4
    syscall
    # saving input double into num1
    li  $v0, 7
    syscall                 
    swc1    $f0, num1b
    swc1    $f1, num1a
    #print "Enter second double: "
    la  $a0, text2
    li  $v0, 4
    syscall
    # saving input double into num2
    li  $v0, 7
    syscall                 
    swc1    $f0, num2b
    swc1    $f1, num2a

    # loading data to registers
    lw  $t0, num1a
    lw  $t1, num1b
    lw  $t2, num2a
    lw  $t3, num2b


sign:       
    move    $t4, $t0
    andi    $t4, $t4, 0x80000000    #preserve sign, zero the rest

    move    $t5, $t2
    andi    $t5, $t5, 0x80000000    #preserve sign, zero the rest

    bne     $t4, $t5, same
    j       extract

same:
    bne     $t0, $t2, extract
    beq     $t1, $t3, zero

extract:    
    or   $s2, $t0, $t1              #if both part of double are equal to zero we skip all the calculation
    or  $s3, $t2, $t3
    beqz    $s2, first_zero
    beqz    $s3, output

    move    $t6, $t0    
    andi    $t6, $t6, 0x7FF00000    #extracting exponent to $t6 
    move    $a0, $t6

    move    $t7, $t0
    andi    $t7, $t7, 0x000FFFFF    #extracting first part of mantissa
    ori     $t7, $t7, 0x00100000    #adding prefix one to mantissa
    #remaining mantissa stays in register $t1

    move    $t8, $t2    
    andi    $t8, $t8, 0x7FF00000    #extracting exponent to $t8
    move    $t9, $t2
    andi    $t9, $t9, 0x000FFFFF    #extracting first part of mantissa
    ori     $t9, $t9, 0x00100000    #adding prefix one to mantissa
    #remaining mantissa stays in register $t3

exp_check:
    #beq    $t6, $t8, adding
    bgt    $t6, $t8, exp1       #exponent $t8 smaller than $t6
    bgt    $t8, $t6, exp2

    bgt     $t4, $t5, sub_first
    blt     $t4, $t5, sub_second

add:

    addu   $t7, $t7, $t9        #add first parts of mantissas
    addu   $t1, $t1, $t3        #add the rest of the mantissas

    move   $s1, $t4             #move sign of the first double to $s1

    j      shift 

sub_first:
    bgt    $t9, $t7, sub_second
    bgt    $t3, $t1, sub_second

    subu   $t7, $t7, $t9        #sub first parts of mantissas
    subu   $t1, $t1, $t3        #sub the rest of the mantissas

    move   $s1, $t4

    j      shift2 

sub_second:
    subu   $t7, $t9, $t7        #sub first parts of mantissas
    subu   $t1, $t3, $t1        #sub the rest of the mantissas

    move   $s1, $t5             #move sign of the secon double to $s1

    j      shift2 

exp1:
    sll    $s4, $t9, 31         #copy lsb of m1
    sll    $s5, $t3, 31         #copy lsb of m2

    srl    $t9, $t9, 1          #shift first part of the mantissa
    srl    $t3, $t3, 1          #shift the rest of the mantissa

    or     $t9, $t9, $s4        #put lsb in m1
    or     $t3, $t3, $s5        #put lsb in m2

    addiu  $t8, $t8, 0x00100000 #increase exponent $t8

    j      exp_check
exp2:
    sll    $s4, $t7, 31         #copy lsb of m1
    sll    $s5, $t1, 31         #copy lsb of m2

    srl    $t7, $t7, 1          #shift first part of the mantissa
    srl    $t1, $t1, 1          #shift the rest of the mantissa

    or     $t7, $t7, $s4        #put lsb in m1
    or     $t1, $t1, $s5        #put lsb in m2

    addiu  $t6, $t6, 0x00100000 #increase exponent $t6

    j      exp_check

shift:

    #andi    $t8, $t7, 0x80000000
    #li    $t4, 0
    #bne    $t8, $t4, result

    andi     $t4, $t7, 0x00200000
    beqz     $t4, result

    sll    $s2, $t7, 31         #copy least significant bit of m1
    #sll    $s3, $t1, 31        #copy lsb of m2

    srl    $t7, $t7, 1          #shift right m1
    srl    $t1, $t1, 1          #shift right m2

    or     $t1, $t1, $s2        #put m1's lsb in m2 msb
    #or     $t1, $t1, $s3       #put lsb in m2

    add    $t6, $t6, 0x00100000 #increase exp
    j result

shift2:
    andi     $t4, $t7, 0x00100000
    bnez     $t4, result

    srl     $s3, $t1, 31        #copy most significant bit of m2
    #sll    $s2, $t7, 31        #copy most significant bit of m2
    #sll    $s3, $t1, 31        #copy lsb of m2

    sll    $t7, $t7, 1          #shift right m1
    sll    $t1, $t1, 1          #shift right m2

    or     $t7, $t7, $s3        #put m2's msb in m1 lsb
    #or     $t1, $t1, $s3       #put lsb in m2

    sub    $t6, $t6, 0x00100000 #increase exp

result:
    andi   $t7, $t7, 0x000FFFFF #preserve mantissa, zero the rest(cut the prefix - one)

    move   $t0, $s1             #copy propoer sign
    or     $t0, $t0, $t6        #add exponent
    or     $t0, $t0, $t7        #add mantissa part1
    b      output

first_zero:
    move  $t0, $t2
    move  $t1, $t3
    j     output

zero:
    li  $t0, 0x00000000
    li  $t1, 0x00000000

output:
    sw  $t0, num1a
    sw  $t1, num1b
    #print "Result: "
    la  $a0, text3
    li  $v0, 4
    syscall
    lwc1    $f12, num1b
    lwc1    $f13, num1a
    #print double - the result
    li  $v0, 3
    syscall
question:
    la  $a0, quest            #Do you want to enter new numbers or finish?
    li  $v0, 4
    syscall
    li  $v0, 5                #reads the answer (integer)
    syscall
    beq $v0, 1, input         #if input =1, continue, if 0 finish, otherwise ask again
    beqz    $v0, fin
    b   question
fin:
    li  $v0, 10               #exit
    syscall
.end main
