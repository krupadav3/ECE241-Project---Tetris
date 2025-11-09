onerror {resume}
quietly WaveActivateNextPane {} 0

# ============================================================================
# BASIC SIGNALS
# ============================================================================
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label Resetn -radix binary /testbench/KEY[0]
add wave -noupdate -label SW -radix hexadecimal /testbench/SW

# ============================================================================
# PS/2 INTERFACE SIGNALS (Critical for Milestone 1!)
# ============================================================================
add wave -noupdate -divider {PS/2 Interface}
add wave -noupdate -label PS2_CLK -radix binary /testbench/PS2_CLK
add wave -noupdate -label PS2_DAT -radix binary /testbench/PS2_DAT
add wave -noupdate -label PS2_CLK_sync -radix binary /testbench/PS2_CLK_S
add wave -noupdate -label PS2_DAT_sync -radix binary /testbench/PS2_DAT_S
add wave -noupdate -label negedge_ps2_clk -radix binary /testbench/negedge_ps2_clk
add wave -noupdate -label Serial -radix hexadecimal /testbench/Serial
add wave -noupdate -label Packet -radix unsigned /testbench/Packet
add wave -noupdate -label ps2_rec -radix binary /testbench/ps2_rec
add wave -noupdate -label scancode -radix hexadecimal /testbench/scancode
add wave -noupdate -label drop_signal -radix binary /testbench/drop_signal

# ============================================================================
# FSM STATE AND CONTROL SIGNALS
# ============================================================================
add wave -noupdate -divider {FSM Control}
add wave -noupdate -label FSM_State -radix hexadecimal /testbench/O1/y_Q
add wave -noupdate -label FSM_Next -radix hexadecimal /testbench/O1/Y_D
add wave -noupdate -label Lx -radix binary /testbench/O1/Lx
add wave -noupdate -label Ly -radix binary /testbench/O1/Ly
add wave -noupdate -label Lxc -radix binary /testbench/O1/Lxc
add wave -noupdate -label Lyc -radix binary /testbench/O1/Lyc
add wave -noupdate -label Ex -radix binary /testbench/O1/Ex
add wave -noupdate -label Ey -radix binary /testbench/O1/Ey
add wave -noupdate -label Exc -radix binary /testbench/O1/Exc
add wave -noupdate -label Eyc -radix binary /testbench/O1/Eyc
add wave -noupdate -label erase -radix binary /testbench/O1/erase
add wave -noupdate -label write -radix binary /testbench/O1/write
add wave -noupdate -label Tdir -radix binary /testbench/O1/Tdir
add wave -noupdate -label Xdir -radix binary /testbench/O1/Xdir

# ============================================================================
# POSITION TRACKING
# ============================================================================
add wave -noupdate -divider {Position Counters}
add wave -noupdate -label X_position -radix unsigned /testbench/O1/X
add wave -noupdate -label Y_position -radix unsigned /testbench/O1/Y
add wave -noupdate -label XC_offset -radix unsigned /testbench/O1/XC
add wave -noupdate -label YC_offset -radix unsigned /testbench/O1/YC
add wave -noupdate -label at_bottom -radix binary /testbench/O1/at_bottom
add wave -noupdate -label is_dropping -radix binary /testbench/O1/is_dropping
add wave -noupdate -label is_locked -radix binary /testbench/O1/is_locked

# ============================================================================
# VGA OUTPUT SIGNALS
# ============================================================================
add wave -noupdate -divider {VGA Outputs}
add wave -noupdate -label VGA_x -radix unsigned /testbench/vga_x
add wave -noupdate -label VGA_y -radix unsigned /testbench/vga_y
add wave -noupdate -label VGA_color -radix hexadecimal /testbench/vga_color
add wave -noupdate -label VGA_write -radix binary /testbench/vga_write

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {10000 ns}
