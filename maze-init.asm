# Get the size of the maze, allocate the necessary space, and initialize the space to the correct
# starting values. After this function returns, the maze is ready for the generation step.
setup_maze:
	pushToStack($ra)
	jal	get_maze_size
	move	$a0, $v0		# maze_length_bytes argument for init_maze_data
	move	$a1, $v1		# total_width_chars argument for init_maze_data
	
	sll	$t0, $a1, 1
	sw	$t0, gen_move_lookup	# gen_move_lookup[0] = total_width_chars * 2
	neg	$t0, $t0
	sw	$t0, gen_move_lookup+12	# gen_move_lookup[3] = total_width_chars * -2
	
	# Allocate memory for the maze. The number of bytes is already in $a0
	li	$v0, 9
	syscall
	
	sw	$v0, maze_ptr		# maze_ptr = the address of the allocated block of memory
	addi	$a2, $v0, NUM_PRECEDING_NEWLINES
	add	$a2, $a2, $a1
	add	$a3, $v0, $a0
	sub	$a3, $a3, $a1
	addi	$a3, $a3, -5
	sw	$a2, northwest_ptr	# northwest_ptr = maze_ptr + NUM_PRECEDING_NEWLINES + total_width_chars
	sw	$a3, southeast_ptr	# southeast_ptr = maze_ptr + maze_length_bytes - total_width_chars - 5
	
	jal	init_maze_data
	
	popFromStack($ra)
	jr	$ra
	

# Prompt the user for the width and height of their terminal and then calculate and store the
# maximum width and height of the maze to fit into the terminal, as well as the total length of
# the maze in bytes.
# Returns:
#	$v0 - The total number of bytes that need to be allocated for the maze
#	$v1 - The total width in chars of one row of the maze, including the newline
get_maze_size:
	printStringl("95 by 13 is a reasonable terminal size.\n")
	promptInt("What is the width of your terminal? ", $t0)
	promptInt("What is the height of your terminal? ", $t1)
	
	bge	$t0, MIN_TERM_WIDTH,  else1
	bge	$t1, MIN_TERM_HEIGHT, else1
	exitWithErrorMsg("(!) Your terminal is too small")

	else1:
	addi	$v1, $t0,  1	# total_width_chars = (term_width % 2) ? term_width+1 : term_width
	andi	$v1, $v1, -2
	addi	$t1, $t1, -1	# total_height_chars = (term_height % 2) ? term_height : term_height-1
	ori	$t1, $t1,  1
	
	mul	$v0, $v1, $t1			 # maze_length_bytes = total_width_chars * total_height_chars
	addi	$v0, $v0, NUM_PRECEDING_NEWLINES # maze_length_bytes += NUM_PRECEDING_NEWLINES
	addi	$v0, $v0, 1			 # maze_length_bytes += 1  # For the null terminator
	
	sw	$v0, maze_length_bytes
	sw	$v1, total_width_chars
	sw	$t1, total_height_chars
	
	jr	$ra
	

# Initialize the characters in the maze to their default values based on the given dimensions.
# Arguments:
#	$a0 - the length of the maze in bytes
#	$a1 - the total width of one row of the maze in chars
#	$a2 - the address of the maze's northwest cell
#	$a3 - the address of the maze's southeast cell
init_maze_data:
	lw	$t0, maze_ptr			# pos1 = maze_ptr (i.e. the address of the allocated memory)
	sub	$t3, $a2, $a1			# pos2 = maze_ptr + NUM_PRECEDING_NEWLINES
	add	$t4, $a3, $a1			# stop_pos = maze_ptr + maze_length_bytes - 1
	addi	$t4, $t4, 4
	li	$t5, '\n'
	li	$t6, '#'
	li	$t7, INNER_CELL_INIT
	li	$t8, WEST_EDGE_INIT
	li	$t9, EAST_EDGE_INIT
	
	# Fill the null terminator
	sb	$0, ($t4)
	
	# Fill the preceding newlines,
	# then fill the rest of the cells with a default value,
	# then fill the west and east edge cells, the east border, and each row's newline.
	loop1_start:				# while pos1 < pos2:
		beq	$t0, $t3, loop1_phase2	#
		sb	$t5, ($t0)		#   memory[pos1] = '\n'
		addi	$t0, $t0, 1		#   pos1 += 1
		j	loop1_start		#
	loop1_phase2:				# while pos1 < stop_pos:
		beq	$t0, $t4, loop1_phase3	#
		sb	$t7, ($t0)		#   memory[pos1] = INNER_CELL_INIT
		addi	$t0, $t0, 2		#   pos1 += 2
		j	loop1_phase2		#
	loop1_phase3:				# while pos2 < stop_pos:
		beq	$t3, $t4, loop1_end	#
		sb	$t8, ($t3)		#   memory[pos2] = WEST_EDGE_INIT
		add	$t3, $t3, $a1		#   pos2 += total_width_chars
		sb	$t9, -4($t3)		#   memory[pos2-4] = EAST_EDGE_INIT
		sb	$t6, -2($t3)		#   memory[pos2-2] = '#'
		sb	$t5, -1($t3)		#   memory[pos2-1] = '\n'
		j	loop1_phase3
	loop1_end:
	
	sub	$t0, $a2, $a1			# top_pos = maze_ptr + NUM_PRECEDING_NEWLINES
	move	$t1, $a2			# north_pos = maze_ptr + northwest_idx
	move	$t2, $a3			# south_pos = maze_ptr + southeast_idx
	addi	$t3, $t1, -2			# stop_pos = north_pos - 2
	li	$t8, NORTH_EDGE_INIT
	li	$t9, SOUTH_EDGE_INIT
	
	# Fill the north and south edge cells, and the top border
	loop2_start:				# while top_pos < stop_pos:
		beq	$t0, $t3, loop2_end	#
		sb	$t6, 0($t0)		#   memory[top_pos] = '#'
		sb	$t6, 1($t0)		#   memory[top_pos+1] = '#'
		sb	$t8, 0($t1)		#   memory[north_pos] = NORTH_EDGE_INIT
		sb	$t9, 0($t2)		#   memory[south_pos] = SOUTH_EDGE_INIT
		addi	$t0, $t0,  2		#   top_pos += 2
		addi	$t1, $t1,  2		#   north_pos += 2
		addi	$t2, $t2, -2		#   south_pos -= 2
		j	loop2_start
	loop2_end:

	li	$t6, NORTHWEST_CORNER_INIT
	li	$t7, NORTHEAST_CORNER_INIT
	li	$t8, SOUTHWEST_CORNER_INIT
	li	$t9, SOUTHEAST_CORNER_INIT
	
	# Fill the cells in each corner
	sb	$t6, ($a2)			# memory[northwest_pos] = NORTHWEST_CORNER_INIT
	add	$a2, $a2, $a1			# northeast_pos = northwest_pos + total_width_chars - 4
	addi	$a2, $a2, -4			#
	sb	$t7, ($a2)			# memory[northeast_pos] = NORTHEAST_CORNER_INIT
	sb	$t9, ($a3)			# memory[southeast_pos] = SOUTHEAST_CORNER_INIT
	sub	$a3, $a3, $a1			# southwest_pos = southwest_pos - total_width_chars + 4
	addi	$a3, $a3, 4			#
	sb	$t8, ($a3)			# memory[southwest_pos] = SOUTHWEST_CORNER_INIT
	
	jr	$ra
