@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

rem TODO добавить открытие только wlf файла, мб не нужно
rem TODO добавить открытие без дефолтного -f <project_name>.sv
rem TODO конвеерное исполнение, скорее всего отдельный скрипт

:: FIND MODELSIM DIRECTORY
SET MODELSIM_DIR=%QUARTUS_ROOTDIR:~0,-1%
FOR %%A in ("%MODELSIM_DIR%") DO SET MODELSIM_DIR=%%~dpA
SET MODELSIM_DIR=%MODELSIM_DIR%modelsim_ase\win32aloem
:: FIND QUARTUS DIRECTORY
SET QUARTUS_DIR=%QUARTUS_ROOTDIR%\bin64

:: SHOW HELP IF NO PROJECT NAME SPECIFIED
FOR %%A IN ("" "-h") DO IF "%~1"==%%A GOTO HELP

:: DEFINE MAIN VARIABLES
SET BATCH_DIR=%~dp0
SET CREATE_PROJECT_TCL=%BATCH_DIR%quar.tcl
SET PROJECT_DIR=%BATCH_DIR%%1
SET PROJECT_NAME=%~1
SET MS_TCL_NAME=ms.tcl
SET MS_TCL=%BATCH_DIR%%MS_TCL_NAME%
SET MS_PROJECT_DIR=%BATCH_DIR%ms_%1
SET MS_SRCDIR=%MS_PROJECT_DIR%\src
SHIFT

:ARGUMENTS
:: ARGUMENTS PARSING
IF "%~1"=="" (
    GOTO ENDARGUMENTS
)^
ELSE IF "%~1"=="-a" (
    SET QUARTUS_ARCHIVE=-archive
    SHIFT
)^
ELSE IF "%~1"=="-c" (
    SET QUARTUS_COMPILE=-compile
    SHIFT
)^
ELSE IF "%~1"=="-d" (
    IF NOT "%~2"=="" SET PROJECT_DIR=%~2\%PROJECT_NAME%
    IF NOT "%~2"=="" SET MS_PROJECT_DIR=%~2\ms_%PROJECT_NAME%
    SHIFT
)^
ELSE IF "%~1"=="-e" (
    IF NOT "%~2"=="" SET QUARTUS_SOF=%~2
    SHIFT
)^
ELSE IF "%~1"=="-f" (
    IF NOT "%~2"=="" SET PROJECT_FILES=%~2
    SHIFT
)^
ELSE IF "%~1"=="-h" (
    GOTO HELP
)^
ELSE IF "%~1"=="-m" (
    IF NOT "%~2"=="" SET PROJECT_MISC_FILES=%~2
    SHIFT
)^
ELSE IF "%~1"=="-s" (
    SET QUARTUS_COMPILE=-analysis
    SHIFT
)^
ELSE IF "%~1"=="-v" (
    SET CREATE_VCD=1
    SHIFT
)^
ELSE IF "%~1"=="-z" (
    SET MS=1
    SHIFT
)^
ELSE (
    SHIFT
)
GOTO ARGUMENTS
:ENDARGUMENTS


:: SET TOP LEVEL ENTITY FILENAME IF NOT SPECIFIED
IF "%PROJECT_FILES%"=="" SET PROJECT_FILES=%PROJECT_NAME%.sv

:: RUN MODELSIM PART IF SPECIFIED
IF NOT "%MS%"=="" GOTO MODELSIM

:: SET FULL COMPILATION IF SOF FILE REQUESTED
IF NOT "%QUARTUS_SOF%"=="" SET QUARTUS_COMPILE=-compile

:: CREATE PROJECT DIRECTORY AND COPY SV FILES
IF NOT EXIST "%PROJECT_DIR%" mkdir %PROJECT_DIR%
FOR %%I in (%PROJECT_FILES%) do copy %%I %PROJECT_DIR%

:: COPY MISC FILES
IF NOT "%PROJECT_MISC_FILES%"=="" for %%I in (%PROJECT_MISC_FILES%) do copy %%I %PROJECT_DIR%

:: CUT DIRECTORY PATH IN PROJECT_FILES
FOR %%i IN (%PROJECT_FILES%) DO (
    CALL SET temp_qf=%%temp_qf%% %%~ni%%~xi
)
SET PROJECT_FILES=%temp_qf%

