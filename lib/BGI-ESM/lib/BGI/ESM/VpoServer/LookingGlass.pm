=head1 TITLE

LookingGlass Methods

=head1 DESCRIPTION

These methods are related to the LookingGlass program.

=head1 USAGE

use BGI::ESM::VpoServer::LookingGlass

=head1 TODO

  - Figure out what to do with the global TIE variable


=head1 REVISIONS

CVS Revision: $Revision: 1.3 $

  #####################################################################
  #  2005-10-05 - nichj - Migrated to Perl Module
  #####################################################################
 
=cut

##############################################################################
### Package Name #############################################################
package BGI::ESM::VpoServer::LookingGlass;
##############################################################################

##############################################################################
### Module Use Section #######################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type check_os);
use BGI::ESM::Common::Variables;
##############################################################################

##############################################################################
### Require Section ##########################################################
require Exporter;
##############################################################################

##############################################################################
### Who is this ##############################################################
our @ISA = qw(Exporter BGI::ESM::VpoServer);
##############################################################################

##############################################################################
### Public Exports ###########################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    looking_glass_new_vpo_event
    lg_get_db_structure
    lg_open_db
    lg_close_db
    lg_merge_records
    lg_add_record
    lg_update_record
    lg_get_record
    lg_print_all_record_keys
    lg_print_xref_all
    lg_print_xref
    lg_print_record
    lg_print_csv_all
    lg_print_csv
    lg_delete_record
    lg_vpo_to_lg
    lg_log
    
);
##############################################################################

##############################################################################
### VERSION ##################################################################
our $VERSION = (qw$Revision: 1.3 $)[-1];
##############################################################################

##############################################################################
# Public Variables
##############################################################################

our %vpo_events;

##############################################################################
# Public Methods / Functions
##############################################################################


=head2 looking_glass_new_vpo_event(\%vpo_data)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  looking_glass_new_vpo_event(\%vpo_data)
  #
  #  Purpose:  Converts vpo_data to lg_data, adds record
  #
  #  Returns:  1 if successful, 0 if problem.
  #
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub looking_glass_new_vpo_event {
    my $vpo_data_incoming = shift;
    my %lg_new_record = ();
    my $retval        = 0;
    my ($vpoid, $log_text, $lg_new_record);
    
    $vpoid            = $vpo_data_incoming->{'msgid'};
  
    $log_text         = "\n== processing $vpoid ==";
    lg_log(\$log_text);
    
    $lg_new_record    = lg_vpo_to_lg($vpo_data_incoming);  # converts the vpo data into looking glass format.
    
    $retval           = lg_add_record($vpoid, $lg_new_record);
    
    $log_text         = "\tLooking glass add record $vpoid returned $retval";
    lg_log(\$log_text);
    
    return $retval;
}

