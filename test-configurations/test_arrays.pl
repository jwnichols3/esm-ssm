


@array1 = qw/calnt001 calnt002 calnt003 calnt004 calnt005 calnt006 calnt007 calnt008 calnt009 calnt010/;
@array2 = qw/calnt001                            Calnt005                                     calnt010 calnt011 calnt012/;

print_array(\@array1);
print_array(\@array2);

@matchingcs    = sort(matching_entries_in_arrays(\@array1, \@array2, "yes"));
print            "\nMatching entries, case sensitive\n";
print_array(@matchingcs);

@matching      = sort(matching_entries_in_arrays(\@array1, \@array2, ""));
print "\nMatching entries, case insensitive\n";
print_array(@matching);


@nonmatchingcs = sort(nonmatching_entries_in_arrays(\@array1, \@array2, "yes"));
print "\nNonmatching entries, case sensitive\n";
print_array(@nonmatchingcs);

@nonmatching   = sort(nonmatching_entries_in_arrays(\@array1, \@array2, ""));
print "\nNonmatching entries, case insensitive\n";
print_array(@nonmatching);


@array_exclusion   = sort(remove_array_from_array(\@array1, \@array2, ""));
@array_exclusioncs = sort(remove_array_from_array(\@array1, \@array2, "yes"));

print "\nArray exclusion, not case sensitive\n";
print_array(@array_exclusion);

print "\nArray exclusion, case sensitive\n";
print_array(@array_exclusioncs);


print "\n\n\n";

@union_array     = sort(array_union_diff_intersect(\@array1, \@array2, "union"    ));
@diff_array      = sort(array_union_diff_intersect(\@array1, \@array2, "diff"     ));
@intersect_array = sort(array_union_diff_intersect(\@array1, \@array2, "intersect"));


print "\nRound 2: union\n";
print_array(sort(@union_array));

print "\nRound 2: difference\n";
print_array(sort(@diff_array));

print "\nRound 2: intersect\n";
print_array(sort(@intersect_array));


exit 0;


sub matching_entries_in_arrays (@@$) {
  my (@array1, @array2);
  my $array1 = $_[0];
  my $array2 = $_[1];
  my $case   = $_[2];
  my @intersect_array;

  @array1    = @$array1;
  @array2    = @$array2;
  
  #######
  # Lower case arrays if not case sensitive (default behavior)
  #######
  if ( lc $case eq "no" || not $case ) {
    @array1 = lc_array(@array1);
    @array2 = lc_array(@array2);
  }
  
  @intersect_array = sort(array_union_diff_intersect(\@array1, \@array2, "intersect"));
  
  return @intersect_array;
  
}


sub nonmatching_entries_in_arrays (@@$) {
  my (@array1, @array2);

  my $array1 = $_[0];
  my $array2 = $_[1];
  my $case   = $_[2];
  my @diff_array;

  @array1    = @$array1;
  @array2    = @$array2;
  
  #######
  # Lower case arrays if not case sensitive (default behavior)
  #######
  if ( lc $case eq "no" || not $case ) {
    @array1 = lc_array(@array1);
    @array2 = lc_array(@array2);
  }
  
  @diff_array      = sort(array_union_diff_intersect(\@array1, \@array2, "diff"     ));
  
}

sub remove_array_from_array (@@$) {
  my (@array1, @array2);
  my $array1 = $_[0];
  my $array2 = $_[1];
  my $case   = $_[2];
  my (@full_union_array, @final_diff_array);

  @array1    = @$array1;
  @array2    = @$array2;
  
  #######
  # Lower case arrays if not case sensitive (default behavior)
  #######
  if ( lc $case eq "no" || not $case ) {
    @array1 = lc_array(@array1);
    @array2 = lc_array(@array2);
  }
  
  @full_union_array = sort(array_union_diff_intersect(\@array1, \@array2, "union"));
  @final_diff_array = sort(array_union_diff_intersect(\@full_union_array, \@array2, "diff"));
  
  return @final_diff_array;
}


##
## Pulled from http://perl.active-venture.com/pod/perlfaq4-dataarrays.html
##
sub array_union_diff_intersect {
  my (@array1, @array2);
  my $array1 = $_[0];
  my $array2 = $_[1];
  my $type   = lc $_[2];
  my ($element, %count);

  @array1    = @$array1;
  @array2    = @$array2;
  
  my (@union, @intersection, @difference);
  my $element;
  my %count = ();

  foreach $element (@array1, @array2) { $count{$element}++ }

  foreach $element (keys %count) {

  	push @union, $element;
  	push @{ $count{$element} > 1 ? \@intersection : \@difference }, $element;
    
  }
  
  if    ( $type =~ /^u/     ) { return @union        }
  elsif ( $type =~ /^i/     ) { return @intersection }
  elsif ( $type =~ /^d/     ) { return @difference   }
  else                        { return 0;            }
  
}


# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: print_array(@array)
#  prints the array line by line.
# -------------------------------------------------------------------
sub print_array {
   my @incoming_array = @_;
   my $line           = "";
   
   foreach $line (@incoming_array) {
      chomp($line);
      print "$line\n";
   }
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: lc_array(@array_name)
#
# This returns an array with the elements lowercased.
#  
# -------------------------------------------------------------------
sub lc_array {
    my @incoming_array = @_;
    my ($item, $lc_item, @outgoing_array);
    
    foreach $item (@incoming_array) {
        $lc_item = lc $item;
        push @outgoing_array, $lc_item;
    }
    
    return @outgoing_array;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

