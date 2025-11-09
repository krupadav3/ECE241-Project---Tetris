`default_nettype none

/*  This code animates one colored block that moves left/right on the display and bounces
 *  off the sides. Press 'z' on the PS2 keyboard to make the block fall down FAST.
 *  Block locks in place at bottom until KEY[0] reset is pressed.
*/

module vga_demo(CLOCK_50, SW, KEY, LEDR, PS2_CLK, PS2_DAT, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0,
				VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
	
    parameter nX = 10;
    parameter nY = 9;

	input wire CLOCK_50;	
	input wire [9:0] SW;
	input wire [3:0] KEY;
	output wire [9:0] LEDR;
    inout wire PS2_CLK, PS2_DAT;
    output wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	output wire [7:0] VGA_R;
	output wire [7:0] VGA_G;
	output wire [7:0] VGA_B;
	output wire VGA_HS;
	output wire VGA_VS;
	output wire VGA_BLANK_N;
	output wire VGA_SYNC_N;
	output wire VGA_CLK;	

	wire [nX-1:0] O1_x;
	wire [nY-1:0] O1_y;
	wire [8:0] O1_color;
    wire O1_write;

    reg prev_ps2_clk;
    wire negedge_ps2_clk;
    wire ps2_rec;
    reg [32:0] Serial;
    reg [3:0] Packet;
    wire [7:0] scancode;
    reg Esc;
    wire drop_signal;
	
    wire Resetn, PS2_CLK_S, PS2_DAT_S;

    assign Resetn = KEY[0];

    sync S3 (PS2_CLK, Resetn, CLOCK_50, PS2_CLK_S);
    sync S4 (PS2_DAT, Resetn, CLOCK_50, PS2_DAT_S);

    always @(posedge CLOCK_50)
        prev_ps2_clk <= PS2_CLK_S;

    assign negedge_ps2_clk = (prev_ps2_clk & !PS2_CLK_S);

    always @(posedge CLOCK_50) begin
        if (Resetn == 0)
            Serial <= 33'b0;
        else if (negedge_ps2_clk) begin
            Serial[31:0] <= Serial[32:1];
            Serial[32] <= PS2_DAT_S;
        end
    end
        
    always @(posedge CLOCK_50) begin
        if (!Resetn || Packet == 'd11)
            Packet <= 'b0;
        else if (negedge_ps2_clk) begin
            Packet <= Packet + 'b1;
        end
    end
        
    assign ps2_rec = (Packet == 'd11) && (Serial[30:23] == Serial[8:1]);

    regn USC (Serial[8:1], Resetn, ps2_rec, CLOCK_50, scancode);
    assign LEDR = {2'b0, scancode};

    // Press 'z' to drop (scancode 0x1A)
    assign drop_signal = ps2_rec && (scancode == 8'h1A);

    // instantiate the animated block
    object O1 (Resetn, CLOCK_50, drop_signal, SW[8:0], O1_x, O1_y, O1_color, O1_write);
        defparam O1.nX = nX;
        defparam O1.nY = nY;

    // display PS2 data on HEX displays
    hex7seg H0 (Serial[4:1], HEX0);
    hex7seg H1 (Serial[8:5], HEX1);
    hex7seg H2 (Serial[15:12], HEX2);
    hex7seg H3 (Serial[19:16], HEX3);
    hex7seg H4 (Serial[26:23], HEX4);
    hex7seg H5 (Serial[30:27], HEX5);

    // connect to VGA controller
    vga_adapter VGA (
		.resetn(KEY[0]),
		.clock(CLOCK_50),
		.color(O1_color),
		.x(O1_x),
		.y(O1_y),
		.write(O1_write),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK_N(VGA_BLANK_N),
		.VGA_SYNC_N(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
		defparam VGA.BACKGROUND_IMAGE = "./MIF/checkers_640_9.mif";

endmodule

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

// n-bit register with sync reset and enable
module regn(R, Resetn, E, Clock, Q);
    parameter n = 8;
    input wire [n-1:0] R;
    input wire Resetn, E, Clock;
    output reg [n-1:0] Q;

    always @(posedge Clock)
        if (Resetn == 0)
            Q <= 'b0;
        else if (E)
            Q <= R;
endmodule

// toggle flip-flop with reset
module ToggleFF(T, Resetn, Clock, Q);
    input wire T, Resetn, Clock;
    output reg Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 1'b0;
        else if (T)
            Q <= ~Q;
endmodule

// up/down counter with reset, enable, and load controls
module UpDn_count (R, Clock, Resetn, E, L, UpDn, Q);
    parameter n = 8;
    input wire [n-1:0] R;
    input wire Clock, Resetn, E, L, UpDn;
    output reg [n-1:0] Q;

    always @ (posedge Clock)
        if (Resetn == 0)
            Q <= 0;
        else if (L == 1)
            Q <= R;
        else if (E)
            if (UpDn == 1)
                Q <= Q + 1'b1;
            else
                Q <= Q - 1'b1;
endmodule

// counter
module Up_count (Clock, Resetn, Q);
    parameter n = 8;
    input wire Clock, Resetn;
    output reg [n-1:0] Q;

    always @ (posedge Clock)
        if (Resetn == 0)
            Q <= 'b0;
        else 
            Q <= Q + 1'b1;
endmodule

module hex7seg (hex, display);
    input wire [3:0] hex;
    output reg [6:0] display;

    always @ (hex)
        case (hex)
            4'h0: display = 7'b1000000;
            4'h1: display = 7'b1111001;
            4'h2: display = 7'b0100100;
            4'h3: display = 7'b0110000;
            4'h4: display = 7'b0011001;
            4'h5: display = 7'b0010010;
            4'h6: display = 7'b0000010;
            4'h7: display = 7'b1111000;
            4'h8: display = 7'b0000000;
            4'h9: display = 7'b0011000;
            4'hA: display = 7'b0001000;
            4'hB: display = 7'b0000011;
            4'hC: display = 7'b1000110;
            4'hD: display = 7'b0100001;
            4'hE: display = 7'b0000110;
            4'hF: display = 7'b0001110;
        endcase
endmodule

// implements a moving colored block that animates horizontally and can drop FAST and lock
module object (Resetn, Clock, drop, new_color, VGA_x, VGA_y, VGA_color, VGA_write);

    parameter nX = 10;
    parameter nY = 9;

    parameter XSCREEN = 640;
    parameter YSCREEN = 480;

    parameter XDIM = 30, YDIM = 30; // block dimensions

    parameter X_INIT = 10'd320;
    parameter Y_INIT = 9'd50;  // Start near top of screen

    parameter KK = 20; // controls animation speed
    parameter MM = 8;

    // state codes
    parameter A = 4'b0000, B = 4'b0001, C = 4'b0010, D = 4'b0011,
              E = 4'b0100, F = 4'b0101, G = 4'b0110, H = 4'b0111,
              I = 4'b1000, J = 4'b1001, K = 4'b1010, L = 4'b1011,
              M = 4'b1100, N = 4'b1101, O = 4'b1110, P = 4'b1111;

    input wire Resetn, Clock;
    input wire drop;  // signal to make block fall
    input wire [8:0] new_color;
    output wire [nX-1:0] VGA_x;
	output wire [nY-1:0] VGA_y;
	output wire [8:0] VGA_color;
    output wire VGA_write;

	wire [nX-1:0] X, XC, X0;
	wire [nY-1:0] Y, YC, Y0;
	wire [8:0] the_color, color;
    wire [KK-1:0] slow;
    reg Lx, Ly, Lxc, Lyc, Exc, Eyc, Ex, Ey;
    wire sync, Xdir;
    reg erase, Tdir;
    reg [3:0] y_Q, Y_D;
    reg write;
    reg is_dropping;  // flag to track if block is dropping
    reg is_locked;    // flag to lock block at bottom

    reg [2:0] ys_Q, Ys_D;
    reg sll, srl;
    reg [MM-1:0] mask;

    assign X0 = X_INIT;
    assign Y0 = Y_INIT;
    parameter ALT = 9'b0;
    
    UpDn_count U2 (X0, Clock, Resetn, Ex, Lx, Xdir, X);
        defparam U2.n = nX;

    UpDn_count U1 (Y0, Clock, Resetn, Ey, Ly, 1'b1, Y);  // always move down when enabled
        defparam U1.n = nY;

    assign the_color = color == 9'b0 ? 9'b111111111 : new_color;
    regn UC (the_color, Resetn, (color == 9'b0), Clock, color); 
        defparam UC.n = 9;

    UpDn_count U3 ({nX{1'd0}}, Clock, Resetn, Exc, Lxc, 1'b1, XC);
        defparam U3.n = nX;
    UpDn_count U4 ({nY{1'd0}}, Clock, Resetn, Eyc, Lyc, 1'b1, YC);
        defparam U4.n = nY;

    Up_count U6 (Clock, Resetn, slow);
        defparam U6.n = KK;

    assign sync = ((slow | (mask << KK-MM)) == {KK{1'b1}});

    ToggleFF U7 (Tdir, Resetn, Clock, Xdir);

    // Create 3D cube effect with shading
    wire [8:0] shaded_color;
    wire is_top_edge, is_left_edge, is_right_edge, is_bottom_edge;
    wire is_border;
    
    assign is_top_edge = (YC < 3);
    assign is_left_edge = (XC < 3);
    assign is_right_edge = (XC >= XDIM - 3);
    assign is_bottom_edge = (YC >= YDIM - 3);
    assign is_border = is_top_edge || is_left_edge || is_right_edge || is_bottom_edge;
    
    assign shaded_color = is_border ? (
        (is_top_edge || is_left_edge) ? 
            {color[8:6] | 3'b001, color[5:3] | 3'b001, color[2:0] | 3'b001} :
            {color[8:6] >> 1, color[5:3] >> 1, color[2:0] >> 1}
    ) : color;
    
    assign VGA_x = X + XC;
    assign VGA_y = Y + YC;
    assign VGA_color = erase == 0 ? shaded_color : ALT;
    assign VGA_write = write;

    // Check if block is at bottom (5 pixels above floor)
    wire at_bottom = (Y >= YSCREEN - YDIM - 5);

    // FSM Algorithm
    always @ (*)
        case (y_Q)
            A:  Y_D = B;

            B:  if (XC != XDIM-1) Y_D = B;
                else Y_D = C;
            C:  if (YC != YDIM-1) Y_D = B;
                else Y_D = D;

            D:  if (is_locked) Y_D = D;  // LOCKED - stay here forever
                else if (drop && !is_dropping) Y_D = M;  // Start dropping
                else if (!sync) Y_D = D;
                else Y_D = E;
            
            E:  if (is_locked) Y_D = D;
                else Y_D = F;

            F:  if (XC != XDIM-1) Y_D = F;
                else Y_D = G;
            G:  if (YC != YDIM-1) Y_D = F;
                else Y_D = H;

            H:  if (is_locked) Y_D = D;
                else Y_D = I;
            I:  Y_D = J;

            J:  if (XC != XDIM-1) Y_D = J;
                else Y_D = K;
            K:  if (YC != YDIM-1) Y_D = J;
                else Y_D = L;
            L:  if (is_locked) Y_D = D;
                else Y_D = D;

            // Drop states - FAST DROP, NO DELAY
            M:  Y_D = N;  // Erase current position
            N:  if (XC != XDIM-1) Y_D = N;
                else if (YC != YDIM-1) Y_D = N;
                else Y_D = O;
            O:  if (at_bottom) Y_D = P;  // Reached bottom, draw final position
                else Y_D = O;  // Keep moving down FAST (no sync delay!)
            P:  if (XC != XDIM-1) Y_D = P;  // Draw block at final position
                else if (YC != YDIM-1) Y_D = P;
                else Y_D = D;  // Go to idle and LOCK

            default: Y_D = A;
        endcase

    always @ (*)
    begin
        Lx = 1'b0; Ly = 1'b0; Lxc = 1'b0; Lyc = 1'b0; Exc = 1'b0; Eyc = 1'b0; 
        erase = 1'b0; write = 1'b0; Ex = 1'b0; Ey = 1'b0; Tdir = 1'b0;
        case (y_Q)
            A:  begin Lx = 1'b1; Ly = 1'b1; Lxc = 1'b1; Lyc = 1'b1; end

            B:  begin Exc = 1'b1; write = 1'b1; end
            C:  begin Lxc = 1'b1; Eyc = 1'b1; end

            D:  Lyc = 1'b1;  // Idle - do nothing if locked
            E:  ;

            F:  begin Exc = 1'b1; erase = 1'b1; write = 1'b1; end
            G:  begin Lxc = 1'b1; Eyc = 1'b1; end

            H:  begin 
                    Lyc = 1'b1; 
                    if (!is_dropping && !is_locked)
                        Tdir = (X == 'd0) || (X == XSCREEN-XDIM); 
                end

            I:  begin if (!is_locked) Ex = 1'b1; end

            J:  begin Exc = 1'b1; write = 1'b1; end
            K:  begin Lxc = 1'b1; Eyc = 1'b1; end
            L:  Lyc = 1'b1;

            // Drop logic - SUPER FAST!
            M:  begin Lxc = 1'b1; Lyc = 1'b1; end
            N:  begin 
                    if (XC != XDIM-1) Exc = 1'b1;
                    else if (YC != YDIM-1) begin Lxc = 1'b1; Eyc = 1'b1; end
                    erase = 1'b1; write = 1'b1;
                end
            O:  begin 
                    Lyc = 1'b1; 
                    Lxc = 1'b1; 
                    if (!at_bottom) Ey = 1'b1;  // Move down EVERY clock cycle (FAST!)
                end
            P:  begin 
                    Exc = 1'b1; 
                    if (YC == YDIM-1) Eyc = 1'b0;
                    else begin Lxc = (XC == XDIM-1); Eyc = (XC == XDIM-1); end
                    write = 1'b1;  // Draw final position
                end
        endcase
    end

    // Track dropping and locked states
    always @(posedge Clock)
        if (Resetn == 0) begin
            is_dropping <= 1'b0;
            is_locked <= 1'b0;
        end
        else begin
            if (y_Q == M)
                is_dropping <= 1'b1;
            
            if (y_Q == P && YC == YDIM-1)  // Finished drawing at bottom
                is_locked <= 1'b1;
            
            if (y_Q == A)  // Reset clears locked state
                is_dropping <= 1'b0;
        end

    always @(posedge Clock)
        if (Resetn == 0)
            y_Q <= A;
        else
            y_Q <= Y_D;

    always @(posedge Clock) begin
        if (Resetn == 0)
            mask <= 'b0;
        else if (srl) begin
            mask[MM-2:0] <= mask[MM-1:1];
            mask[MM-1] <= 1'b1;
        end
        else if (sll) begin
            mask[MM-1:1] <= mask[MM-2:0];
            mask[0] <= 1'b0;
        end
    end

    parameter As = 3'b000, Bs = 3'b001, Cs = 3'b010, Ds = 3'b011, Es = 3'b100;

    always @ (*)
        case (ys_Q)
            As: Ys_D = As;
            default: Ys_D = As;
        endcase

    always @ (*)
    begin
        sll = 1'b0; srl = 1'b0;
    end

    always @(posedge Clock)
        if (Resetn == 0)
            ys_Q <= As;
        else
            ys_Q <= Ys_D;

endmodule