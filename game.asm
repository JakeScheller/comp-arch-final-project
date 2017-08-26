setup_game:
	pushToStack($ra)
	
	lw	$t0, total_width_chars
	sw	$t0, gen_move_lookup+0
	neg	$t0, $t0
	sw	$t0, gen_move_lookup+12
	li	$t0, 1
	sw	$t0, gen_move_lookup+4
	neg	$t0, $t0
	sw	$t0, gen_move_lookup+8	
	
	lw	$s1, northwest_ptr
	addi	$s1, $s1, 1
	lw	$s2, southeast_ptr
	addi	$s2, $s2, 2
	li	$t0, ' '
	sb	$t0, ($s2)
	
	li	$s3, 0

	#jal	print_maze_term
	printStringl("\nWaiting to connect to screen...\n")
	printStringl("1. Open the Keyboard and Display MMIO Simulator from the Tools menu\n")
	printStringl("2. Uncheck DAD and set Delay Length to one\n")
	printStringl("3. Click the Font button and set the font to Courier New\n")
	printStringl("4. Click the Connect To MIPS button\n")
	jal	print_maze_screen
	li	$s0, 0x00100107
	outputChar($s0)
	li	$t1, '@'
	outputChar($t1)
	printStringl("Click the line below this one and begin entering moves (ijkl to move, any other key to exit).\n")
	
	popFromStack($ra)
	jr	$ra


main_game_loop:
	beq	$s1, $s2, won_game
	j	get_user_move
	
	
get_user_move:
	li	$v0, 12
	syscall
	li	$t0, 'i'
	beq	$t0, $v0, user_move_north
	li	$t0, 'k'
	beq	$t0, $v0, user_move_south
	li	$t0, 'j'
	beq	$t0, $v0, user_move_west
	li	$t0, 'l'
	beq	$t0, $v0, user_move_east
	li	$s4, 1
	li	$t0, 'I'
	beq	$t0, $v0, user_move_north
	li	$t0, 'K'
	beq	$t0, $v0, user_move_south
	li	$t0, 'J'
	beq	$t0, $v0, user_move_west
	li	$t0, 'L'
	beq	$t0, $v0, user_move_east
	li	$t0, 'q'
	beq	$t0, $v0, exit
	j	main_game_loop
	user_move_north:
	li	$a0, DIR_NORTH
	j	do_move_direction
	user_move_south:
	li	$a0, DIR_SOUTH
	j	do_move_direction
	user_move_west:
	li	$a0, DIR_WEST
	j	do_move_direction
	user_move_east:
	li	$a0, DIR_EAST
	j	do_move_direction
	
	
do_move_direction:
	move	$t0, $s1	# save the current maze position
	sll	$t1, $a0, 2	# the lookup offset
	lw	$t2, gen_move_lookup($t1)
	add	$s1, $s1, $t2	# the new maze position
	lbu	$t2, ($s1)	# the new maze char
	beq	$s4, 1, can_move_there
	beq	$t2, '#', cant_move_there
	can_move_there:
	li	$s4, 0
	outputChar($s0)		# move back to the current screen position
	li	$t2, ' '
	outputChar($t2)		# overwrite the player char with space
	lw	$t2, game_move_lookup($t1)
	add	$s0, $s0, $t2	# update to the new screen position
	outputChar($s0)		# move to the new screen position
	li	$t2, '@'
	outputChar($t2)
	addi	$s3, $s3, 1
	j	main_game_loop
	cant_move_there:
	move	$s1, $t0	# restore the current maze position
	j	main_game_loop
		

print_maze_screen:
	lw	$t0, maze_ptr
	addi	$t0, $t0, NUM_PRECEDING_NEWLINES
	li	$t1, 0x00000007
	outputChar($t1)
	loop6_start:
		lbu	$t2, ($t0)
		beq	$t2, '\0', loop6_end
		addi	$t0, $t0, 1
		beq	$t2, '\n', loop6_next_line
		outputChar($t2)
		j	loop6_start
		
		loop6_next_line:
		addi	$t1, $t1, 0x00000100
		outputChar($t1)
		j	loop6_start
	loop6_end:
	jr	$ra
	

print_maze_term:
	lw	$a0, maze_ptr
	li	$v0, 4
	syscall
	jr	$ra
	
	
won_game:
	printStringl("\nA-maze-ing! You won the game in ")
	move	$a0, $s3
	li	$v0, 1
	syscall
	printStringl(" moves!")
	j	exit