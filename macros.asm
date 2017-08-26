# The number of newlines to print before the maze, when printing to the console and not the MMIO tool
.eqv	NUM_PRECEDING_NEWLINES 4

# Any smaller than this and the maze is basically 1x1 cells
.eqv	MIN_TERM_WIDTH	6
.eqv	MIN_TERM_HEIGHT	5

# Default values for cells in the maze, before the generation algorithm runs. The maze is a grid
# of bytes, divided into 2x2 byte cells. The top left byte in each cell contains a value that
# describes the state of the cell. The lower four bytes indicate where the edges of the maze are.
# From most to least significant, the bits indicate whether the cell is against the north, west,
# east, or south edges, with a 0 representing the presence of an edge in that direction. The two
# bits above that represent in which directions the cell is 'open'. The top right byte is always
# open and the bottom left byte is always closed. If bit 5 of the cell value is 1, the top left
# byte is open, and if bit 6 is 1, the bottom right byte is open. Finally, bit 7 indicates that
# the cell has been visited by the generation algorithm, which cannot re-add visited cells to the
# stack. The algorithm starts in the northwest corner, so that corner is initialized as visited.
.eqv	INNER_CELL_INIT 0x0F # 00_00_1111
.eqv	NORTH_EDGE_INIT 0x07 # 00_00_0111
.eqv	SOUTH_EDGE_INIT 0x0E # 00_00_1110
.eqv	EAST_EDGE_INIT  0x0D # 00_00_1101
.eqv	WEST_EDGE_INIT  0x0B # 00_00_1011
.eqv	NORTHWEST_CORNER_INIT 0x43 # 01_00_0011
.eqv	NORTHEAST_CORNER_INIT 0x05 # 00_00_0101
.eqv	SOUTHWEST_CORNER_INIT 0x0A # 00_00_1010
.eqv	SOUTHEAST_CORNER_INIT 0x0C # 00_00_1100

# Directional constants
.eqv	DIR_NORTH 3
.eqv	DIR_WEST  2
.eqv	DIR_EAST  1
.eqv	DIR_SOUTH 0

# A rough mesaure of how often a corridor will branch, or how complicated the maze is. More 
# accurately, this is the probability (as a fraction of 256) that on any step of the generation
# algorithm, it will choose a random cell on the stack and continue from there instead of
# continuing from the cell at the head of the stack. When this is 0, the algorithm only branches
# when it is forced to, making it equivalent to the recursive backtracing algorithm. When this is
# 256, the algorithm chooses a random item on the stack at every step, making it equivalent to
# prim's algorithm. See bit.ly/2urum5G for more details.
.eqv	BRANCHINESS 26



.macro pushToStack(%reg)
	subi	$sp, $sp, 4
	sw	%reg, ($sp)
.end_macro

.macro popFromStack(%reg)
	lw	%reg, ($sp)
	addi	$sp, $sp, 4
.end_macro


.macro printString(%label)
	la	$a0, %label
	li	$v0, 4
	syscall
.end_macro

.macro printChar(%char)
	li	$a0, %char
	li	$v0, 11
	syscall
.end_macro

.macro readInt()
	li	$v0, 5
	syscall
.end_macro


# From the help docs on MARS macros. Takes a string literal and prints it to the screen.
.macro printStringl(%str)
	.data
string:	.asciiz %str
	.text
	printString(string)
.end_macro

# Takes a string literal and a register. Prints the string and then reads an int from the
# user, which is returned in the given register.
.macro promptInt(%prompt, %reg)
	printStringl(%prompt)
	readInt()
	move	%reg, $v0
.end_macro

# Takes a string literal. Prints it and then exits the program.
.macro exitWithErrorMsg(%msg)
	printStringl(%msg)
	j	exit
.end_macro


# Generate a random integer in the range [0, 256) and returns it in $a0.
.macro getRandByte()
	li	$v0, 41
	syscall
	andi	$a0, $a0, 0xFF
.end_macro

# Generates a random integer in the range [0, the value in $a0) and returns it in $a0.
.macro getRandRange()
	li	$v0, 42
	syscall
.end_macro

.macro outputChar(%reg)
	loop_start:
	lw	$v1, 0xffff0008
	andi	$v1, $v1, 1
	beqz	$v1, loop_start
	sw	%reg, 0xffff000c
.end_macro


.macro _debugPrintAsCoords(%reg)
	pushToStack($a0)
	pushToStack($v0)
	move	$a0, %reg
	lw	$v0, northwest_ptr
	sub	$a0, %reg, $v0
	srl	$a0, $a0, 1
	lw	$v0, total_width_chars
	div	$a0, $v0
	li	$v0, 1
	mfhi	$a0
	syscall
	printChar(',')
	printChar(' ')
	li	$v0, 1
	mflo	$a0
	syscall
	printChar('\n')
	popFromStack($v0)
	popFromStack($a0)
.end_macro

.macro _debugPrintAsBinary(%reg)
	pushToStack($a0)
	pushToStack($v0)
	move	$a0, %reg
	li	$v0, 35
	syscall
	printChar('\n')
	popFromStack($v0)
	popFromStack($a0)
.end_macro
