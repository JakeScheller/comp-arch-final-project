# Computer Architecture final project
This is a simple maze game I wrote as my final project for my Computer Architecture class. It generates a maze using a variant of the recursive backtracking algorithm, then lets the user solve it interactively. I wrote it using the [MARS MIPS emulator](http://courses.missouristate.edu/KenVollmar/mars/), which exposes some not-exactly-realistic syscalls and features that make this program incompatible with other MIPS emulators.
## Generation algorithm
The algorithm is based on the one from [this useful blog post](http://weblog.jamisbuck.org/2011/1/27/maze-generation-growing-tree-algorithm) by a blogger named Jamis Buck. It's a neat twist on the recursive backtracking algorithm where on every step there is some chance that the maze will, instead of continuing from the head of the stack, continue from a random element on the stack. This means that there are fewer of the long, winding paths created by the drunkard's walk of recursive backtracking. The neat thing is that you can tune the chance of continuing from a random element to choose roughly how often the maze branches. I call this chance the "branchiness factor."

The algorithm I wrote doesn't match the algorithm from the blog post exactly, but I'm very happy with how the mazes end up turning out.
## Interactive solving
Once the program has generated the maze, it lets the user solve it interactively. MARS has a "Keyboard and Display MMIO Simulator" which lets a program print characters to specific coordinates on the screen, just like a terminal. The program takes input from the prompt and moves the player character within the maze. When the player reaches the end, the program prints how many steps it took for him/her to finish the maze. You can cheat by holding shift while moving to walk through walls, if you're so inclined.
## Visualization
I also wrote a javascript program to help me wrap my head around how the algorithm works and to choose the branchiness factor that made the maze most fun to play. The program has two phases. In the first phase, the maze is generated. White squares are on the stack, whereas green squares have been removed from the stack and are now closed. Once the whole maze is green, the generation is complete, at which point the maze turns white and the second phase begins (after you press space). In the second phase, the maze is filled with color, such that for every square with the same color, it takes the same number of steps to get from that square back to the starting position. This phase is great for visualizing the internal structure of the maze, and it is what I based my decision on for which branchiness factors to choose. Flooding the maze with color makes the difference very apparent between, for example, branchiness factors 0, 10, and 100.

An interesting thing to note is that the human eye is better at seeing differences in blue, purple, and red hues than in green and yellow hues. Because of this, it looks like the maze has a large area where most of the squares are about the same distance from the starting position, namely those squares that have been filled with green and yellow hues. This is an illusion. If you change the start_hue variable in the code so that the green starts near the beginning or end of the maze, (try 90 or 180), or anywhere in between, that respective area ends up with the same homogeneous appearance. I spent a while looking into perceptually uniform color spaces like CIELAB to try and mitigate this, but I eventually decided I'd be better off spending my time getting started writing MIPS code ;)
### Visualization instructions:
* The maze generation starts automatically.
* Press space to pause. Press space again to play.
* While paused, press '.' (period) to advance one frame.
* While playing, press the left and right arrow keys to change the speed.
* While playing, press the up arrow key to engage TurboBoost®
* Press enter to immediately complete the maze.
* Once the maze has finished generating, it will turn white.
* At that time, press space or enter to begin flooding it with color.
* The same controls apply to the color flooding as to the maze generation.

## Thanks for taking a look at my code!
Feel free to mess around with the 'user defined variables' at the top of the visualization program or in the macros.asm file.