=head2 lg_get_db_structure()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function: lg_get_db_structure()
  #
  #  Purpose:  Builds a blank database structure.
  #
  #  Returns:  Reference to a hash that has the structure
  #
  #  Requires: 
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_get_db_structure {
  my ($db_structure, %db_structure);
  
  $db_structure   = {
                      v_msg_grp   => "",
                      v_node      => "",
                      v_sev       => "",
                      v_opened    => "",
                      p_ticket    => "",
                      p_cat       => "",
                      p_subcat    => "",
                      p_prod      => "",
                      p_prob      => "",
                      p_asgp      => "",
                      p_apgp      => "",
                      p_open      => "",
                      a_id        => "",
                      a_gp        => "",
                      a_open      => "",
                      a_ack       => "",
                      a_ackid     => "",
                    };

  return $db_structure;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2 lg_open_db()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function: lg_open_db()
  #
  #  Purpose:  opens the database.
  #
  #  Returns:  Sets global variables:
  #             %vpo_events which is tied to the $db_file set in lg_get_db_file
  #
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_open_db {
    my $retval = 1;
    my $log_text;
    my $dbm;
    
    # if already open
    #if ($vpo_events) { return 1; }
    #if ($dbm)        { return 1; }
    
    my $db_file = lg_get_db_file();
    
    if (not -e $db_file) {
      
      $dbm = tie %vpo_events, 'MLDBM', $db_file, O_CREAT|O_RDWR, 0640 or die $!;
      
    } else {
      
      $dbm = tie %vpo_events, 'MLDBM', $db_file or die $!;
    }
    
    return 1;
  
    #############################
    #### Subfunction ############
    #############################
    sub lg_get_db_file {
      my $db_file = "$PGM_ROOT/vpoevents";
    
      return $db_file;
    
    }

}

=head2 lg_close_db()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function: lg_close_db()
  #
  #  Purpose:  closes the database by untying the variable
  #
  #  Returns:  
  #            
  #
  #  Requires: 
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_close_db {
    my $retval = 1;
    
    untie %vpo_events;
    
    return $retval;
  
}

=head2 lg_merge_records(\%existing_hash, \%hash_with_new_vals)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_merge_records(\%existing_hash, \%hash_with_new_vals)
  #
  #  Purpose:  takes the existing hash and adds values in hash_with_new_vals
  #            NOTE: values in the hash_with_new_vals will overwrite any in existing_hash
  #
  #  Returns:  reference to the udpated hash
  #            
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_merge_records {
    my $existing_hash = shift;
    my $hash_to_merge = shift;
    my %merged        = ();
  
    while ( my ($k,$v) = each(%{$existing_hash}) ) {
        $merged{$k} = $v;
    }
    while ( my ($k,$v) = each(%{$hash_to_merge}) ) {
        $merged{$k} = $v;
    }  
    
    return \%merged;
  
}

=head2 lg_add_record($record_key, \%db_hash)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_add_record(\%db_hash)
  #
  #  Purpose:  Takes the incoming hash and adds it to the database hash
  #
  #  Returns:  1 if successful, 0 if fails, 2 if already exists
  #            
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_add_record ($$) {
  my $record_key = shift;
  my $db_hash    = shift;
  my $retval     = 0;
  my ($log_text, $record);
  
  if ( (not $record_key) || (not db_hash) ) {
    print "lg_add_record ERROR: record_key and/or db_hash must not be blank!\n";
    return $retval;
  }
  
  if (lg_open_db()) {
    
    if (not exists $vpo_events{$record_key}) {
      
      $vpo_events{$record_key} = $db_hash;
      
      $log_text = "\tDB key = $vpo_events{$record_key}\n";
      $log_text = $log_text . "\tAdded to database: $record_key";
      lg_log(\$log_text);
      lg_log($vpo_events{$record_key});
      lg_log($db_hash);
      
      $retval   = 1;
      
    } else {
      
      print "Error: It appears $record already exists.\n";

      $log_text = "\tIt appears $record aready exists.";
      lg_log(\$log_text);

      $retval = 2;
      
    }
    
    lg_close_db();

  } else {
    
    print "Unable to open database: $!\n";
    $retval = 0;
    
  }
  
  
  return $retval;
  
}

=head2 lg_udpate_record($record_key, \%update_hash)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_update_record($record_key, \%update_hash)
  #
  #  Purpose:  Looks up the existing record (based on record_key), stores its values in a temporary
  #             hash, merges the existing record and the %update_hash,
  #             deletes the existing record, then adds the record to the database.
  #
  #  Returns:  1 if successful, 0 if fails
  #            
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_update_record {
  my $record_key     = shift;
  my $updated_record = shift;
  my $retval         = 0;
  my ($existing_hash, $updated_hash, $log_text);
  
  if ( (not $record_key) || (not db_hash) ) {
    print "lg_add_record ERROR: record_key and/or db_hash must not be blank!\n";
    return $retval;
  }
  
  if (lg_open_db()) {
    
    if (exists $vpo_events{$record_key}) {
      
      $existing_hash = lg_get_record($record_key);
      
      $updated_hash  = lg_merge_records($existing_hash, $updated_record);
      
      $log_text = "\tupdating $record_key with the following values:";
      lg_log(\$log_text);
      lg_log($updated_hash);
      
      ##
      ## We have the existing record merged with the updated information.
      ##
  
      if (lg_delete_record($record_key)) {
        
        if (lg_add_record($record_key, $updated_hash)) {
          
          $retval = 1;

        } else {
          
          print "Error! problem adding record $record_key\n";
          $retval = 0;
          
        }

      } else {
        
        print "Error! problem deleting record $record_key\n";
        $retval = 0;
        
      }
      
    } else {
      
      print "lg_update_record: The record doesn't exist!\n";
      
    }
    
    lg_close_db();
    
  } else {
    
    print "Unable to open database: $!\n";
    $retval = 0;
    
  }
  
}


=head2 lg_get_record($vpoid)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_get_record($vpoid)
  #
  #  Purpose:  Looks up the existing record based on $vpoid, retrieves the associated hash
  #            into a temporary hash
  #
  #  Returns:  A reference to the temporary hash
  #            
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_get_record {
    my $record_key = shift;
    my ($temp_hash, %temp_hash);
    
    if ( exists $vpo_events{$record_key} ) {
      $temp_hash = $vpo_events{$record_key};
    } else {
      $temp_hash = 0;
    }
    
    return $temp_hash;
  
}

=head2 lg_print_all_record_keys()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_print_all_record_keys()
  #
  #  Purpose:  prints all keys for the db file
  #
  #  Returns:  n/a
  #            
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_print_all_record_keys {
    my $log_text;
    
    if (lg_open_db()) {
      
      for my $key (sort keys %vpo_events) {
        print "$key\n";
      }
      
      if (lg_close_db()) {

      }
      
    }
    else {
      
      print "Error: unable to open db file: $!\n";
      
    }
  
    return 1;
}

=head2 lg_print_xref_all()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_print_xref_all()
  #
  #  Purpose:  prints all record's vpoid and ticket number
  #
  #  Returns:  n/a
  #            
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_print_xref_all {
    my $log_text;
    
    if (lg_open_db()) {
      
      for my $key (sort keys %vpo_events) {
        print "$key " . $vpo_events{$key}{'p_ticket'} . "\n";
      }
      
      if (lg_close_db()) {

      }
      
    }
    else {
      
      print "Error: unable to open db file: $!\n";
      
    }
  
    return 1;
}

=head2 lg_print_xref_all()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_print_xref($record_key)
  #
  #  Purpose:  prints specific record's vpoid and ticket number
  #
  #  Returns:  n/a
  #            
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_print_xref {
    my $log_text;
    my $record_key = shift;
    my $retval;
    
    if ( (not $record_key) ) {
      print "lg_print_record ERROR: record_key must not be blank!\n";
      return $retval;
    }
  
    if (lg_open_db()) {
      
      if (exists $vpo_events{$record_key}) {
        print $record_key . " " . $vpo_events{$record_key}{'p_ticket'} . "\n";
      } else {
        print "Error: It appears $record_key doesn't exist.\n";
        $retval = 2;
      }
      
      if (lg_close_db()) {

      }
      
    }
    else {
      
      print "Error: unable to open db file: $!\n";
      
    }
  
    return 1;
}


=head2 lg_print_record($record_key)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_print_record($record_key)
  #
  #  Purpose:  prints the values associated with the $record_key
  #
  #  Returns:  1 if successful, 2 if not found, 0 if problem
  #            
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_print_record {
    my $record_key = shift;
    my $retval     = 0;
    
    if ( (not $record_key) ) {
      print "lg_print_record ERROR: record_key must not be blank!\n";
      return $retval;
    }
    
    if (lg_open_db()) {
      
      if (exists $vpo_events{$record_key}) {
        
        print "Record key: " . $record_key . "\n";
        lg_print_record_details($vpo_events{$record_key});
        $retval = 1;
        
      } else {
        
        print "Error: It appears $record_key doesn't exist.\n";
        $retval = 2;
        
      }
      
      lg_close_db();
  
    } else {
      
      print "Unable to open database: $!\n";
      $retval = 0;
      
    }
    
    return $retval;
    
    ###############################################################
    ### Subfunction: lg_print_record_details($record_reference) ###
    ###############################################################
    sub lg_print_record_details ($) {
      my $record_ref = shift;
      my $retval     = 1;
      
      for my $key (sort keys %{$record_ref}) {
        print "\t$key == " . $record_ref->{$key} . "\n";
      }
      
      return $retval;
      
    }

}

=head2 lg_print_csv_all()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_print_csv_all()
  #
  #  Purpose:  print all records in cvs format
  #
  #  Returns:  1 if successful, 2 if not found, 0 if problem
  #            
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_print_csv_all {
    my $log_text;
    my $pre_q  = "\"";
    my $post_q = "\",";
    
    if (lg_open_db()) {
    

    print $pre_q . "v_msg_id"    . $post_q .
          $pre_q . "v_app_name"  . $post_q .
          $pre_q . "v_node"      . $post_q .
          $pre_q . "v_severity"  . $post_q .
          $pre_q . "v_opened"    . $post_q .
          $pre_q . "p_ticket"    . $post_q .
          $pre_q . "p_category"  . $post_q .
          $pre_q . "p_subcat"    . $post_q .
          $pre_q . "p_product"   . $post_q .
          $pre_q . "p_problem"   . $post_q .
          $pre_q . "p_assgn_grp" . $post_q .
          $pre_q . "p_ap_grp"    . $post_q .
          $pre_q . "p_open"      . $post_q .
          "\n";

    
    for my $key (sort keys %vpo_events) {
      print $pre_q . $key                                 . $post_q .
            $pre_q . trim($vpo_events{$key}{'v_msg_grp'}) . $post_q .
            $pre_q . trim($vpo_events{$key}{'v_node'})    . $post_q .
            $pre_q . trim($vpo_events{$key}{'v_sev'})     . $post_q .
            $pre_q . trim($vpo_events{$key}{'v_opened'})  . $post_q .
            $pre_q . trim($vpo_events{$key}{'p_ticket'})  . $post_q .
            $pre_q . trim($vpo_events{$key}{'p_cat'})     . $post_q .
            $pre_q . trim($vpo_events{$key}{'p_subcat'})  . $post_q .
            $pre_q . trim($vpo_events{$key}{'p_prod'})    . $post_q .
            $pre_q . trim($vpo_events{$key}{'p_prob'})    . $post_q .
            $pre_q . trim($vpo_events{$key}{'p_asgp'})    . $post_q .
            $pre_q . trim($vpo_events{$key}{'p_apgp'})    . $post_q .
            $pre_q . trim($vpo_events{$key}{'p_open'})    . $pre_q  .
            "\n";

      }
      
      if (lg_close_db()) {

      }
      
    }
    else {
      
      print "Error: unable to open db file: $!\n";
      
    }
  
    return 1;
    
  
}

=head2 lg_print_csv_all()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_print_csv_all()
  #
  #  Purpose:  print all records in cvs format
  #
  #  Returns:  1 if successful, 2 if not found, 0 if problem
  #            
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_print_csv {
  my $record_key = shift;
  my $log_text;
  my $pre_q      = "\"";
  my $post_q     = "\",";
  
  if (lg_open_db()) {
    
    print $pre_q . "v_msg_id"    . $post_q .
          $pre_q . "v_app_name"  . $post_q .
          $pre_q . "v_node"      . $post_q .
          $pre_q . "v_severity"  . $post_q .
          $pre_q . "v_opened"    . $post_q .
          $pre_q . "p_ticket"    . $post_q .
          $pre_q . "p_category"  . $post_q .
          $pre_q . "p_subcat"    . $post_q .
          $pre_q . "p_product"   . $post_q .
          $pre_q . "p_problem"   . $post_q .
          $pre_q . "p_assgn_grp" . $post_q .
          $pre_q . "p_ap_grp"    . $post_q .
          $pre_q . "p_open"      . $post_q .
          "\n";

    print $pre_q . $record_key                           . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'v_msg_grp'}) . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'v_node'})    . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'v_sev'})     . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'v_opened'})  . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'p_ticket'})  . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'p_cat'})     . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'p_subcat'})  . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'p_prod'})    . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'p_prob'})    . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'p_asgp'})    . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'p_apgp'})    . $post_q .
          $pre_q . trim($vpo_events{$record_key}{'p_open'})    . $pre_q  .
          "\n";
    
    if (lg_close_db()) {

    }
    
  }
  else {
    
    print "Error: unable to open db file: $!\n";
    
  }

  return 1;
  
}

