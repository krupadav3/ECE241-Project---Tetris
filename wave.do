onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label KEY -radix binary /testbench/KEY
add wave -noupdate -label resetn -radix binary /testbench/resetn
add wave -noupdate -divider "VGA Signals"
add wave -noupdate -label VGA_X -radix decimal /testbench/VGA_X
add wave -noupdate -label VGA_Y -radix decimal /testbench/VGA_Y
add wave -noupdate -label VGA_COLOR -radix hex /testbench/VGA_COLOR
add wave -noupdate -label plot -radix binary /testbench/plot
add wave -noupdate -label inBlock -radix binary /testbench/dut/inBlock

WaveRestoreZoom {0 ns} {100000 ns}