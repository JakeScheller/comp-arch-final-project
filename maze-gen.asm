# An implementation of the growing tree algorithm detailed at bit.ly/2urum5G. Essentially, the
# algorithm starts by pushing the northwest corner of the maze to the stack, and then every step
# after that, it picks a cell from the stack to use as the current cell. Normally this is the cell
# at the top of the stack, unless a random condition is met (the branchiness factor), in which case
# the algorithm chooses a random element from the stack to use as the current cell. The algorithm
# then tries to find any adjacent cells that have not yet been visited. If there are no such adjacent
# cells, the current cell is removed from the stack. Otherwise, it picks one of the unvisited adjacent
# cells and pushes it to the stack. Finally, it updates both the current and the new cell to indicate
# that the new cell has been visited and that the wall between the two cells is open. When there are
# no more items on the stack, the algorithm is finished. See the third comment in macros.asm for more
# about how the cells are structured.
generate_maze:
	pushToStack($ra)
	pushToStack($s0)
	pushToStack($s1)
	pushToStack($s2)
	pushToStack($s3)
	
	move	$s0, $sp				# stack_base = stack_pointer
	lw	$t0, northwest_ptr			#
	pushToStack($t0)				# pushToStack(northwest_ptr)
							
	gen_loop_start:					# while stack_pointer != stack_base:
		beq	$sp, $s0, gen_loop_end		#
		move	$s1, $sp			#   cur_pos_ptr = stack_pointer

		# If the random condition is met, use a random cell
		# from the stack instead of the cell at the top
		getRandByte()				#
		bge	$a0, BRANCHINESS, skip_if1	#   if randrange(0, 256) < BRANCHINESS:
		sub	$a1, $s0, $sp			#     upper_bound = stack_base - stack_pointer
		getRandRange()				#     rand_num = randrange(0, upper_bound)
		add	$s1, $sp, $a0			#     cur_pos_ptr = stack_pointer + rand_num
		andi	$s1, $s1, -4			#     cur_pos_ptr &= 0b11...1100
							#
		skip_if1:				#
		lw	$s2, ($s1)			#   cur_pos = memory[cur_pos_ptr]
		lbu	$s3, ($s2)			#   cur_cell = memory[cur_pos]

		# Get the list of unvisited cells adjacent to cur_cell					
		move	$a0, $s2			#
		move	$a1, $s3			#
		jal	get_possible_directions		#   possible_dirs = getPossibleDirections(cur_pos, cur_cell)
		
		# If there are no such adjacent cells, remove the
		# current cell from the stack, even if it is not
		# at the top
		bnez	$v0, have_possible_dirs		#   if possible_dirs == 0:
		no_possible_dirs:			#
		beq	$s1, $sp, skip_if2		#     if cur_pos_ptr != stack_ptr:
		lw	$t0, ($sp)			#
		sw	$t0, ($s1)			#       memory[cur_pos_ptr] = memory[stack_ptr]
		skip_if2:				#
		addi	$sp, $sp, 4			#     stack_pointer += 4
		j	gen_loop_start			#
		
		# If there are adjacent unvisited cells, pick one of
		# them at random and use it as the new cell
		have_possible_dirs:			#   else:
		move	$a0, $v0			#
		jal	get_random_direction		#     direction = getRandomDirection(possible_dirs)
		sll	$t0, $v0, 2			#     new_pos = cur_pos + gen_move_lookup[direction]
		lw	$t8, gen_move_lookup($t0)	#
		add	$t8, $t8, $s2			#

		# Update new_cell and cur_cell to reflect the fact that
		# new_cell has been visited and the wall between the two
		# cells is now open
		lbu	$t9, ($t8)			#     new_cell = memory[new_pos] | 0b01_00_0000
		ori	$t9, $t9, 0x40			#
							#
		beq	$v0, DIR_SOUTH, gen_case_south	#
		beq	$v0, DIR_EAST, gen_case_east	#
		beq	$v0, DIR_WEST, gen_case_west	#
		gen_case_north:				#     if direction == DIR_NORTH:
		ori	$t9, $t9, 0x20			#       new_cell |= 0b0_10_0000
		j	break_cases1			#
		gen_case_south:				#     elif direction == DIR_SOUTH:
		ori	$s3, $s3, 0x20			#       cur_cell |= 0b0_10_0000
		j	break_cases1			#
		gen_case_east:				#     elif direction == DIR_EAST:
		ori	$t9, $t9, 0x10			#       new_cell |= 0b0_01_0000
		j	break_cases1			#
		gen_case_west:				#     elif direction == DIR_WEST:
		ori	$s3, $s3, 0x10			#       cur_cell |= 0b0_01_0000
							#
		break_cases1:				#
		sb	$s3, ($s2)			#     memory[cur_pos] = cur_cell
		sb	$t9, ($t8)			#     memory[new_pos] = new_cell
							#
		pushToStack($t8)			#     pushToStack(new_pos)

		j	gen_loop_start
		gen_loop_end:
	
	# Now that the cells have information about which walls are open and which are closed,
	# we can overwrite the bytes in each cell with characters that represent walls and spaces.
	jal	finalize_maze

	popFromStack($s3)
	popFromStack($s2)
	popFromStack($s1)
	popFromStack($s0)	
	popFromStack($ra)
	jr	$ra
	

