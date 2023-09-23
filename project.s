.data
.globl cFlag
.globl cData

.align 2
cFlag: .word 0
.align 0
cData: .space 1

.align 2
W: .word 24
.align 2
H: .word 16
.align 2
startX: .word 24
.align 2
endX: .word  361
.align 2
totalElements: .word 384

.align 0
temp: .space 100
.align 2
helper: .space 48           #W*H/8
.align 2
map: .space 48
#map: .asciiz "I.IIIIIIIIIIIIIIIIIIII....I....I.......I.IIII.IIIII.I.I.III.I.II.I.....I..I..I.....II.I.III.II...II.I.IIII...I...III.I...I...IIIIII.IIIII.III.III.II.............I.I...IIIIIIIIIIIIIIII.I.III@...............I..IIIIIIIIIIIIIIIIIIIIIII"
winnertext: .asciiz "\nWinner winner chicken dinner!"
labyrinthtext: .asciiz "\nLabyrinth:\n"
newline: .asciiz "\n"
.text
.globl main
main:
###Interupts enabled for keyboard and processor
mfc0 $t0, $12
li $t1, 0x801 
or $t0, $t0, $t1
mtc0 $t0, $12 #giving value 1 to 1st and 11th bit of register 12 of the coprocessor
li $t0, 2
la $t1, 0xffff0000
sb $t0, 0($t1) #enabling keyboard interupts (value of second bit of 0xffff0000 is 1)
##########
#store variables in s regs
lw $s0, W
lw $s1, H
lw $s2, startX
lw $s3, totalElements
#s4 playerPos
la $s5, map
la $s6, temp
#initialize binary labyrinth
la $t1, map
li $t2, 0x04FFFFFF
sw $t2, 0($t1)
li $t2, 0xABEF2120
sw $t2, 4($t1)
li $t2, 0x0D90A0ED
sw $t2, 8($t1)
li $t2, 0x88BDC6AE
sw $t2, 12($t1)
li $t2, 0xEEFB8DE8
sw $t2, 16($t1)
li $t2, 0x8D0280ED
sw $t2, 20($t1)
li $t2, 0x80B1FEFF
sw $t2, 24($t1)
li $t2, 0xDFFA9500
sw $t2, 28($t1)
li $t2, 0x8576B3B5
sw $t2, 32($t1)
li $t2, 0xAD2D028C
sw $t2, 36($t1)
li $t2, 0x88A1FDBB
sw $t2, 40($t1)
li $t2, 0xFFFFBF01
sw $t2, 44($t1)


#initialize playerPos
move $s4, $s2
#mainloop
mainlooplabel:
#print labyrinth
jal printLabyrinth

#read char and move it in t1
###############################################################standalone polling starts

# addi    $s0, $0, 0                      #Here is given
# lui     $s0, 0xffff                     #value: 0xffff at s0
#  key_wait:
#	    lw      $t0, 0($s0)
#	    andi    $t0, $t0, 0x1  # Isolate ready bit
#	    beqz    $t0, key_wait
#	    # Read value
#	   lw      $t1, 4($s0)   
#lw $s0, W #s0 takes the value of W again(s0 used in polling)	   
###############################################################standalone polling ends
###############################################################polling 
theFinalLoop:           
###check if given value, if not loop
lb $t6, cFlag
beqz $t6, theFinalLoop
###t1=t7(cValue)
lw $t1, cData
sb $zero, cFlag
###############################################################polling_ends
#switch choice
#if w
li $t2, 119
bne $t1, $t2, ifs
#check if valid move up
	#playerPos-W>=0
sub $t1, $s4, $s0
blt $t1, $0, endofswitch
	#map[playerPos-W]!='I'
move $a0, $t1
move $a1, $s5
jal readChar 
li $t3, 1
beq $v0, $t3, endofswitch
#move up
sub $s4, $s4, $s0
j endofswitch
#if s
ifs:
li $t2, 115
bne $t1, $t2, ifa
#check if valid move down
	#playerPos+W<totalElements
