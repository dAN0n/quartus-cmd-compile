set files   [string trim $2]
set dofiles [string trim $3]

project open $1
foreach file $files { project addfile ./src/$file }
foreach file $dofiles { project addfile ./src/$file }
project calculateorder

foreach file $files { vlog ./src/$file }
vsim work.$1 -wlf ./src/$1.wlf
foreach file $dofiles { do ./src/$file }
