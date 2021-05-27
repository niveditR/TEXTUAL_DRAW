. DRAW
. enter a command (or more commands) to stdin and press enter to draw
. commands:
. - h : displays help on stdout
. - w, a, s, d : up, left, down, right
. - f : changes drawing symbol to next typed character
. - c : clears the screen and returns to center
. - p : fills the screen with drawing symbol
. - q : halt
.
. examples:    'aaaa wwww dddd ssss' -> draws a 4x4 square
.              'f.' -> changes drawing symbol to '.'
.              'f-dddf df-dddf df-ddd' -> draws a dashed line '--- --- ---'
.
draw START 0 
reset LDA screen_columns            . calculate center:  X = (screen_columns/2) * screen_rows  
	DIV #2
	MUL screen_rows
	RMO A, X                   . set X to center coordinate
	J help                     . display help (comment this line to skip it)
	J print_cursor                         
	
input RD #0
	COMP #10                   
	JEQ input                  . newline, ignore
	COMP #113
	JEQ halt                   . q, halt 
	COMP #102
	JEQ switch_symbol                 . f, change drawing symbol
	COMP #99
	JEQ clear_screen                  . c, clear_screen screen
	COMP #112
	JEQ fill_screen                   . p, fill_screen screen
	COMP #104
	JEQ help                   . h, help
	COMP #119
	JEQ move_up                     . w a s d za premikanje kurzorja
	COMP #97
	JEQ move_left
	COMP #115
	JEQ move_down
	COMP #100
	JEQ move_right
	J input
	
	                          . switch the drawing symbol 
switch_symbol RD #0                
	COMP #10                    
	JEQ switch_symbol                . newline is ignored, read another character
	STA symbol
	J input                  
	
	                          . clear_screen screen - call screen_clear
clear_screen JSUB screen_clear    
	J reset
	

	
print_cursor LDA mouse_cursor         . print mouse_cursor to coordinate in X
	+STCH screen, X
	J input


	                          . fill_screen screen - load symbol and call screen_fill
fill_screen LDA symbol
	JSUB screen_fill
	J reset

screen_clear STA temporary_A           . save A to temporary_A, set it to space and call write_last_A
	LDA #32 
	J write_last_A
	
screen_fill STA temporary_A            . save A to temporary_A and call write_last_A
	J write_last_A
	

	
	                          . move down - almost the same as up
move_down LDA symbol             
	+STCH screen, X           . draw symbol to X, move X down one row
	LDA screen_columns
	ADDR A, X                 
	LDA screen_length
	COMPR X, A
	JGT substract_length              . if X is too far down, move it to top of screen
	J print_cursor                
substract_length LDA screen_length         . subtract screen_length (move X from bottom to top)
	SUBR A, X
	J print_cursor       


	                          . move up
move_up LDA symbol
	+STCH screen, X           . print symbol on current X (location of mouse_cursor) 
	LDA screen_columns               . move X up (X = X - screen_columns)
	SUBR A, X
	LDA #0                    
	COMPR X, A                . if X is too far up, move it to bottom of the screen 
	JLT add_length               
	J print_cursor                
add_length LDA screen_length          . moves X from above the screen to bottom (adds screen_length)
	ADDR A, X
	J print_cursor                . add screen_length (move X from top to bottom)         
	
	                          

	
	                          . move right - almost the same as up
move_right LDA symbol
	+STCH screen, X           . draw symbol, move X to right, check if we went too far
	RMO X, A
	DIV screen_columns
	STA current_row
	LDA #1
	ADDR A, X
	RMO X, A
	DIV screen_columns
	JGT substract_screen_columns              . if calculated row is too high, move X one row up
	J print_cursor
substract_screen_columns LDA screen_columns        . subtract screen_columns (move X one up)
	SUBR A, X
	J print_cursor




				. move left
move_left LDA symbol             
	+STCH screen, X           . draw symbol to X
	RMO X, A
	DIV screen_columns               . calculate current row ( X / screen_columns)
	STA current_row
	LDA #1
	SUBR A, X                 . move X one to left
	RMO X, A                  . if X moved too far left, it will be one row higher on the right side
	DIV screen_columns               
	COMP current_row               . X / screen_columns gives us the row X is on
	JLT add_screen_columns               . if calculated row is lower than current_row, move one down 
	J print_cursor
add_screen_columns LDA screen_columns         . add screen_columns (move X one down)
	ADDR A, X
	J print_cursor



help STX temporary_X               . print help to stdout
	LDX #0
	LDA #help_length              .calculate length of help text
	SUB #help_text
	SUB #2
	STA help_length
help_write LDA help_text, X        . read from help_text, write to stdout
	WD #1
	TIX help_length               . increment X and compare it to help length
	JEQ restore_X               
	J help_write    
restore_X LDX temporary_X . restore X, set A to 0 and go to input
	LDA #0
	J print_cursor                . draw mouse_cursor on the screen and wait for new input 
	

	
write_last_A  STX temporary_X            . write last bit of A to whole screen
	LDX #0 
loop +STCH screen, X
	TIX screen_length
	JEQ return
	J loop
return LDX temporary_X             . reload A and X from temporary_A and temporary_X
	LDA temporary_A
	RSUB               
	
halt J halt
	
symbol WORD 42        . drawing symbol
mouse_cursor WORD 43        . mouse_cursor symbol
current_row WORD 12        . current row
temporary_A RESW 1
temporary_X RESW 1
screen_rows WORD 25       . screen rows    
screen_columns WORD 80       . screen columns - should be the same as settings in simulator
screen_length WORD 2000

	                    . help text
help_text BYTE C'  ---DRAW---'    
	BYTE 10
	BYTE C'Type a command (or more commands) to standard input and press enter to execute them.'
	BYTE 10
	BYTE C'List of Commands:'
	BYTE 10
	BYTE C'- h: displays help on stdout'
	BYTE 10
	BYTE C'- w,a,s,d: up, left, down, right'
	BYTE 10
	BYTE C'- f: changes drawing symbol to next typed character'
	BYTE 10
	BYTE C'- c: clears the screen and returns to center'
	BYTE 10
	BYTE C'- p: fills the screen with drawing symbol'
	BYTE 10
	BYTE C'- q: halt'   
	BYTE 10
help_length RESW 1         
	
	ORG 47104           . screen address in memory
screen RESB 1