add $t1, $s4, $s0
bge $t1, $s3, endofswitch
	#map[playerPos+W]!='I'
move $a0, $t1
move $a1, $s5
jal readChar 
li $t3, 1
beq $v0, $t3, endofswitch
#move down
add $s4, $s4, $s0
j endofswitch
#if a
ifa:
li $t2, 97
bne $t1, $t2, ifd
#check if valid move left
	#playerPos%W>0
div $s4, $s0
mfhi $t1
blez $t1, endofswitch
	#map[playerPos-1]!='I'
addi $a0, $s4, -1
move $a1, $s5
jal readChar 
li $t3, 1
beq $v0, $t3, endofswitch
#move left
addi $s4, $s4, -1
j endofswitch
#if d
ifd:
li $t2, 100
bne $t1, $t2, ife
#check if valid move right
	#playerPos%W<W-1
div $s4, $s0
mfhi $t1
addi $t2, $s0, -1
sub $t1, $t1, $t2
bgez $t1, endofswitch
	#map[playerPos+1]!='I'
addi $a0, $s4, 1
move $a1, $s5
jal readChar
li $t3, 1
beq $v0, $t3, endofswitch
#move right
addi $s4, $s4, 1
j endofswitch
#if e
ife:
li $t2, 101
bne $t1, $t2, endofswitch
#makeMove(startX)
move $a0, $s2
jal makeMove
#prints best path
jal printLabyrinth
#end program
j exitlabel
endofswitch:
#if reached the @
#map[playerPos]=='@'
lw $t1, endX
bne $s4, $t1, mainlooplabel
#print "Winner..."
li $v0, 4
la $a0, winnertext
syscall
#terminate
exitlabel:
li $v0, 10
syscall



printLabyrinth:
#initialize i,j,k
li $t1, 0 #i
li $t2, 0 #j
li $t3, 0 #k
move $t4, $ra
jal delay
move $ra, $t4
#print "Labyrinth\n"
li $v0, 4
la $a0, labyrinthtext
syscall
#i loop
forloopi:
bge $t1, $s1, afterloopi
	#j loop
	forloopj:
	bge $t2, $s0, afterloopj
		#if k == playerPos
		bne $t3, $s4, elselabel
		#temp[j]='P'
		li $t4, 80
		add $t5, $t2, $s6
		sb $t4, 0($t5)
		#else
		j afteriflabel
		elselabel:
		#$t4=map[k]
		move $a0, $t3 
		move $a1, $s5
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal readChar
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		move $t4, $v0 
		#$t5=helper[k]
		move $a0, $t3 
		la $t5, helper
		move $a1, $t5 
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal readChar
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		move $t5, $v0 
		#decide value of t4
		bne $t4, $0, tfourisone
		bne $t5,$0,tfiveisone
		li $t4, 48
		j finishedwithtfourfive
		tfiveisone:
		li $t4, 42
		j finishedwithtfourfive
		tfourisone:
		bne $t5, $0, tfiveisagainone
		li $t4, 49
		j finishedwithtfourfive
		tfiveisagainone:
		li $t4, 35	
		finishedwithtfourfive:
		#temp[j]=$t4
		add $t5, $t2, $s6
		sb $t4, 0($t5)
		afteriflabel:
		#k++
		addi $t3, $t3, 1
		#j++
		addi $t2, $t2, 1
	j forloopj
	afterloopj:
	#temp[j+1]=null
	addi $t4, $t2, 1
	add $t5, $t4, $s6
	sb $0, 0($t5)
	#print temp
	li $v0, 4
	move $a0, $s6
	syscall
	#print '\n'
	la $a0, newline
	syscall
	#initialize j for next loop
	li $t2, 0
	#i++
	addi $t1, $t1, 1
j forloopi
afterloopi:
#return
jr $ra


delay:
#li $t7, 100000
#loopdelay:
#addi $t7, $t7, -1
#bgtz $t7, loopdelay
jr $ra

