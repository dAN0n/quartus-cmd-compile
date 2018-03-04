package require cmdline
load_package flow

set options {\
    { "project.arg" "" "Project name" }\
    { "sv.arg" "" "Project verilog files array" }\
    { "misc.arg" "" "Project misc files array" }\
    { "analysis" "" "Project Analysis & Synthesis" }\
    { "compile" "" "Project full compilation" }\
    { "archive" "" "Archive project to qar file" }\
}
array set opts [::cmdline::getoptions quartus(args) $options]

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

proc run_analysis_and_synthesis {} {
    puts "\nExecuting Analysis & Synthesis\n"
    if { [catch {execute_module -tool map} result] } {
        puts "ERROR: Analysis & Synthesis failed. See the report file.\n"
    } else {
        puts "\nAnalysis & Synthesis was successful.\n"
    }
}

proc run_full_compilation {} {
    puts "\nExecuting Full compilation\n"
    if { [catch {execute_flow -compile} result] } {
        puts "ERROR: Full compilation failed. See the report files.\n"
    } else {
        puts "\nFull compilation was successful.\n"
    }
}

proc create_archive {project} {
    puts "\nExecuting archivation\n"
    if { [catch {project_archive $project.qar -all_revisions -overwrite} result] } {
        puts "ERROR: Archivation failed. See the report files.\n"
    } else {
        puts "\nArchivation was successful.\n"
    }
}

if { ![project_exists $opts(project)] } {
    create_new_project $opts(project)
    add_sv_files $opts(sv)
    puts "\nProject \"$opts(project)\" was created and opened\n"
} else {
    project_open $opts(project)
    add_sv_files $opts(sv)
    puts "\nProject \"$opts(project)\" was opened\n"
}

if { $opts(misc) ne "" } { add_misc_files $opts(misc) }
if { $opts(analysis) }   { run_analysis_and_synthesis }
if { $opts(compile) }    { run_full_compilation }
if { $opts(archive) }    { create_archive $opts(project) }
project_close
