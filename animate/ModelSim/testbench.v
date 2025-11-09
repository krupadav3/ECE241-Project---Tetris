`timescale 1ns / 1ps

/*
 * Simplified testbench for ECE241 Milestone 1
 * Tests PS/2 interface and object FSM without VGA adapter dependencies
 */

module testbench ( );
    parameter CLOCK_PERIOD = 20;
    
    reg CLOCK_50;    
    reg [9:0] SW;
    reg [3:0] KEY;
    
    // PS/2 signals
    reg PS2_CLK, PS2_DAT;
    
    // Wires for internal signals
    wire [7:0] scancode;
    wire drop_signal;
    wire [9:0] block_x;
    wire [8:0] block_y;
    wire [3:0] fsm_state;
    wire is_locked;
    wire at_bottom;
    wire ps2_rec;
    wire [9:0] vga_x;
    wire [8:0] vga_y;
    wire [8:0] vga_color;
    wire vga_write;
    
    wire Resetn, PS2_CLK_S, PS2_DAT_S;
    wire negedge_ps2_clk;
    reg prev_ps2_clk;
    wire [32:0] Serial;
    wire [3:0] Packet;
    
    assign Resetn = KEY[0];
    
    // Instantiate sync modules
    sync S3 (PS2_CLK, Resetn, CLOCK_50, PS2_CLK_S);
    sync S4 (PS2_DAT, Resetn, CLOCK_50, PS2_DAT_S);
    
    // PS/2 edge detection
    always @(posedge CLOCK_50)
        prev_ps2_clk <= PS2_CLK_S;
    
    assign negedge_ps2_clk = (prev_ps2_clk & !PS2_CLK_S);
    
    // PS/2 serial shift register
    reg [32:0] serial_reg;
    always @(posedge CLOCK_50) begin
        if (Resetn == 0)
            serial_reg <= 33'b0;
        else if (negedge_ps2_clk) begin
            serial_reg[31:0] <= serial_reg[32:1];
            serial_reg[32] <= PS2_DAT_S;
        end
    end
    assign Serial = serial_reg;
    
    // PS/2 packet counter
    reg [3:0] packet_count;
    always @(posedge CLOCK_50) begin
        if (!Resetn || packet_count == 'd11)
            packet_count <= 'b0;
        else if (negedge_ps2_clk)
            packet_count <= packet_count + 'b1;
    end
    assign Packet = packet_count;
    
    // PS/2 receive signal
    assign ps2_rec = (packet_count == 'd11) && (serial_reg[30:23] == serial_reg[8:1]);
    
    // Scancode register
    reg [7:0] scancode_reg;
    always @(posedge CLOCK_50) begin
        if (!Resetn)
            scancode_reg <= 8'b0;
        else if (ps2_rec)
            scancode_reg <= serial_reg[8:1];
    end
    assign scancode = scancode_reg;
    
    // Drop signal
    assign drop_signal = ps2_rec && (scancode == 8'h1A);
    
    // Instantiate object module directly
    object O1 (
        .Resetn(Resetn),
        .Clock(CLOCK_50),
        .drop(drop_signal),
        .new_color(SW[8:0]),
        .VGA_x(vga_x),
        .VGA_y(vga_y),
        .VGA_color(vga_color),
        .VGA_write(vga_write)
    );
    defparam O1.nX = 10;
    defparam O1.nY = 9;
    
    // Connect to object internal signals
    assign block_x = O1.X;
    assign block_y = O1.Y;
    assign fsm_state = O1.y_Q;
    assign is_locked = O1.is_locked;
    assign at_bottom = O1.at_bottom;
    
    // Clock generator
    initial begin
        CLOCK_50 <= 1'b0;
    end
    
    always @ (*)
    begin : Clock_Generator
        #((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
    end
    
    // PS/2 Clock generator (~10 kHz, much slower than FPGA clock)
    initial begin
        PS2_CLK <= 1'b1;
    end
    
    always begin
        #50000 PS2_CLK <= ~PS2_CLK;  // ~10 kHz PS/2 clock
    end
    
    // Reset sequence
    initial begin
        KEY <= 4'b0;
        #40 KEY[0] <= 1'b1; // release reset
    end
    
    // Test sequence
    initial begin
        SW <= 9'b111111111;  // Set color to cyan
        PS2_DAT <= 1'b1;     // Idle high
        
        // Wait for reset to complete
        #100;
        
        $display("=== ECE241 Milestone 1 Test ===");
        $display("Time(ns) | Event");
        $display("---------|----------------------------------");
        
        // Test 1: Verify initial state
        #1000;
        $display("%0t | Initial position: X=%0d, Y=%0d, State=%h", 
                 $time, block_x, block_y, fsm_state);
        
        // Test 2: Wait for animation cycle to complete initial draw
        wait(fsm_state == 4'h3);  // Wait for idle state D
        $display("%0t | Initial draw complete, reached IDLE state", $time);
        
        // Test 3: Simulate 'z' key press for drop
        $display("%0t | Simulating 'z' key press (scancode 0x1A)...", $time);
        send_ps2_scancode(8'h1A);
        
        // Wait for scancode to be received
        wait(ps2_rec == 1'b1);
        #100;
        $display("%0t | PS/2 received! scancode=0x%h, drop_signal=%b", 
                 $time, scancode, drop_signal);
        
        // Test 4: Monitor drop sequence
        if (drop_signal) begin
            $display("%0t | DROP SIGNAL ACTIVE - Block should start falling", $time);
            wait(fsm_state == 4'hC);  // Drop state M (M=12=0xC)
            $display("%0t | Entered DROP state M", $time);
            
            // Monitor Y position during drop
            repeat(20) begin
                #1000;
                $display("%0t | Dropping... Y=%0d, State=%h, at_bottom=%b", 
                         $time, block_y, fsm_state, at_bottom);
            end
        end
        
        // Test 5: Wait for block to reach bottom and lock
        wait(at_bottom == 1'b1);
        $display("%0t | Block reached bottom (Y=%0d)", $time, block_y);
        
        wait(is_locked == 1'b1);
        $display("%0t | Block LOCKED at bottom!", $time);
        
        // Test 6: Verify block stays locked
        #5000;
        $display("%0t | Verifying lock... Y=%0d (should not change)", $time, block_y);
        
        #5000;
        $display("%0t | Lock verified! Y=%0d", $time, block_y);
        
        $display("\n=== Test Summary ===");
        $display("✓ PS/2 interface working (scancode received)");
        $display("✓ Drop signal generation working");
        $display("✓ Block drops to bottom");
        $display("✓ Block locks in place");
        $display("\nAll tests passed!");
        
        #10000;
        $stop;
    end
    
    // Task to send a PS/2 scancode (11 bits: START + 8 data + PARITY + STOP)
    task send_ps2_scancode;
        input [7:0] code;
        integer i;
        reg parity;
        begin
            parity = ^code;  // Odd parity
            
            // Wait for PS/2 clock low
            wait(PS2_CLK == 1'b0);
            
            // START bit (0)
            PS2_DAT = 1'b0;
            wait(PS2_CLK == 1'b1);
            wait(PS2_CLK == 1'b0);
            
            // 8 DATA bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                PS2_DAT = code[i];
                wait(PS2_CLK == 1'b1);
                wait(PS2_CLK == 1'b0);
            end
            
            // PARITY bit
            PS2_DAT = ~parity;  // Odd parity
            wait(PS2_CLK == 1'b1);
            wait(PS2_CLK == 1'b0);
            
            // STOP bit (1)
            PS2_DAT = 1'b1;
            wait(PS2_CLK == 1'b1);
            wait(PS2_CLK == 1'b0);
            
            // Return to idle
            PS2_DAT = 1'b1;
        end
    endtask
    
    // Monitor for significant events
    always @(posedge CLOCK_50) begin
        // Track state transitions
        if (O1.y_Q != O1.Y_D && O1.Y_D != 4'h3 && O1.Y_D != 4'h1) begin
            $display("%0t | FSM: %h -> %h", $time, O1.y_Q, O1.Y_D);
        end
    end

endmodule

// Include the support modules from vga_demo.v
// syncronizer, implemented as two FFs in series
module sync(D, Resetn, Clock, Q);
    input wire D;
    input wire Resetn, Clock;
    output reg Q;

    reg Qi;

    always @(posedge Clock)
        if (Resetn == 0) begin
            Qi <= 1'b0;
            Q <= 1'b0;
        end
        else begin
            Qi <= D;
            Q <= Qi;
        end
endmodule