=head2 lg_delete_record($record_key)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_delete_record($record_key)
  #
  #  Purpose:  delete record from database
  #
  #  Returns:  1 if successful, 2 if not found, 0 if problem
  #            
  #  Requires: MLDBM
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_delete_record {
    my $record_key = shift;
    my $retval     = 0;
    
    if (not $record_key) {
      print "Error! in lg_delete_record record_key my be defined!\n";
      return $retval;
    }
    
    if (lg_open_db()) {
      
      if (exists $vpo_events{$record_key}) {
        
        delete $vpo_events{$record_key};
        $retval = 1;
        
      } else {
        
        print "$record_key doesn't exist\n";
        $retval = 2;
        
      }
      
    } else {
      
      print "Error! unable to open database\n";
      $retval = 0;
      
    }
  
    
    return $retval;

}

=head2 lg_vpo_to_lg(\%vpo_data_hash)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_vpo_to_lg(\%vpo_data_hash)
  #
  #  Purpose:  Converts vpo data structure to new looking glass data structure
  #
  #  Returns:  reference to temp hash with lg data structure
  #            
  #  Requires: 
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------
  
=cut

sub lg_vpo_to_lg {
  my $vpo_structure   = shift;
  my $lg_db_structure = lg_get_db_structure();
  my $vpo_opened_dt;
  
  # VPO data structure
  #%vpo_data = (
  #             'message_group'      => $vpo_message_group          ,
  #             'node'               => strip_domain($vpo_nodename) ,
  #             'cma'                => $vpo_cma                    ,
  #             'message_text'       => $vpo_message                ,
  #             'msgid'              => $vpo_msgid                  ,
  #             'node_type'          => $vpo_nodetype               ,
  #             'event_date_node'    => $vpo_event_date_node        ,
  #             'event_time_node'    => $vpo_event_time_node        ,
  #             'event_date_mgmtsvr' => $vpo_event_date_mgmtsvr     ,
  #             'event_time_mgmtsvr' => $vpo_event_time_mgmtsvr     ,
  #             'appl'               => $vpo_appl                   ,
  #             'obj'                => $vpo_obj                    ,
  #             'severity'           => $vpo_severity               ,
  #             'operators'          => $vpo_operators              ,
  #             'instruction_text'   => $vpo_instruction_text
  #            );

  #$lg_db_structure   = {
  #                    v_msg_grp   => "",
  #                    v_node      => "",
  #                    v_sev       => "",
  #                    v_opened    => "",
  #                    p_ticket    => "",
  #                    p_cat       => "",
  #                    p_subcat    => "",
  #                    p_prod      => "",
  #                    p_prob      => "",
  #                    p_asgp      => "",
  #                    p_apgp      => "",
  #                    p_open      => "",
  #                    a_id        => "",
  #                    a_gp        => "",
  #                    a_open      => "",
  #                    a_ack       => "",
  #                    a_ackid     => "",
  #                  };
  #
  
    $vpo_opened_dt = $vpo_structure->{'event_date_mgmtsvr'} . " " . $vpo_structure->{'event_time_mgmtsvr'};
  
    $lg_db_structure->{'v_msg_grp'} = $vpo_structure->{'message_group'};
    $lg_db_structure->{'v_node'}    = $vpo_structure->{'node'};
    $lg_db_structure->{'v_sev'}     = $vpo_structure->{'severity'};
    $lg_db_structure->{'v_opened'}  = $vpo_opened_dt;
    
    return $lg_db_structure;
  
}

