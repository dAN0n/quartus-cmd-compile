@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

rem TODO моделсим часть
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
SHIFT

:: ARGUMENTS PARSING
:ARGUMENTS
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
    SHIFT
)^
ELSE IF "%~1"=="-e" (
    IF NOT "%~2"=="" SET QUARTUS_SOF=%~2
    SHIFT
)^
ELSE IF "%~1"=="-f" (
    IF NOT "%~2"=="" SET QUARTUS_FILES=%~2
    SHIFT
)^
ELSE IF "%~1"=="-h" (
    GOTO HELP
)^
ELSE IF "%~1"=="-s" (
    SET QUARTUS_COMPILE=-analysis
    SHIFT
)^
ELSE (
    SHIFT
)
GOTO ARGUMENTS
:ENDARGUMENTS

:: SET TOP LEVEL ENTITY FILENAME IF NOT SPECIFIED
IF "%QUARTUS_FILES%"=="" SET QUARTUS_FILES=%PROJECT_NAME%.sv

:: SET FULL COMPILATION IF SOF FILE REQUESTED
IF NOT "%QUARTUS_SOF%"=="" SET QUARTUS_COMPILE=-compile

:: CREATE PROJECT DIRECTORY AND COPY SV FILES
IF NOT EXIST %PROJECT_DIR% mkdir %PROJECT_DIR%
for %%I in (%QUARTUS_FILES%) do copy %%I %PROJECT_DIR%

:: RUN QUARTUS TCL SCRIPT
cd /D %PROJECT_DIR%
%QUARTUS_DIR%\quartus_sh -t %CREATE_PROJECT_TCL% -project %PROJECT_NAME% -sv "%QUARTUS_FILES%" %QUARTUS_COMPILE% %QUARTUS_ARCHIVE%

:: COPY SOF/QAR FILES TO QUARTUS_SOF DIRECTORY
IF NOT "%QUARTUS_SOF%"=="" (
    IF NOT EXIST %QUARTUS_SOF% mkdir %QUARTUS_SOF%
    copy %PROJECT_DIR%\output_files\%PROJECT_NAME%.sof %QUARTUS_SOF%
    IF NOT "%QUARTUS_ARCHIVE%"=="" copy %PROJECT_DIR%\%PROJECT_NAME%.qar %QUARTUS_SOF%
)
GOTO END

rem %MODELSIM_ROOTDIR%\vsim

::HELP MESSAGE
:HELP
ECHO Usage: %~0 ^<project_name^> [options]
ECHO     -a    Archive project
ECHO     -c    Full compilation of project
ECHO     -d    Set project root directory (current by default)
ECHO     -e    Copy .sof file to directory (with .qar if -a is set)
ECHO     -f    SystemVerilog files for adding to project (example: "top.sv sum.sv")
ECHO     -h    Prints this help
ECHO     -s    Analysis ^& Synthesis of project

:END