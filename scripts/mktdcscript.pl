#!/usr/bin/perl
# -*- encoding: utf-8 -*-

use strict;
use warnings;

my $th = (shift || 100);
my $statfile = (shift || 'stats');
my $monophones = 'config/monophones';

print qq|RO 10.0 "$statfile"\n\n|;
print <DATA>; # DATAの中身はスクリプト末尾参照
print qq|\nUF macro\n\n|;

my $fh;
open $fh, "<", $monophones or die "Error: OpenR: $monophones";
while(my $ph = <$fh>) {
	chomp $ph;
	next if($ph eq "");
	foreach my $n (2,3,4) {
		print qq|TB $th "TC_$ph$n" {("$ph","*-$ph+*","*-$ph","$ph+*").state[$n]}\n|;
	}
}
close($fh);

print qq|\n|;
print qq|AU "new_logical_triphones"\n|;
print qq|CO "tied_triphones"\n|;
print qq|ST "model/tree"\n|;

exit 0;
#####################################################
__DATA__
QS "L_Nasal"   { N-*,n-*,m-* }
QS "R_Nasal"   { *+N,*+n,*+m }

QS "L_Bilabial"       { p-*,b-*,f-*,m-*,w-* }
QS "R_Bilabial"       { *+p,*+b,*+f,*+m,*+w }

QS "L_DeltalAlveolar" { t-*,d-*,ts-*,z-*,s-*,n-* }
QS "R_DeltalAlveolar" { *+t,*+d,*+ts,*+z,*+s,*+n }

QS "L_PalatoAlveolar"  { ch-*,j-*,sh-* } 
QS "R_PalatoAlveolar"  { *+ch,*+j,*+sh } 

QS "L_Velar"          { k-*,g-* }
QS "R_Velar"          { *+k,*+g }

QS "L_Glottal"        { h-* }
QS "R_Glottal"        { *+h }

QS "L_YOUON"      { y-* }

QS "L_SOKUON"     { q-* }
QS "R_SOKUON"     { *+q }

QS "L_R"          { r-* }
QS "R_R"          { *+r }

QS "L_N"          { N-* }
QS "R_N"          { *+N }

QS "L_A"          { a-* }
QS "R_A"          { *+a }
QS "L_I"          { i-* }
QS "R_I"          { *+i }
QS "L_U"          { u-* }
QS "R_U"          { *+u }
QS "L_E"          { e-* }
QS "R_E"          { *+e }
QS "L_O"          { o-* }
QS "R_O"          { *+o }
