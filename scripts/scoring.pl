#!/usr/bin/perl
#
# Scoring tool for Julius
#
#   Copyright (C) 2013-2016 Sunao HARA (hara@cs.okayama-u.ac.jp)
#   Copyright (C) 2013-2016 Abe Laboratory, Okayama Univresity
#   Last Modified: 2016/12/13 12:32:45.
#
use strict;
use warnings;

## Encodings
use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

## 強制終了 トラップ
$SIG{'INT'}=$SIG{'HUP'}=$SIG{'QUIT'}=$SIG{'TERM'}=sub { print "SIGINT!!\n"; exit; };

## USAGE
sub usage {
	print STDERR $_[0] . "\n" if(@_ >= 0);
	print STDERR <<EOF;
usage:
	perl $0 res2hyp result.txt > result.hyp
	perl $0 align result.ref result.hyp > result.ali
	perl $0 score result.ali
EOF
	exit 1;
}

## 設定
my $opt = shift || "";
my $re_fileid = '(\w\d)-(\d\d)(?:\.mfc)??';

## 本処理
if($opt eq "res2hyp") {
	cmd_result2hypothesis(@ARGV);
} elsif($opt eq "align") {
	cmd_alignment(@ARGV);
} elsif($opt eq "score") {
	cmd_scoring(@ARGV);
} else {
	usage("Error: Unknown command: $opt");
}

exit 0;
##############################################

sub cmd_result2hypothesis {
	my $res_filename = shift || "result.txt";
	my $fp;

	my $cur_fileid = "";

	print STDERR $res_filename."\n";
	open $fp, "<:utf8", $res_filename or die "Error: OpenR: $res_filename\n";
	while(<$fp>) {
		s/(?:\r|\n)+$//g;
		# Julius 4.2.3
		if(/^input MFCC file: (.*)$/o) {
			my $cur_filename = $1;
			if($cur_filename =~ /$re_fileid/o) {
				$cur_fileid = $1 . "-" . "$2";
			}
			next;
		}
		if(/^sentence1: (.*)$/) {
			print join("\t", $cur_fileid, $1), "\n";
			$cur_fileid = "";
			next;
		}
	}
	close($fp);

}

