
//reading block from memory

//In reset state, where KEY[0]=0, black screen and counters at at origin. 
//During normal operation, when KEY[0] = 1, counters scan the screen but it is still black
//When KEY[1] is pressed, the square is shown on the screen at (50,50)



module memory(CLOCK_50, KEY, VGA_X, VGA_Y, VGA_COLOR, plot); 
	input wire CLOCK_50; 

	input wire [3:0] KEY; // KEY[0] for resetn, KEY[1] to show block
	
	//screen dimension from 160*120, so 8 bits for 2^8 and 7 bits for 2^7 respectively
	output reg [7:0] VGA_X; 
	output reg [6:0] VGA_Y; 
	output wire [23:0] VGA_COLOR; //for 24 bit colour 
	output reg plot; 
	
	wire resetn = KEY[0]; //active low reset (when low (!resetn), reset is triggered) 
	wire KEY1 = KEY[1]; //press key1 to show block
	
	//X counter (columns)
	always @(posedge CLOCK_50) 
	begin 
		if(!resetn) //when reset is 0, it is triggered
			VGA_X <=0; 
		else if (VGA_X==159)
			VGA_X <=0; 
		else VGA_X<=VGA_X+1; 
	end 
	
	//X counter essentially works like a cursor across the screen in the x direction 
	//when Clockedge is positive, and reset is triggered, then, x-coordinate is 0 
										//	or if x coordinate is at the right end of the screen, 
									   // it goes back to 0 
									   // otherwise, x coordinate keeps incrementing by 1
									
								
							
	//	Y counter (rows) 
	always @(posedge CLOCK_50)
	begin 
		if(!resetn)
			VGA_Y <= 0; 
		else if(VGA_X==159)
		begin 
			if(VGA_Y==119) VGA_Y<=0; //end of the frame, where y coordinate is reset to 0 
			else VGA_Y <=VGA_Y+1; //otherwise, y coordinate keeps incrementing by 1 
		end
	end
	
	//plot, write enable signal 
	always@(posedge CLOCK_50)
	begin 
		plot<=1'b1; 
	end 
	
	
	//Block memory - 16x16 
	reg [8:0] block [0:255];
	//16*16=256 pixels total, where each needs 9 bits for colour
	
	//initializing memory with the block mif 
	initial 
	begin 
		$readmemh("C:/Users/niran/Downloads/Stack5/memory/block.mif", block);
	end 
	
	//calculate address into block memory 
	reg [7:0] memAddress; 
	wire inBlock; 
	assign inBlock=(VGA_X>=50&&VGA_X<66)&&(VGA_Y>=50&&VGA_Y<66); 
	
	//calculating address of pixels; are they within the 16x16 block? 
	always@(*) 
	begin 
		if(inBlock) memAddress = (VGA_Y-50)*16+(VGA_X-50); 
		//converting the 2D coordinates into 1D memory addresses 
		//multiply the row by 16 (since each row has 16 pixels), then add column to yield linear address 
		else memAddress = 0; 
	end 
	
	//reading from memory 
	reg [8:0] blockColour; 
	always @(posedge CLOCK_50) 
	begin 
		blockColour<=block[memAddress]; 
	end 
	
	//show block if KEY1 is pressed and within block area, else show black background
	reg showBlock; 
	always@(posedge CLOCK_50) 
	begin
		if(!resetn) showBlock<=0; 
		else if (~KEY1) //active low; KEY 1 is presssed 
			showBlock<=1; 
	end 
	
	
	
	    // Convert 9-bit to 24-bit color
    wire [23:0] color_24bit = {
        {8{blockColour[8]}}, // Red
        {8{blockColour[5]}}, // Green
        {8{blockColour[2]}}  // Blue
    };
    
    assign VGA_COLOR = (showBlock && inBlock) ? color_24bit : 24'h000000; 
	
endmodule 