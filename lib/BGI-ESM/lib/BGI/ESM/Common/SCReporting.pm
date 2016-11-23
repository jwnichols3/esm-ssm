
=head1 NAME

BGI ESM Common ServiceCenter Reporting modules

=head1 SYNOPSIS

This library is used BGI ESM programs that want to use ServicCenter reporting.

=head1 REVISIONS

CVS Revision: $Revision: 1.1 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2007-04-25   nichj   Getting initial release done
  #
  #####################################################################

=head1 TODO


=cut


#################################################################################
### Package Name ################################################################
package BGI::ESM::Common::SCReporting;
#################################################################################

#################################################################################
### Module Use Section ##########################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Time::localtime;
#################################################################################

#################################################################################
### Require Section #############################################################
require Exporter;
#################################################################################

#################################################################################
### Who is this #################################################################
our @ISA = qw(Exporter BGI::ESM::Common);
#################################################################################

#################################################################################
### Public Exports ##############################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    get_sc_search_url
    format_sc_date
);
#################################################################################

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.1 $)[-1];
#################################################################################

#################################################################################
### CONSTANTS #####################################################################
our $SC_BASE_URL = "http://csm/display/incidents_results.cfm";
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################

=head2 get_sc_search_url({ severity=><1,2,3,4,5,all>, start_date=><start_date>, end_date=><end_date> })

    returns a URL for use in SC
=cut

sub get_sc_search_url {
	my ($arg_ref) = @_;
    
    my $sev          = _not_blank($arg_ref->{severity});
    my $start_date   = _not_blank($arg_ref->{start_date});
    my $end_date     = _not_blank($arg_ref->{end_date});
    
	my $url = $SC_BASE_URL . "?" . 
		"display_mode=count&save_as_name=VPO+Generated+Tickets+%28All%29" . '&' .
		"Count=Count+Only&maxrecords=14000" . '&' .
		"flag=" . '&' .
		"includebox=open_time+as+columnorder004_open_time" . '&' .
		"open_time=BET" . '&' .
		"date_opened_first_dt=${start_date}" . '&' .
		"date_opened_second_dt=${end_date}" . '&' .
		"close_time=ALL" . '&' .
		"date_closed_first_dt=" . '&' .
		"date_closed_second_dt=" . '&' .
		"update_time=ALL" . '&' .
		"date_last_updated_first_dt=" . '&' .
		"date_last_updated_second_dt=" . '&' .
		"contact_name=VPO" . '&' .
		"dept=ALL" . '&' .
		"contact_location=ALL" . '&' .
		"mrc=ALL" . '&' .
		"edit_field=Type+MRC" . '&' .
		"vip=" . '&' .
		"assignment=ALL" . '&' .
		"assignee_name=ALL" . '&' .
		"ticket_owner=ALL" . '&' .
		"edit_field=Type+MRC" . '&' .
		"opened_by=ALL" . '&' .
		"edit_field=Type+MRC" . '&' .
		"Severity=${sev}" . '&' .
		"status=ALL" . '&' .
		"category=ALL" . '&' .
		"subcategory=ALL" . '&' .
		"edit_field=Type+MRC" . '&' .
		"Product_Type=ALL" . '&' .
		"edit_field=Type+MRC" . '&' .
		"Problem_Type=ALL" . '&' .
		"closed_by=ALL" . '&' .
		"edit_field=Type+MRC" . '&' .
		"resolution_mins=" . '&' .
		"number=" . '&' .
		"sort=number" . '&' .
		"brief_description=" . '&' .
		"bd_search=All" . '&' .
		"action=" . '&' .
		"desc_search=All" . '&' .
		"update_action=" . '&' .
		"ca_search=All" . '&' .
		"resolution=" . '&' .
		"res_search=All" . '&' .
		"survey_question_1=ALL" . '&' .
		"survey_join_1=OR" . '&' .
		"survey_question_2=ALL" . '&' .
		"survey_join_2=OR" . '&' .
		"survey_question_3=ALL" . '&' .
		"survey_join_3=OR" . '&' .
		"survey_question_4=ALL" . '&' .
		"survey_join_4=OR" . '&' .
		"survey_question_5=ALL" . '&' .
		"survey_comments=" . '&' .
		"survey_search=All";

    return $url;
}

=head2 format_sc_date({ time_in_epoch=><time_in_epoch> })

    returns a date suitable for SC URL
    
    Mmm+dd+yyyy
    
=cut

sub format_sc_date {
	my ($arg_ref) = @_;
    
    my $time_in_epoch = _not_blank($arg_ref->{time_in_epoch});
    
	my $ctm = ctime($time_in_epoch);
	
    my @tm = split / /, $ctm;
    
    my $retval = "$tm[1]+$tm[2]+$tm[4]";
    
    return $retval;
}

######################################################################
#
# Breakdown of the URI:
#http://csm/display/incidents_results.cfm?save_as_type=INCIDENT&
#display_mode=count&
#save_as_name=VPO+Generated+Tickets+%28All%29&
#Count=Count+Only&
#maxrecords=14000&
#flag=&
#includebox=open_time+as+columnorder004_open_time&
#open_time=BET&
#date_opened_first_dt=Apr+1+2007&
#date_opened_second_dt=Apr+15+2007&
#close_time=ALL&
#date_closed_first_dt=&
#date_closed_second_dt=&
#update_time=ALL&
#date_last_updated_first_dt=&
#date_last_updated_second_dt=&
#contact_name=VPO&
#dept=ALL&
#contact_location=ALL&
#mrc=ALL&
#edit_field=Type+MRC&
#vip=&
#assignment=ALL&
#assignee_name=ALL&
#ticket_owner=ALL&
#edit_field=Type+MRC&
#opened_by=ALL&
#edit_field=Type+MRC&
#Severity=ALL&
#status=ALL&
#category=ALL&
#subcategory=ALL&
#edit_field=Type+MRC&
#Product_Type=ALL&
#edit_field=Type+MRC&
#Problem_Type=ALL&
#closed_by=ALL&
#edit_field=Type+MRC&
#resolution_mins=&
#number=&
#sort=number&
#brief_description=&
#bd_search=All&
#action=&
#desc_search=All&
#update_action=&
#ca_search=All&
#resolution=&
#res_search=All&
#survey_question_1=ALL&
#survey_join_1=OR&
#survey_question_2=ALL&
#survey_join_2=OR&
#survey_question_3=ALL&
#survey_join_3=OR&
#survey_question_4=ALL&
#survey_join_4=OR&
#survey_question_5=ALL&
#survey_comments=&
#survey_search=All

#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################


=head2 _not_blank

=cut

sub _not_blank{
    my ($var_to_check) = @_;
    
    if (not $var_to_check) {
        croak "Error: Variable must be set.";
    }
    
    return $var_to_check;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


1;