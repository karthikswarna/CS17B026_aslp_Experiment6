# MIPS program to normalize a given floating point number.

	.data
sign:	.word	0
int:	.word	0
frac:   .word	12
length:	.word	4
	.text

main:
	lw $s0, sign					# sign bit of normalized number.
	li $s1, 0					# this stores the exponent.
	lw $t0, int 					# load integer part of number.
	lw $t1, frac					# load fractional part of number.
	li $t3, 0					# loop counter
	li $t4, 0					# temp variable to check the MSB.
	li $t5, -2147483648				# constant to obtain the MSB.

# Case-1: Exponent is positive.
for:
	and $t4, $t0, $t5				# obtaining the MSB.
	bne $t4, $zero, first_1_int 			# if MSB == 1, goto first_1_int.
	sll $t0, $t0 , 1				# shifting the int part left side.
	addi $s1, $s1, 1				# incrementing the value (32 - exponent).
	addi $t3, $t3, 1				# incrementing the loop counter.
	beq $t3, 32, no_one_int				# terminating condition.
	j for

# subcase : int and frac are non-zero.
first_1_int:
	sll $t0, $t0, 1
	addi $s1, $s1, 1
	li $t3, 0					# loop counter.
	move $t6, $t1					# temporary variabe to hold fractional part.
	li $t7, 0					# temporary variabe to hold length of fractional part.
	
for_2:							# loop for calculating the length of frac part.
	and $t4, $t6, $t5				# obtaining the MSB.
	bne $t4, $zero, Exit				# if MSB == 1, goto Exit.
	sll $t6, $t6, 1					# shifting the frac part left side.
	addi $t7, $t7 ,1				# incrementing the value (32 - length).
	addi $t3, $t3, 1				# incrementing the loop counter.
	beq $t3, 32, no_one_frac			# terminating condition.
	j for_2

Exit:
	li $t5, 32
	sub $t7, $t5, $t7				# calculating the length of fractional part.
	sub $t7, $s1, $t7				# $t7 = right shift amount for int part(this makes space for frac part).
	srlv $t0, $t0, $t7				# right shifting the int part by $t7 bits.
	or $t1, $t1, $t0				# forming the mantissa of normalized number.
	sub $s1, $t5, $s1				# calculating the exponent.
	j store_values

# subcase : fractional part is zero.
no_one_frac:
	srlv $t1, $t0, $s1				# forming mantissa using int part.
	li $t5, 32
	sub $s1, $t5, $s1				# calculating the exponent.
	j store_values

# Case-2: Exponent is negative(int part is zero).
no_one_int:
	li $s1, 0					# reinitializing the exponent.
	li $t3, 0					# loop counter.
	li $t5, -2147483648
	
for_3:
	and $t4, $t1, $t5				# obtaining the MSB.
	bne $t4, $zero, first_1_frac			# if MSB == 1, goto first_1_frac.
	sll $t1, $t1, 1					# shifting the frac part left side.
	addi $s1, $s1, 1				# incrementing the value (32 - exponent).
	addi $t3, $t3, 1				# incrementing the loop counter.
	beq $t3, 32, its_zero				# terminating condition.
	j for_3

first_1_frac:
	li $t5, 32
	sll $t1, $t1, 1
	addi $s1, $s1, 1
	srlv $t1, $t1, $s1				# forming the mantissa.
	sub $s1, $t5, $s1				# length of mantissa.
	lw $t5, length					# load length of frac part.
	sub $s1, $s1, $t5				# exponent = length of frac - length of mantissa.
	j store_values

# if given number is zero.
its_zero:
	li $t1, 0
	li $s1, 0

store_values:
	sw $s1, int
	sw $t1, frac
	jr $ra
.end main