=head2 lg_log(\$reference_to_print)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  lg_log(\$reference_to_print)
  #
  #  Purpose:  Tests for reference of HASH and prints formatted hash to a file.
  #
  #  Returns:  
  #            
  #  Requires: 
  #
  #  Issues/Enhancements:
  #            Any possible enhancements that might make this function better
  #
  # -------------------------------------------------------------------

=cut

sub lg_log {
    my $lg_log_file   = "$PGM_LOGS/looking_glass.log";
    my $to_print      = shift;
    my $item;
    
    if (not -e $lg_log_file) {
      open LG_LOG, "> $lg_log_file"  || warn "Unable to open $lg_log_file: $!\n";
    } else {
      open LG_LOG, ">> $lg_log_file" || warn "Unable to open $lg_log_file: $!\n";
    }
  
    if (ref($to_print) eq "HASH") {
      
      print_hash_formatted_file(LG_LOG, \%{$to_print});
      
    } elsif (ref($to_print) eq "ARRAY") {
  
      foreach $item (@{$to_print}) {
        print LG_LOG "$item\n";
      }
      
    } else {
      
      print LG_LOG "${$to_print}\n";
      
    }
    
    close LG_LOG;

}

##############################################################################
### End of Public Methods / Functions ########################################
##############################################################################

##############################################################################
### Private Methods / Functions ##############################################
##############################################################################






##############################################################################
### End of Private Methods / Functions #######################################
##############################################################################

##############################################################################
# Do not change this.  Required for successful require load
1;
##############################################################################

__END__

=head2 DEVELOPER'S NOTES
 

=cut

