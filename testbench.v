`timescale 1ns/1ns
module testbench;
    reg CLOCK_50;
    reg [3:0] KEY;
    wire [7:0] VGA_X;
    wire [6:0] VGA_Y;
    wire [23:0] VGA_COLOR;
    wire plot;
    wire resetn = KEY[0];
    
    top dut(.resetn(resetn), .CLOCK_50(CLOCK_50), .VGA_X(VGA_X), 
            .VGA_Y(VGA_Y), .VGA_COLOR(VGA_COLOR), .plot(plot));
    
    initial CLOCK_50 = 0;
    always #10 CLOCK_50 = ~CLOCK_50;
    
    initial begin
        KEY = 4'b0000;  #100;
        KEY = 4'b0001;  #400000;
        $stop;
    end
endmodule