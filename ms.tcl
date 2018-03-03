proc generate_do {name} {
	set tcl [open ./src/$name.do w]
	puts $tcl "# Tutorial for generate waveform in tcl"
	puts $tcl "# From: https://www.microsemi.com/document-portal/doc_view/136364-modelsim-me-10-4c-command-reference-manual-for-libero-soc-v11-7"
	puts $tcl "#"
	puts $tcl "# Use \"view wave\" to show wave window if needed"
	puts $tcl "#"
	puts $tcl "# Use \"add wave <name>\" to add signals to wave window"
	puts $tcl "# For example: \"add wave *\""
	puts $tcl "#"
	puts $tcl "# Use \"virtual signal {<name> {<signals>}}\" or \"add wave {<name> {<signals>}}\" for adding custom groups"
	puts $tcl "# For example: \"virtual signal {sw7_4 {sw\[7:4\]}}\""
	puts $tcl "#"
	puts $tcl "# Use \"force <name> <value> \[@\]<time>\" for set signal value for some relative time (@ - absolute time)"
	puts $tcl "# For example \"force sw\[1:0\] 2'b10 10, 2#01 20\""
	puts $tcl "#"
	puts $tcl "# \"-repeat (-r) \[@\]<time>\" flag repeats a series of forced values and times at the time specified"
	puts $tcl "# \"-cancel \[@\]<time>\" flag cancels the force command at the time specified"
	puts $tcl "#"
	puts $tcl "# To force signal to set some value whenever the value on the signal is some value use:"
	puts $tcl "# when {siga = 10#1} { force -deposit siga 10#85 }"
	puts $tcl "#"
	puts $tcl "# For increment sequence use:"
	puts $tcl "# for {set i 0} {\$i < 20} {incr i} { force sw 8'd\$i \[expr \$i*10\] }"
	puts $tcl "#"
	puts $tcl "# For random sequence use:"
	puts $tcl "# for {set i 0} {\$i < 20} {incr i} { force sw 8'd\[expr int(rand()*1000)\] \[expr \$i*10\] }"
	puts $tcl "#"
	puts $tcl "# For running simulation use \"run \[@\]<time>\""
	puts $tcl "#"
	puts $tcl "# For zooming you can use \"zoom full\" or \"zoom range <start> <end>\""
	puts $tcl "#"
	puts $tcl "# Use \"quit -sim\" and \"quit\" to close ModelSim after script executing"
	close $tcl
}

set files   [string trim $2]
set dofiles [string trim $3]

project open $1
foreach file $files { project addfile ./src/$file }
foreach file $dofiles { project addfile ./src/$file }
project calculateorder

foreach file $files { vlog ./src/$file }
vsim work.$1 -wlf ./src/$1.wlf

if { [file exists ./src/$1.do] == 0 } {
	generate_do $1
	project addfile ./src/$1.do
} elseif {[file exists ./src/$1.do] == 1 && $dofiles == ""} {
	do ./src/$1.do
} else {
	foreach file $dofiles { do ./src/$file }
}
