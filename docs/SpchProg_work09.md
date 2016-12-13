---
title: 実習9: 音声認識エンジン Julius を用いた大語彙音声認識と評価
---

# 実習9: 音声認識エンジン Julius を用いた大語彙音声認識と評価

前回実習で作成したJulius用の言語モデルを利用して，認識実験を行う．

## 9.0 準備

実習8と同じ`~/OUSLP/work/mklm`以下でおこなう．

~~~ sh
$ cd ~/OUSLP/work/mklm
~~~

なお，同封されている`ref.txt`が古い版（ニュース風の文書）になっているかもしれない．
その場合は，以下の内容に修正する．

~~~
吾輩は猫である。
薄暗いじめじめした所でニャーニャー泣いていた事だけは記憶している。
この書生というのは時々我々を捕えて煮て食うという話である。
そうして，その穴の中から時々ぷうぷうと煙を吹く。
腹が非常に減って来た。泣きたくても声が出ない。
~~~

## 9.1 正解文ファイルを作成する

認識と同様の形態素解析（あるいは、単語の分かち書き）が必要になる．

### 9.1.1 ベースとなるテキストファイルを作る

`emacs`などのエディタを用いて，正解テキストを1行ずつ書き並べたファイル（`ref.txt`）を作成する．
読み仮名は消しておいたほうが良い．

    * https://sites.google.com/site/ouslp2016/1/labo_a
    * n101などの文字列は，今は不要

### 9.1.2 mecabで分かち書きに変換

分かち書きされたテキスト`result.ref`を作成する．

~~~ sh
$ mecab -Owakati ref.txt > result.ref
~~~

### 9.1.3 IDを付与

9.1.1で消したIDを再び付与する．
以下の例のように`ID\t正解テキスト\n`という書式に変換する．

~~~ sh
emacs result.ref
~~~

~~~
n101    吾輩 は 猫 で ある 。
n102    薄暗い じめじめ し た 所 で ニャーニャー 泣い て い た 事 だけ は 記憶 し て いる 。
~~~


## 9.2 音声認識の実施

### 9.2.1 特徴量ファイルの準備

Juliusは本来wavファイルでも読み込めるのだが，ここでは処理の高速化のため，事前に特徴量に変換しておく．

~~~ sh
$ HCopy -C ../recog_shop/config/wav2mfcc.hconf ../speech/novel1/n101.wav n101.mfc
$ HCopy -C ../recog_shop/config/wav2mfcc.hconf ../speech/novel1/n102.wav n102.mfc
$ HCopy -C ../recog_shop/config/wav2mfcc.hconf ../speech/novel1/n103.wav n103.mfc
$ HCopy -C ../recog_shop/config/wav2mfcc.hconf ../speech/novel1/n104.wav n104.mfc
$ HCopy -C ../recog_shop/config/wav2mfcc.hconf ../speech/novel1/n105.wav n105.mfc
~~~

参考までに，`HCopy`の書式は`HCopy -C (config_file) (source_file) (destination_file)`である．

### 9.2.2 Juliusによる音声認識を実行

~~~ sh
$ find . -name "*.mfc" | sort | julius -h ../recog_shop/base_am/hmmdefs -hlist ../recog_shop/base_am/triphones -v news5000.dic -d news.bingram | tee result.txt
~~~

パイプでつなげたコマンドの意味は以下の通り．

  - `find`で拡張子`.mfc`のファイルを現在のディレクトリ（`.`）から探索して，ファイルリストを出力
  - `sort`で念のためファイルリストが番号順になるようにソートしておく
  - `julius`でファイルリストに書かれたすべての音声ファイルに対して音声認識をする
  - `tee`で認識結果をファイル（`result.txt`）に書き出しつつ，デバッグのために画面にも表示させる

### 9.2.3 認識率を算出

#### 認識結果を正解ファイルと同じ書式に変換する（仮説ファイルと呼ぶ）

~~~ sh
$ perl scoring.pl res2hyp result.txt | tee result.hyp
~~~

#### 正解ファイルと仮説ファイルの単語間のDPマッチングをおこなう

~~~ sh
$ perl scoring.pl align result.ref result.hyp | tee result.ali
~~~

#### DPマッチングの結果から認識精度を算出する

~~~ sh
$ perl scoring.pl score result.ali
~~~

#### 考察の参考

  - 認識率を上げるにはどうすればよいだろうか？
  - コマンド文法も認識できるようにするためにはどうすればよいだろうか？
    - ヒント：Juliusには文法のデバッグのために，文法から文章を生成するツールが含まれている．
