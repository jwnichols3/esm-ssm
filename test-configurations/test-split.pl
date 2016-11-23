

$cma = "netiq_sev=17;;netiq_server=calntmgt001";


@cma_fields = split /;;/, $cma;

foreach $cma_field (@cma_fields) {
  print "$cma_field\n";
  push @cma_value_pair, split /=/, $cma_field;
}

foreach $cma_value (@cma_value_pair) {
  print "$cma_value\n";
}

%cma_value_hash = @cma_value_pair;

print $cma_value_hash{'netiq_sev'};

