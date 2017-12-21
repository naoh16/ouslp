#!/usr/bin/perl
#
# 三つ組みの単語リストを元にHTKDICを生成するライブラリ。
#
# Original: phoneme_util.pl
#   Copyright (C) 2013 Sunao Hara, Okayama Univ.
#   Copyright (C) 2006-2011 Sunao Hara, Nagoya Univ.
#   Last modified: 2013/09/11 17:04:08.
#

# 定番のおまじない
use strict;
use warnings;

use utf8;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';
binmode STDIN, ':utf8';

##
## 設定
##

my %kana2phone_table1 = (
	'ァ' => 'a',    'ィ' => 'i',    'ゥ' => 'u',    'ェ' => 'e',    'ォ' => 'o', 
	'ア' => 'a',    'イ' => 'i',    'ウ' => 'u',    'エ' => 'e',    'オ' => 'o',
	'カ' => 'k a',  'キ' => 'k i',  'ク' => 'k u',  'ケ' => 'k e',  'コ' => 'k o',
	'ガ' => 'g a',  'ギ' => 'g i',  'グ' => 'g u',  'ゲ' => 'g e',  'ゴ' => 'g o',
	'サ' => 's a',  'シ' => 'sh i',  'ス' => 's u',  'セ' => 's e',  'ソ' => 's o',
	'ザ' => 'z a',  'ジ' => 'j i',  'ズ' => 'z u',  'ゼ' => 'z e',  'ゾ' => 'z o',
	'タ' => 't a',  'チ' => 'ch i', 'ツ' => 'ts u', 'テ' => 't e',  'ト' => 't o',
	'ダ' => 'd a',  'ヂ' => 'j i',  'ヅ' => 'z u',  'デ' => 'd e',  'ド' => 'd o',
	'ナ' => 'n a',  'ニ' => 'n i',  'ヌ' => 'n u',  'ネ' => 'n e',  'ノ' => 'n o',
	'ハ' => 'h a',  'ヒ' => 'h i',  'フ' => 'f u',  'ヘ' => 'h e',  'ホ' => 'h o',
	'バ' => 'b a',  'ビ' => 'b i',  'ブ' => 'b u',  'ベ' => 'b e',  'ボ' => 'b o',
	'パ' => 'p a',  'ピ' => 'p i',  'プ' => 'p u',  'ペ' => 'p e',  'ポ' => 'p o',
	'マ' => 'm a',  'ミ' => 'm i',  'ム' => 'm u',  'メ' => 'm e',  'モ' => 'm o',
	'ヤ' => 'y a',                  'ユ' => 'y u',                  'ヨ' => 'y o',
	'ャ' => 'y a',                  'ュ' => 'y u',                  'ョ' => 'y o',
	'ラ' => 'r a',  'リ' => 'r i',  'ル' => 'r u',  'レ' => 'r e',  'ロ' => 'r o',
	'ワ' => 'w a',  'ヰ' => 'i'  ,                  'ヱ' => 'e',    'ヲ' => 'o',
	'ヴ' => 'b u',
	'ン' => 'N', 'ッ' => 'q',
	'ー' => ':',   '―' => ':', '‐' => ':', '-' => ':', '～' => ':',
	'・' => '', '「' => '', '」' => '', '”' => '', '。' => '', '、' => 'sp', '，' => 'sp',
	'二' => 'n i', '&' => 'a N d o'
);

my %kana2phone_table2 = (
	'キャ' => 'ky a',             'キュ' =>'ky u',            'キョ'=>'ky o',
	'ギャ' => 'gy a',             'ギュ' =>'gy u',            'ギョ'=>'gy o',
	'クゥ' => 'k u',
	'シャ' => 'sh a',             'シュ' =>'sh u',            'ショ'=>'sh o',
	'ジャ' => 'j a',              'ジュ' =>'j u',             'ジョ'=>'j o',
	'チャ' => 'ch a',             'チュ' =>'ch u', 'チェ' =>'ch e', 'チョ'=>'ch o',
	'ティ' => 't i', 'トゥ' =>'t u',
	'ディ' => 'd i', 'デュ' => 'dy u', 'ドゥ' =>'d u',
	'ニャ' => 'ny a', 'ニュ' => 'ny u', 'ニョ' => 'ny o',
	'ネェ' => 'n e:',
	'ファ' => 'f a', 'フィ' => 'f i', 'フェ' => 'f e', 'フォ' => 'f o',
	                              'フュ' =>'hy u',            'フョ'=>'hy o',
	'ヒャ' => 'hy a',             'ヒュ' =>'hy u',            'ヒョ'=>'hy o',
	'ビャ' => 'by a',             'ビュ' =>'by u',            'ビョ'=>'by o',
	'ピャ' => 'py a',             'ピュ' =>'py u',            'ピョ'=>'py o',
	'ミャ' => 'my a',             'ミュ' =>'my u',            'ミョ'=>'my o',
	'リャ' => 'ry a',             'リュ' =>'ry u',            'リョ'=>'ry o',
	                  'ウィ' => 'w i',             'ウェ' =>'w e',  'ウォ'=>'w o',
	'ヴァ' => 'b a',  'ヴィ' => 'b i',  'ヴェ' =>'b e',  'ヴォ'=>'b o',
	'ウ゛ァ' => 'b a', 'ウ゛ィ' => 'b i', 'ウ゛ェ' => 'b e', 'ウ゛ォ' => 'b o',
	'ンー' => 'N'
);

my $word_silB = "<s>";
my $word_silE = "</s>";

##
## メインルーチン
##
while(my $entry = <>) {
	chomp $entry;
	my ($word, $yomi, $pos) = split(/\+/, $entry, 3);
	my $new_yomi = kana2phone($yomi);
	$new_yomi =~ s/[^a-zA-Z:\s]//go;
	
	if($word eq $word_silB) {
		$new_yomi = "silB";
	} elsif($word eq $word_silE) {
		$new_yomi = "silE";
	}

	if($new_yomi !~ /([aiueoN]|sp|sil)/o) {
		print STDERR $entry,"\n";
	} else {
		print join("\t", $entry, "[".$word."]", $new_yomi), "\n";
	}
}

exit 0;

##
## ライブラリ
##
sub kana2phone {
	my $text = shift;
	my $result = $text;
	return "" if(!$result);

	foreach my $key (keys %kana2phone_table2){
		$result =~ s/$key/$kana2phone_table2{$key} /g;
	}
	foreach my $key (keys %kana2phone_table1){
		$result =~ s/$key/$kana2phone_table1{$key} /g;
	}
	
	$result =~ s/ :/:/go;
	$result =~ s/  / /go;
	
	# 2重母音対策
	$result =~ s/a a/a:/go;
	$result =~ s/i i/i:/go;
	$result =~ s/u u/u:/go;
	$result =~ s/e e/e:/go;
	$result =~ s/o o/o:/go;

	$result =~ s/e i/e:/go;
	$result =~ s/o u/o:/go;
	
	$result =~ s/::/:/go;
	$result =~ s/:+/:/go;
	$result =~ s/(?<![aiueo])://go;

	return $result;
}

