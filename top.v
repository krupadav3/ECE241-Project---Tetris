
//Displaying a static tetromino block on the screen with counters. 

//turn off any implicit wires 
`default_nettype none 

module top(resetn, CLOCK_50, VGA_X, VGA_Y, VGA_COLOR, plot); 
	input wire resetn; 
	input wire CLOCK_50; 
	//screen dimension from 160*120, so 8 bits for 2^8 and 7 bits for 2^7 respectively
	output reg [7:0] VGA_X; 
	output reg [6:0] VGA_Y; 
	output reg [23:0] VGA_COLOR; //for 24 bit colour 
	output reg plot; 
	
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
					
					
	//write enable must always be drawing when clockedge is positive 
	always @(posedge CLOCK_50)
	begin 
		plot<=1'b1; //0 when blanking
	end 
	
	
	
	wire inBlock; //within bounds of the block, red colour is allowed 
	assign inBlock = (VGA_X>=50&&VGA_X<66) && (VGA_Y>=50&&VGA_Y<66); 
	
	always @(*)
	begin 
		if(inBlock)
			VGA_COLOR=24'b11111111_00000000_00000000; 
		else
			VGA_COLOR = 24'b00000000_00000000_00000000;
		end
						  
endmodule

`default_nettype wire //restore default wire behaviour 