# Given a cell, return a value indicating the directions of any adjacent unvisited cells. The value
# returned is a 4-bit vector where the index of the bit corresponds to the direction (just like with
# the lower 4 bits of a cell) and a 1 bit means the adjacent cell in that direction is unvisited.
# Arguments:
#	$a0 - The address of the current cell
#	$a1 - The value of the current cell
# Returns:
#	$v0 - The bit vector, as described above
get_possible_directions:
	li	$v0, 0					# dirs = 0
	li	$t0, 0x8				# mask = 0b1000
	li	$t1, 12					# test_dir = 12
	loop3_start:					# while test_dir >= 0:
		bltz	$t1, loop3_end			#
		lw	$t2, gen_move_lookup($t1)	#   test_ptr = cur_pos + gen_move_lookup[test_dir/4]
		add	$t2, $a0, $t2			#
		lbu	$t2, ($t2)			#   test_cell = memory[test_ptr]
		srl	$t2, $t2, 6			#   test_val = (test_cell >> 6) - 1
		subi	$t2, $t2, 1			#
		and	$t2, $t2, $t0			#   dirs |= (cur_cell & mask) & test_val
		and	$t2, $t2, $a1			#
		or	$v0, $v0, $t2			#
		srl	$t0, $t0, 1			#   mask >>= 1
		subi	$t1, $t1, 4			#   test_dir -= 4
		j	loop3_start			#
	loop3_end:					# return dirs
	
	jr	$ra
	

# Given a vector of possible directions, as described in the comment above get_possible_directions,
# pick one of the directions at random and return its directional constant.
# Arguments:
#	$a0 - The bit vector representing the possible directions
# Returns:
#	$v0 - The integer constant corresponding to the chosen direction 
get_random_direction:
	mul	$t0, $a0, 0x1111			# dirs_list = possible_directions * 0x1111
	li	$a1, 4					# direction = 4
	li	$v0, 42					#
	syscall						# rand_num = randrange(0, 4)
	loop4_start:					# while True:
		andi	$t1, $t0, 1			#   rand_num -= dirs_list & 1
		sub	$a0, $a0, $t1			#
		srl	$t0, $t0, 1			#   dirs_list >>= 1
		bltz	$a0, loop4_end			#   if rand_num < 0: break
		addi	$a1, $a1, 1			#   direction += 1
		j	loop4_start			#
	loop4_end:					#
	rem	$v0, $a1, 4				# return direction % 4
	jr	$ra
	

# Use the cell values to determine where the walls and corridors are in the maze, and overwrite
# the bytes of each cell with the correct characters. Once this returns, maze_ptr points to a
# the string representation of the maze, which is ready to be printed to the screen.
finalize_maze:
	lw	$t0, northwest_ptr			# upper_row_pos = northwest_ptr
	lw	$t2, total_width_chars			# total_width_chars = total_width_chars
	add	$t1, $t0, $t2				# lower_row_pos = upper_row_pos + total_width_chars
	subi	$t3, $t1, 2				# stop_pos = lower_row_pos - 2
	addi	$t4, $t2, 2				# offset = total_width_chars + 2
	li	$t8, '#'
	li	$t9, ' '

	finalize_loop_start:				# while True:
		loop5_start:				#   while True:
		beq	$t0, $t3, loop5_end		#     if upper_row_pos == stop_pos: break
		lbu	$t5, ($t0)			#     cell = memory[upper_row_pos]
		beqz	$t5, finalize_loop_end		#     if cell == 0: break twice
		sb	$t9, 1($t0)			#     memory[upper_row_pos+1] = ' '
		sb	$t8, 0($t1)			#     memory[lower_row_pos] = '#'
		move	$t6, $t9			#     fill_char = ' '
		andi	$t7, $t5, 0x10			#     test_val = cell & 0b00_01_0000
		bnez	$t7, skip_if3			#     if test_val == 0:
		move	$t6, $t8			#       fill_char = '#'
		skip_if3:				#
		sb	$t6, 0($t0)			#     memory[upper_row_pos] = fill_char
		move	$t6, $t9			#     fill_char = ' '
		andi	$t7, $t5, 0x20			#     test_val = cell & 0b00_10_0000
		bnez	$t7, skip_if4			#     if test_val == 0:
		move	$t6, $t8			#       fill_char = '#'
		skip_if4:				#
		sb	$t6, 1($t1)			#     memory[lower_row_pos+1] = fill_char
		addi	$t0, $t0, 2			#     upper_row_pos += 2
		addi	$t1, $t1, 2			#     lower_row_pos += 2
		j	loop5_start			#
		loop5_end:				#
							#
		add	$t0, $t0, $t4			#   upper_row_pos += total_width_chars + 2
		add	$t1, $t1, $t4			#   lower_row_pos += total_width_chars + 2
		add	$t3, $t3, $t2			#   stop_pos += total_width_chars * 2
		add	$t3, $t3, $t2
		j	finalize_loop_start
	finalize_loop_end:
	
	jr	$ra
