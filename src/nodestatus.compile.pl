#!/usr/local/bin/perl
###################################################################
#
#             File: nodestatus.compile.pl
#         Revision: 1.0
#
#           Author: William P Dooley
#
#    Original Date: 02/05
#
#      Description: This program compiles the nodestatus code into 
#                   appropriate nodestatus directorie
#
#           Usage:  nodestatus.compile.pl  
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  02/05      wpd           Modified from UNIX script
###################################################################


$version = "$0 version 1.02\n";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;
use File::Basename;

# ===================================================================
# Get Command Line Options
# ===================================================================

GetOptions(
            "v", "version",
            "h", "help",
            "d", "debug", "debugextensive"
          );

# ===================================================================
# Version check
# ===================================================================
if ( $opt_v or $opt_version ) { die $version }

if ( $opt_h or $opt_help ) {
  usage();
  die $version;
}

# ===================================================================
# Begining of Main
# ===================================================================

#
# Set up the standard variables
#

@platform = qw(SUN);

#
# Copmile the code
#

#
# Check if individual programs were specified.
#

$parms_found =+ @ARGV;

foreach $platform (@platform) {
   print "Compiling nodestatus for $platform\n";
   $src_dir = "/esm/prod/nodestatus/source/";
   chdir "/esm/prod/nodestatus/bin";

   if ( $parms_found eq 0 ) {
      @files = qw(Node_Group_Extract.pl nodestatus.alert.pl nodestatus.clean_up.pl nodestatus.config_populate.pl nodestatus.delta.pl nodestatus.sweep.pl);
   } else {
      @files       = @ARGV;
   }

   #
   # Compile Programs
   #

   foreach $file (@files) {
      print "    $file\n";     
      `/opt/OV/perl2exe/perl2exe -platform=$platform $src_dir/$file > /dev/null`;
   }


   system "chmod 755 \*";
   system "chown root:opcgrp \*";

}

