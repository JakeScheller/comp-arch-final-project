# Jake Scheller - CS 3340.0U2 Final Project

.include "macros.asm"

.data
maze_length_bytes:	.word	0
total_width_chars:	.word	0
total_height_chars:	.word	0

maze_ptr:		.word	0
northwest_ptr:		.word	0
southeast_ptr:		.word	0

gen_move_lookup:	.word	         0          2          -2           0
game_move_lookup:	.word	0x00000100 0x00100000 -0x00100000 -0x00000100



.text
main:
	jal	setup_maze
	jal	generate_maze
	jal	setup_game
				
	j	main_game_loop


.include "maze-init.asm"
.include "maze-gen.asm"
.include "game.asm"

exit:
	li	$v0, 10
	syscall
