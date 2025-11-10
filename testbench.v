`timescale 1ns/1ns

module testbench;
    // Testbench signals
    reg CLOCK_50;
    reg [3:0] KEY;
    wire [7:0] VGA_X;
    wire [6:0] VGA_Y;
    wire [23:0] VGA_COLOR;
    wire plot;
    
    // Instantiate your design
    memory dut(
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .VGA_X(VGA_X),
        .VGA_Y(VGA_Y), 
        .VGA_COLOR(VGA_COLOR),
        .plot(plot)
    );
    
    // 50 MHz clock generation (20ns period)
    initial CLOCK_50 = 0;
    always #10 CLOCK_50 = ~CLOCK_50;  // Every 10ns toggle = 20ns period
    
    // Test sequence
    initial begin
        // Initialize
        KEY = 4'b0000;  // Reset active (KEY[0]=0)
        #100;           // Wait 100ns
        
        // Release reset
        KEY = 4'b0001;  // Reset released (KEY[0]=1), KEY[1]=1 (not pressed)
        #100000;        // Wait 100,000ns (0.1ms) - see some frames
        
        // Press KEY[1] to show block
        KEY = 4'b0011;  // KEY[0]=1, KEY[1]=0 (pressed - active low)
        #400000;        // Wait 400,000ns (0.4ms) - see block for multiple frames
        
        $stop;          // End simulation
    end
endmodule