onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /module_tb/clk
add wave -noupdate /module_tb/rstb
add wave -noupdate /module_tb/test_tb1
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {99560 ps} 0}
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {105 ns}
