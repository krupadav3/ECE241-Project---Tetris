onerror {resume}
quietly WaveActivateNextPane {} 0

# Clock and reset
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label KEY -radix binary /testbench/KEY
add wave -noupdate -label resetn -radix binary /testbench/dut/resetn
add wave -noupdate -label KEY1 -radix binary /testbench/dut/KEY1

# VGA signals
add wave -noupdate -divider "VGA Outputs"
add wave -noupdate -label VGA_X -radix decimal /testbench/VGA_X
add wave -noupdate -label VGA_Y -radix decimal /testbench/VGA_Y
add wave -noupdate -label VGA_COLOR -radix hexadecimal /testbench/VGA_COLOR
add wave -noupdate -label plot -radix binary /testbench/plot

# Memory signals
add wave -noupdate -divider "Memory System"
add wave -noupdate -label inBlock -radix binary /testbench/dut/inBlock
add wave -noupdate -label memAddress -radix decimal /testbench/dut/memAddress
add wave -noupdate -label blockColour -radix hexadecimal /testbench/dut/blockColour
add wave -noupdate -label showBlock -radix binary /testbench/dut/showBlock

# Configure wave display
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
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
update
WaveRestoreZoom {0 ns} {600000 ns}