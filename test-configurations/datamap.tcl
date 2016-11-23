#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

set pgm_dir "/apps/esm/vpo/vpo_server/src"
set pgm     "datamap_util.pl"
set pgm_parm "--tcl --app=esm"
set pgm_cmd "perl $pgm_dir/$pgm $pgm_parm"

set return_val [eval [concat exec $pgm_cmd]]

puts $return_val

#puts "\n"

set item ""

#foreach item { $return_val } {
#    
#    puts "line: $item\n"
#    
#}

