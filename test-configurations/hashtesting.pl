$status_file = "status.log";

%status = (
           "start_time",
           "end_time",
           "status",
           "fail_count",
           "last_success_epoch",
           "last_success_display"
          );

open  STATUSFILE, "$status_file";

@status_file_contents = <STATUSFILE>;

close STATUSFILE;

print "$status_file contents:\n";

$i = 1;

for $item (@status_file_contents) {
  chomp($item);
  $item = trim($item);
  @line = split /=/, $item;
  
  $fieldsplit{"$line[0]"} = $line[1];
  
  print "$item\n";
  $i++;
}

if ($fieldsplit{"FAIL_COUNT"} > 3) {
  print "Fail count is greater than 3\n";
}



sub trim {
    my @out = @_;
    for (@out) {
        s/^\s+//;
        s/\s+$//;
    }
    return wantarray ? @out : $out[0];
}