:: CUT DIRECTORY PATH IN PROJECT_MISC_FILES AND ADD MISC FLAG
FOR %%i IN (%PROJECT_MISC_FILES%) DO (
    CALL SET temp_misc=%%temp_misc%% %%~ni%%~xi
)
IF NOT "%PROJECT_MISC_FILES%"=="" SET PROJECT_MISC_FILES=-misc "%temp_misc%"

:: RUN QUARTUS TCL SCRIPT
cd /D %PROJECT_DIR%
%QUARTUS_DIR%\quartus_sh -t %CREATE_PROJECT_TCL% -project %PROJECT_NAME% -sv "%PROJECT_FILES%" %QUARTUS_COMPILE% %QUARTUS_ARCHIVE% %PROJECT_MISC_FILES%

:: COPY SOF/QAR FILES TO QUARTUS_SOF DIRECTORY
IF NOT "%QUARTUS_SOF%"=="" (
    IF NOT EXIST "%QUARTUS_SOF%" mkdir %QUARTUS_SOF%
    copy %PROJECT_DIR%\output_files\%PROJECT_NAME%.sof %QUARTUS_SOF%
    IF NOT "%QUARTUS_ARCHIVE%"=="" copy %PROJECT_DIR%\%PROJECT_NAME%.qar %QUARTUS_SOF%
)
GOTO END

:MODELSIM
:: CREATE PROJECT DIRECTORY AND COPY SV/DO FILES
IF NOT EXIST "%MS_PROJECT_DIR%" mkdir %MS_SRCDIR%
FOR %%I in (%PROJECT_FILES%) do copy %%I %MS_SRCDIR%
FOR %%I in (%PROJECT_MISC_FILES%) do copy %%I %MS_SRCDIR%

:: COPY MAIN TCL FILE TO MS_PROJECT_DIR
copy %MS_TCL% %MS_PROJECT_DIR%

:: CUT DIRECTORY PATH IN PROJECT_FILES
FOR %%i IN (%PROJECT_FILES%) DO (
    CALL SET temp_qf=%%temp_qf%% %%~ni%%~xi
)
SET PROJECT_FILES=%temp_qf%

:: CUT DIRECTORY PATH IN PROJECT_MISC_FILES
FOR %%i IN (%PROJECT_MISC_FILES%) DO (
    CALL SET temp_misc=%%temp_misc%% %%~ni%%~xi
)
SET PROJECT_MISC_FILES=%temp_misc%

:: RUN MODELSIM TCL SCRIPT
cd /D %MS_PROJECT_DIR%
IF EXIST "%PROJECT_NAME%.mpf" %MODELSIM_DIR%\vsim -do "do ./%MS_TCL_NAME% %PROJECT_NAME% {%PROJECT_FILES%} {%PROJECT_MISC_FILES%}"
IF NOT EXIST "%PROJECT_NAME%.mpf" %MODELSIM_DIR%\vsim -do "project new . %PROJECT_NAME%; do ./%MS_TCL_NAME% %PROJECT_NAME% {%PROJECT_FILES%} {%PROJECT_MISC_FILES%}"
IF NOT "%CREATE_VCD%"=="" %MODELSIM_DIR%\vsim -c -do "project open %PROJECT_NAME%; wlf2vcd ./src/%PROJECT_NAME%.wlf -o ./src/%PROJECT_NAME%.vcd; quit"
GOTO END

:HELP
::HELP MESSAGE
ECHO Usage: %~0 ^<project_name^> [options]
ECHO     -a    Archive project
ECHO     -c    Full compilation of project
ECHO     -d    Set project root directory (current by default)
ECHO     -e    Copy .sof file to directory (with .qar if -a is set)
ECHO     -f    SystemVerilog files for adding to project (^<project_name^>.sv by default; example: "1.sv 2.sv")
ECHO     -h    Prints this help
ECHO     -m    Misc files for adding to archive/ModelSim .do files (example: "top.do top.wlf")
ECHO     -s    Analysis ^& Synthesis of project
ECHO     -v    Create .vcd file from .wlf file in ModelSim
ECHO     -z    Run ModelSim instead of Quartus II

:END