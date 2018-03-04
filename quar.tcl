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
run_quartus_jobs $opts(project) $opts(analysis) $opts(compile) $opts(archive)
project_close
