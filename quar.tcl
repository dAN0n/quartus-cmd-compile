package require cmdline
load_package flow

set options {\
    { "project.arg" "" "Project name" }\
    { "sv.arg" "" "Project verilog files array" }\
    { "analysis" "" "Project Analysis & Synthesis" }\
    { "compile" "" "Project full compilation" }\
    { "archive" "" "Archive project to qar file" }\
}
array set opts [::cmdline::getoptions quartus(args) $options]

if { ![project_exists $opts(project)] } {
    project_new $opts(project) -family "Cyclone V" -part "5CSEMA5F31C6" -overwrite
    set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files 
    set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0 
    set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85 
    set_global_assignment -name DEVICE_FILTER_PACKAGE FBGA 
    set_global_assignment -name DEVICE_FILTER_PIN_COUNT 896 
    set_global_assignment -name DEVICE_FILTER_SPEED_GRADE 6 
    set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256    
    foreach file $opts(sv) {
        set_global_assignment -name SYSTEMVERILOG_FILE $file
    }
    puts "\nProject \"$opts(project)\" was created\n"
    project_close
} else {
    project_open $opts(project)
    foreach file $opts(sv) {
        set_global_assignment -name SYSTEMVERILOG_FILE $file
    }
    project_close
}

if {$opts(analysis)} {
    project_open $opts(project)
    puts "\nExecuting Analysis & Synthesis\n"
    if {[catch {execute_module -tool map} result]} {
        puts "ERROR: Analysis & Synthesis failed. See the report file.\n"
    } else {
        puts "\nAnalysis & Synthesis was successful.\n"
    }
    project_close
}

if {$opts(compile)} {
    project_open $opts(project)
    puts "\nExecuting full compilation\n"
    if {[catch {execute_flow -compile} result]} {
        puts "ERROR: Analysis & Synthesis failed. See the report files.\n"
    } else {
        puts "\nFull compilation was successful.\n"
    }
    project_close
}

if {$opts(archive)} {
    project_open $opts(project)
    puts "\nExecuting archivation\n"
    if {[catch {project_archive $opts(project).qar -all_revisions -overwrite} result]} {
        puts "ERROR: Archivation failed. See the report files.\n"
    } else {
        puts "\nArchivation was successful.\n"
    }
    project_close
}