sub cmd_alignment {
	my $ref_filename = shift || "result.ref";
	my $hyp_filename = shift || "result.hyp";

	my %ref_data = load_idtext($ref_filename);
	my %hyp_data = load_idtext($hyp_filename);

	foreach my $id (sort keys %hyp_data) {
		#print STDERR "DEBUG: process $id\n";

		my @refs = split(/\s+/, $ref_data{$id});
		my @hyps = split(/\s+/, $hyp_data{$id});

		# delete POS data
		@refs = map { s/\+.*//g; $_; } @refs;
		@hyps = map { s/\+.*//g; $_; } @hyps;

		# delete sil, sp, <s>, etc.
		@refs = map { s/(?:sil|sp|<\/??s>|[、。，．])//g; $_; } @refs;
		@hyps = map { s/(?:sil|sp|<\/??s>|[、。，．])//g; $_; } @hyps;

		# cleaning
		@refs = grep {$_ ne ""} @refs;
		@hyps = grep {$_ ne ""} @hyps;

		#print STDERR "DEBUG: REF: " . join(" / ", @refs) . "\n";
		#print STDERR "DEBUG: HYP: " . join(" / ", @hyps) . "\n";

		#	push @refs, "</s>";
		#push @hyps, "</s>";

		# DP matching and output results
		print $id . "\n";
		dp_align(\@refs, \@hyps);
	}
}

sub cmd_scoring {
	my $ali_filename = shift;

	my %data = load_alignment_file($ali_filename);
	my %uid_cnt = ();
	my %total_cnt = ();
	
	foreach my $id (sort keys %data) {
		my $uid = "";
		my $sid = "";
		if($id =~ /$re_fileid/o) {
			$uid = $1; $sid = $2;
		} else {
			print STDERR "WARNING: Unrecognized ID: $re_fileid: $id\n";
			next;
		}

		#print STDERR "DEBUG: $id\n";

		my $cur_data = $data{$id};

		my %cnt = ("C"=>0, "S"=>0, "D"=>0, "I"=>0);
		foreach my $ali (@{$cur_data->{'ALI'}}) {
			++$cnt{$ali};
		}

		foreach my $w ('C', 'S', 'D', 'I') {
			$uid_cnt{$uid}->{$w} += $cnt{$w};
			$total_cnt{$w} += $cnt{$w};
		}

		$uid_cnt{$uid}->{'SNT'} += 1;
		$total_cnt{'SNT'} += 1;
		if($cnt{'S'} + $cnt{'D'} + $cnt{'I'} > 0) {
			$uid_cnt{$uid}->{'SERR'} += 1;
			$total_cnt{'SERR'} += 1;
		}
	}

	# OUTPUT: Header
	print join("\t", 'UID', 'SNT', '|'), "\t";
	print join("\t", '#C', '#S', '#D', '#I', '|'), "\t";
	print join("\t", 'S.Err.', 'Err.', 'Corr', 'Acc.'), "\n"; 
	print "-" x 94 , "\n";

	# OUTPUT: Contents
	foreach my $uid (sort keys %uid_cnt) {
		my %cnt = %{$uid_cnt{$uid}};
		my @stat1 = calc_stat1(%cnt);

		print sprintf("%s", $uid) . "\t";
		print sprintf("%3d", $cnt{'SNT'}) . "\t|";
		print map {sprintf("\t%2d", $_)} @stat1[0..3];
		print "\t|";
		print map {sprintf("\t%.2f", $_)} @stat1[4..7];
		print "\n";

	}

	# OUTPUT: Footer
	print "-" x 94 , "\n";

	my @stat1 = calc_stat1(%total_cnt);
	print "TOTAL\t";
	print sprintf("%3d", $total_cnt{'SNT'}) . "\t|";
	print map {sprintf("\t%2d", $_)} @stat1[0..3];
	print "\t|";
	print map {sprintf("\t%.2f", $_)} @stat1[4..7];
	print "\n";


}

sub calc_stat1 {
	my %cnt = @_;
	my $cnt_ref = $cnt{'C'} + $cnt{'S'} + $cnt{'D'};
	my $err1    = $cnt{'S'} + $cnt{'D'};
	my $err2    = $cnt{'S'} + $cnt{'D'} + $cnt{'I'};

	my $snt_err = sprintf("%.2f", 100.0 * $cnt{'SERR'}/$cnt{'SNT'});
	my $wrd_err = sprintf("%.2f", 100.0*$err1/$cnt_ref);
	my $corr = sprintf("%.2f", 100.0 - 100.0*$err1/$cnt_ref);
	my $acc  = sprintf("%.2f", 100.0 - 100.0*$err2/$cnt_ref);

	return $cnt{'C'}, $cnt{'S'}, $cnt{'D'}, $cnt{'I'}, $snt_err, $wrd_err, $corr, $acc;
}

sub load_alignment_file {
	my $filename = shift;
	my $fh;
	my %data = ();

	open $fh, "<:utf8", $filename or die "Error: OpenR: $filename\n";
	while(<$fh>) {
		my $id = $_;
		my $ref_str = <$fh>;
		my $hyp_str = <$fh>;
		my $ali_str = <$fh>;

		$ref_str =~ s/^REF:\s+//;
		$hyp_str =~ s/^HYP:\s+//;
		$ali_str =~ s/^ALI:\s+//;

		$data{$id} = {
			'REF' => [split(/\s+/, $ref_str)],
			'HYP' => [split(/\s+/, $hyp_str)],
			'ALI' => [split(/\s+/, $ali_str)],
		}
	}
	close($fh);

	return %data;
}

sub dp_align {
	my @refs = @{$_[0]};
	my @hyps = @{$_[1]};

	my $I = @refs + 1;
	my $J = @hyps + 1;
	my @dpcost = (0) x ($I * $J);

	#print STDERR "DEBUG: REF: ", join(" / ", @refs), "\n";	
	#print STDERR "DEBUG: HYP: ", join(" / ", @hyps), "\n";	

	if(@refs == 0 || @hyps == 0) {
		print STDERR "Warning: No Reference or Hypothesis\n";
		return ;
	}

	# Initialize
	for(my $i=0; $i<$I; ++$i) {
		$dpcost[$i*$J] = $i;
	}
	for(my $j=0; $j<$J; ++$j) {
		$dpcost[$j] = $j;
	}

	for(my $i=1; $i<$I; ++$i) {
		for(my $j=1; $j<$J; ++$j) {
			# Correct
			if($refs[$i-1] eq $hyps[$j-1]) {
				$dpcost[$i*$J + $j] = $dpcost[($i-1)*$J+($j-1)];
				next;
			}

			# Insertion
			my $s1 = $dpcost[$i*$J + ($j-1)] + 1;
			# Deletion
			my $s2 = $dpcost[($i-1)*$J + $j] + 1;
			# Substitution
			my $s3 = $dpcost[($i-1)*$J + ($j-1)] + 1;

			if($s3 <= $s1) {
				if($s3 <= $s2) {
					$dpcost[$i*$J+$j] = $s3;
				} else {
					$dpcost[$i*$J+$j] = $s2;
				}
			} else {
				if($s1 <= $s2) {
					$dpcost[$i*$J+$j] = $s1;
				} else {
					$dpcost[$i*$J+$j] = $s2;
				}
			}

		}
	}


	# Debug DP matrix
	#for(my $i=0; $i<$I; ++$i) {
	#	for(my $j=0; $j<$J; ++$j) {
	#		print sprintf("%2d ", $dpcost[$i*$J+$j]);
	#	}
	#	print "\n";
	#}

	# Back trace
	my ($i,$j) = ($I-1,$J-1);
	my @dp_ref = ();
	my @dp_hyp = ();
	my @dp_res  = ();

	my $cur_cost= $dpcost[-1]; # last

	while( ($i > 0) || ($j > 0) ) {
		if($dpcost[($i)*$J+($j-1)] < $cur_cost) {
			unshift @dp_res, "I";
			unshift @dp_ref, " ";
			unshift @dp_hyp, $hyps[--$j]; #--$j;
		} elsif($dpcost[($i-1)*$J+($j)] < $cur_cost) {
			unshift @dp_res, "D";
			unshift @dp_ref, $refs[--$i]; #--$i;
			unshift @dp_hyp, " ";
		} elsif($dpcost[($i-1)*$J+($j-1)] < $cur_cost) {
			unshift @dp_res, "S";
			unshift @dp_ref, $refs[--$i];
			unshift @dp_hyp, $hyps[--$j];
		} elsif($dpcost[($i-1)*$J+($j-1)] == $cur_cost) {
			unshift @dp_res, "C";
			unshift @dp_ref, $refs[--$i]; #--$i;
			unshift @dp_hyp, $hyps[--$j]; #--$j;
		} else {
			print STDERR "$i??$j??\n";
		}
		$cur_cost = $dpcost[$i*$J+$j];
	}
	
	print join("\t", "REF:", @dp_ref), "\n";
	print join("\t", "HYP:", @dp_hyp), "\n";
	print join("\t", "ALI:", @dp_res), "\n";

}

sub load_idtext {
	my $filename = shift;
	my $fp;
	my %data = ();

	open $fp, "<:utf8", $filename or die "Error: OpenR: $filename\n";
	while(<$fp>) {
		s/(?:\r|\n)+$//g;
		my($id, $text) = split(/\s+/, $_, 2);
		$data{$id} = $text;
	}
	close($fp);

	print STDERR sprintf("Info: Load %d data from %s\n", int(keys %data), $filename);

	return %data;
}
