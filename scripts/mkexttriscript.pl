#!/usr/bin/perl
# -*- encoding: utf-8 -*-

use strict;
use warnings;

my $treefile   = (shift || 'model/tree');
my $tmphmmlist = (shift || 'tmp_tied_triphones');
my $exthmmlist = (shift || 'ext_tied_triphones');

print qq|LT $treefile\n|;
print qq|AU $tmphmmlist\n|;
print qq|CO $exthmmlist\n|;

exit 0;
