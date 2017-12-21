#!/usr/bin/perl
# -*- encoding: utf-8 -*-

use strict;
use warnings;

my $base_triphones = shift;
my $ext_triphones  = shift;

my %phones = ();

load_triphones(\%phones, $base_triphones);
load_triphones(\%phones, $ext_triphones);

foreach my $k (sort keys %phones) {
	if($k ne $phones{$k}) {
		print join(" ", $k, $phones{$k}) . "\n";
	} else {
		print $k . "\n";
	}
}

exit 0;

sub load_triphones {
	my $ref_phones   = shift;
	my $filename = shift;
	my $fh;

	open $fh, "<", $filename or die "Error: OpenR: $filename";
	while(<$fh>) {
		chomp;
		my @p = split(/\s+/, $_, 2);
		my $ph = pop @p;
		my $lg = (pop @p) || $ph;
#		print join(" ", $lg, $ph)."\n";
		$ref_phones->{$lg} = $ph;# unless(exists($ref_phones->{$ph}));
	}
	close($fh);
}