makeMove:
#store index in s7
move $s7, $a0
#index<0
bgez $s7, afterfirstcondition
li $v0, 0
j return
afterfirstcondition:
#index>=totalElements
bgt $s3, $s7, afterifone 
li $v0, 0
j return
afterifone:
#if2
move $a0, $s7
move $a1, $s5
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal readChar
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
move $t1, $v0
move $a0, $s7 
la $a1, helper
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal readChar
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
move $t2, $v0 
or $t3, $t1, $t2 #if t1=0&&t2=0
bne $t3, $0, afteriftwo

lw $t3, endX
bne $s7, $t3, afterifseven
move $a0, $s7
li $a1,1
move $a2, $s5
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal storeChar
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
move $a0, $s7
li $a1, 1
la $a2, helper 
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal storeChar
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal printLabyrinth
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
li $v0, 1
j return
afterifseven:



#store in helper[index] 1
move $a0, $s7 
li $a1, 1
la $a2, helper
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal storeChar
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal printLabyrinth
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
#if3
addi $a0, $s7, 1
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal makeMove
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
li $t1, 1
bne $v0, $t1, afterifthree
move $a0, $s7
li $a1,1
move $a2, $s5
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal storeChar
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
li $v0, 1
j return
afterifthree:
add $a0, $s7, $s0
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal makeMove
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
li $t1, 1
bne $v0, $t1, afteriffour
move $a0, $s7
li $a1,1
move $a2, $s5
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal storeChar
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
li $v0, 1
j return
afteriffour:
addi $a0, $s7, -1
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal makeMove
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
li $t1, 1
bne $v0, $t1, afteriffive
move $a0, $s7
li $a1,1
move $a2, $s5
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal storeChar
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
li $v0, 1
j return
afteriffive:
sub $a0, $s7, $s0 
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal makeMove
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
li $t2, 1
bne $v0, $t2, afterifsix
move $a0, $s7
li $a1,1
move $a2, $s5
addi $sp, $sp, -8
sw $ra, 0($sp)
sw $s7, 4($sp)
jal storeChar
lw $s7, 4($sp)
lw $ra, 0($sp)
addi $sp, $sp, 8
li $v0, 1
j return
afterifsix:
li $v0, 0
j return

afteriftwo:

li $v0, 0

return:
jr $ra



readChar:
#a0 index
#a1 address to begin (map or helper)
addi $sp, $sp, -12
sw $t1, 0($sp)
sw $t2, 4($sp)
sw $t3, 8($sp)
li $t1, 8
div $a0, $t1
mflo $t1 #a = index div 8
mfhi $t2 #b = index mod 8
add $t3, $a1, $t1
lb $t1, 0($t3)
li $t3, 128 #10000000
srlv $t3, $t3, $t2
and $t2, $t1, $t3
bgt $t2,$0,returnone
li $v0, 0
j afterreturn
returnone:
li $v0, 1
afterreturn:
lw $t1, 0($sp)
lw $t2, 4($sp)
lw $t3, 8($sp)
addi $sp, $sp, 12
j $ra



storeChar:
#a0 index
#a1 0 or 1
#a2 address of map or helper
addi $sp, $sp, -16
sw $t1, 0($sp)
sw $t2, 4($sp)
sw $t3, 8($sp)
sw $t4, 12($sp)

li $t1, 8
div $a0, $t1
mflo $t1 #a = index div 8
mfhi $t2 #b = index mod 8
add $t3, $a2, $t1
lb $t1, 0($t3)
li $t4, 7
sub $t2, $t4, $t2
blez $a1, storeelse
sllv $a1, $a1, $t2
or $t1, $t1,$a1
j afterstoreif
storeelse:
li $a1, 1
sllv $a1, $a1, $t2
li $t4, 0xFF
sub $a1, $t4, $a1
and $t1, $t1, $a1
afterstoreif:
sb $t1, 0($t3)
lw $t1, 0($sp)
lw $t2, 4($sp)
lw $t3, 8($sp)
lw $t4, 12($sp)
addi $sp, $sp, 16
j $ra



































