# Optargs package
package require cmdline

# Create new Quartus project for Cyclone V DE1-SoC board
proc create_new_project {project} {
    project_new $project -family "Cyclone V" -part "5CSEMA5F31C6" -overwrite
    set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
    set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
    set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
    set_global_assignment -name DEVICE_FILTER_PACKAGE FBGA
    set_global_assignment -name DEVICE_FILTER_PIN_COUNT 896
    set_global_assignment -name DEVICE_FILTER_SPEED_GRADE 6
    set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256
}

proc add_sv_files {sv} {
    foreach file $sv { set_global_assignment -name SYSTEMVERILOG_FILE $file }
}

proc add_misc_files {misc} {
    foreach file $misc { set_global_assignment -name MISC_FILE $file }
}

proc run_quartus_jobs {project analysis compile archive} {
    if { $analysis } { execute_command "execute_module -tool map" "Analysis & Synthesis" }
    if { $compile }  { execute_command "execute_flow -compile" "Full compilation" }
    if { $archive }  { execute_command "project_archive $project.qar -all_revisions -overwrite" "Archivation" }
}

proc execute_command {command name} {
    puts "\nExecuting $name\n"
    if { [catch { eval $command } result] } {
        puts "\nERROR: $name failed. See the report files.\n"
    } else {
        puts "\n$name was successful.\n"
    }
}

# Open/create Quartus project and make jobs with it
proc quartus {project sv misc analysis compile archive} {
    # Load quartus_sh flow package
    load_package flow
    if { ![project_exists $project] } {
        create_new_project $project
        add_sv_files $sv
        puts "\nProject \"$project\" was created and opened\n"
    } else {
        project_open $project
        add_sv_files $sv
        puts "\nProject \"$project\" was opened\n"
    }

    if { $misc ne "" } { add_misc_files $misc }
    run_quartus_jobs $project $analysis $compile $archive
    project_close
}

################################################################################

# Generate sample .do file with short tutorial
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
    puts $tcl "# Use \"radix signal <name> <b|d|h|o|u|a|t> to set radix\""
    puts $tcl "#"
    puts $tcl "# Always blocks may not show correct waveforms because of x\'s initial value"
    puts $tcl "# In that situations use: foreach signal \[find signals *\] { force \$signal 0 -c 0 }"
    puts $tcl "#"
    puts $tcl "# Use \"force <name> <value> \[@\]<time>\" for set signal value in some relative time (@ - absolute time)"
    puts $tcl "# For example \"force sw\[1:0\] 2'b10 0, 2#10 10\""
    puts $tcl "#"
    puts $tcl "# \"-repeat (-r) \[@\]<time>\" flag repeats a series of forced values and times at the time specified"
    puts $tcl "# \"-cancel (-c) \[@\]<time>\" flag cancels the force command at the time specified"
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
    puts $tcl "# For zooming you can use \"wave zoom full\" or \"wave zoom range <start> <end>\""
    puts $tcl "#"
    puts $tcl "# Use \"quit -sim\" and \"quit\" to close ModelSim after script executing"
    puts $tcl ""
    puts $tcl ""
    puts $tcl "view wave"
    puts $tcl "delete wave *"
    puts $tcl "add wave *"
    puts $tcl ""
    puts $tcl "foreach signal \[find signals *\] { force \$signal 0 -c 0 }"
    puts $tcl ""
    puts $tcl "run 1000"
    puts $tcl "wave zoom full"
    close $tcl
}

# Open ModelSim project and make waveforms with it
proc modelsim {project sv misc} {
    # Trim spaces for correct compilation
    set files   [string trim $sv]
    set dofiles [string trim $misc]

    project open $project
    foreach file $files { project addfile ./src/$file }
    foreach file $dofiles { project addfile ./src/$file }
    # Calculate files compilation order
    project calculateorder

    # Compilate SystemVerilog files
    foreach file $files { vlog ./src/$file }
    # Run simulation
    vsim work.$project -wlf ./src/$project.wlf

    # If tcl script for waveform simulation not exists
    if { [file exists ./src/$project.do] == 0 } {
        generate_do $project
        project addfile ./src/$project.do
    # If tcl script for waveform simulation exists with empty misc files array
    } elseif {[file exists ./src/$project.do] == 1 && $dofiles == ""} {
        do ./src/$project.do
    } else {
        foreach file $dofiles { do ./src/$file }
    }
}

################################################################################

# Main process
# If $1 argument not exists (in quartus_sh run)
if { ![info exists 1] } {
    # Set optargs for work with Quartus commands (not work in ModelSim -do flag)
    set options {\
        { "project.arg" "" "Project name" }\
        { "sv.arg" "" "Project verilog files array" }\
        { "misc.arg" "" "Project misc files array" }\
        { "analysis" "Run Analysis & Synthesis" }\
        { "compile" "Run Full compilation" }\
        { "archive" "Archive project to .qar file" }\
        { "modelsim" "Run ModelSim instead of Quartus" }\
    }
    array set opts [::cmdline::getoptions quartus(args) $options]

    quartus $opts(project) $opts(sv) $opts(misc) $opts(analysis) $opts(compile) $opts(archive)
# If $1 argument exists (in vsim -do "do ..." run)
} elseif { [info exists 1] && $1 == "-modelsim" } {
    modelsim $2 $3 $4
}