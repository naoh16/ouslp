#!/usr/bin/perl
# -*- encoding: utf-8 -*-

use strict;
use warnings;

my $statfile = (shift || 'stats');
my $mixnum   = (shift || 2);

print qq|LS $statfile\n|;
print qq|MU $mixnum {*.state[2-4].mix}\n|;

exit 0;
