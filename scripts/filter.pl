#!/usr/bin/perl

while(<>) {
	s/(\\\d\d\d)/eval("\"$1\"")/eg;
	print $_;
}

