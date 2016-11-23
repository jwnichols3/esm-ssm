#
#
#

#===========================================
#= Modules
#=

use Date::Format;
use Data::Dumper;
use Log::Log4perl;
use Log::Log4perl::Level;
use Log::Dispatch::FileRotate;
use Log::Log4perl::Appender::Screen;



#===========================================
#= Global vars and constants
#=

#-----
#- My name and my dir
#-
our $PARGRAM_FULL_NAME = $0;
our $PROGRAM_NAME = $0;
our $PROGRAM_DIR  = $0;
$PROGRAM_NAME =~ s/^.*[\/\\](\S+)$/$1/;
$PROGRAM_DIR  =~ s/^(.*)$PROGRAM_NAME/$1/;

#------
#- Get current time and get seconds from midnight
#-
our $now = time;
our $now_str = time2str( "%c", $now );

#------
#- Get Time Zone from environemtn variable TZ or set it to the
#- default US/Pacific
#-
our $TZ = ( exists $ENV{TZ} ) ? $ENV{TZ} : "US/Pacific";


#------
#- OVO Commands
#- we are running scripts from the the OVO template or
#- as appication from OVO GUI,
#- so assuming the PATH is set up correctly
#- Some special commands for management server are defined with the full path
#-
our $OPCMSG  = "opcmsg";
our $OPCMON  = "opcmon";
#our $OPCNODE = "/opt/OV/bin/OpC/util/opcnode";
our $OPCNODE = "opcnode";


#------
#- The hash of commands that have been checked before
#- used by the check_command()
#-
our %checked_commands;

#------
#- Verbose level and allowd verbosw modes
#-
our $verbose;
our %allowed_log_levels = ( 'fatal' => $FATAL, 'error' => $ERROR,
                            'warn'  => $WARN,  'info'  => $INFO, 'debug' => $DEBUG );

#------
#- Name of the Error Log File
#-
our $error_log_file_name;

#-----
#- Default Log4perl configuration
#-
our %log4perl_configuration =
      (

        'log4perl.rootLogger' => 'ERROR, SCREEN',

        'log4perl.appender.SCREEN'                => 'Log::Log4perl::Appender::Screen',
        'log4perl.appender.SCREEN.layout'         => 'Log::Log4perl::Layout::PatternLayout',
        'log4perl.appender.SCREEN.layout.ConversionPattern' => '%L:%c: %-5p - %m%n',

        'log4perl.appender.LOGFILE'               => 'Log::Dispatch::FileRotate',
        'log4perl.appender.LOGFILE.layout'        => 'Log::Log4perl::Layout::PatternLayout',
        'log4perl.appender.LOGFILE.filename'      => $PARGRAM_FULL_NAME . ".log",
        'log4perl.appender.LOGFILE.mode'          => 'append',
        'log4perl.appender.LOGFILE.size'          => 5000000,
        'log4perl.appender.LOGFILE.max'           => 1,
        'log4perl.appender.LOGFILE.layout.ConversionPattern' => '%d.%r: %F{1}[%c]:%L %-5p - %m%n'

      );

#-----
#- Initialize the Logger
#-
Log::Log4perl->init( \%log4perl_configuration );



####################################################################
# Functions
#

#===========================================
#= check_command
#=
sub check_command($$$$)
{
  my ( $command, $parm, $condition, $cache ) = @_;
  my $return_code = -1;

  my $logger = Log::Log4perl->get_logger("check_command()");
  $logger -> level( $allowed_log_levels{ $verbose } );

  #------
  #- Parse condition parameter
  #-   exit=<exit code>
  #- OR
  #-   out="output pattern"
  #-
  my %cmp_conditions;

  if ( $condition =~ /exit=(\d+)/ ) {
    $cmp_conditions{ 'exit' } = $1;
  }
  elsif ( $condition =~ /out=(.+)/ ) {
    $cmp_conditions{ 'out' } = $1;
  }
  else {
    $logger -> log( $ERROR, "The condition is not recognized '$condition'" );
    return $return_code;
  }


  #------
  #- If this command has been already checked then use the previous result
  #- if $cache is 1
  #-
  if ( $cache == 1 ) {
    $logger -> log( $DEBUG, "Cache mode it ON, lookup the hash..." );
    if ( exists $checked_commands{ $command . $parm . $condition } ) {
      $return_code = $checked_commands{ $command . $parm . $condition };
      $logger -> log( $DEBUG, "Command found in the hash. " .
                              "Will use previous result - $return_code." );
    }
    else {
      $logger -> log( $DEBUG, "Checking command for the first time. " );
      $cache = 0;
    }
  }

  if ( $cache == 0 ) {
    #------
    #- Executing Command
    #-
    $logger -> log( $DEBUG, "Executing command '$command $parm' ..." );

    my $cmd_out = `$command $parm 2>&1`;
    my $cmd_exit_code = $?;

    #------
    #- Compare actual result with the expected result
    #-
    if ( exists $cmp_conditions{ 'exit' } ) {
      if ( $cmd_exit_code == $cmp_conditions{ 'exit' } ) {
        $logger -> log( $DEBUG, "Command '$command $parm' returned expected exit code: $cmd_exit_code" );
        $return_code = 0;
      }
      else {
        $logger -> log( $WARN, "Command '$command $parm' returned unexpected exit code: $cmd_exit_code: $!" );
        $return_code = 1;
      }
    }
    if ( exists $cmp_conditions{ 'out' } ) {
      my $cmp_condition = $cmp_conditions{ 'out' };
      if ( $cmd_out =~ /$cmp_condition/ ) {
        $logger -> log( $DEBUG, "Command '$command $parm' returned expected output: $cmd_out" );
        $return_code = 0 unless ( $return_code == 1 );
      }
      else {
        $logger -> log( $WARN, "Command '$command $parm' returned unexpected output: $cmd_out" );
        $return_code = 1;
      }
    }

    #------
    #- Add result to the hash
    #-
    $checked_commands{ $command . $parm . $condition } = $return_code;
  }

  return $return_code;
}
#= END check_command()
#===========================================

