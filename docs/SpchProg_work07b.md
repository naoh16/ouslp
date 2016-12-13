---
title: 実習7b: HMM音響モデルの適応
---

# 実習7b: HMM音響モデルの適応（発展課題）

## 7b-0. 作業ディレクトリ等

    $ cd ~/OUSLP/work/recog_shop
    $ mkdir model/adapt


## 7b-1. MLLR適応の準備

ここでは32クラスタの回帰木を作成して適応をおこなう．

適応には回帰木ファイルが必要となる．
そして，回帰木ファイルを作るためには，学習時のstatファイルが必要となる．


### 7b-1-1. 適応元ファイルの確認

~~~ sh
$ ls -al base_am/
~~~

    合計 892
    drwxrwx---+ 2 hara abelab   4096 2013-11-29 16:15 ./
    drwxrwx---+ 7 hara abelab   4096 2013-11-29 16:55 ../
    -rw-r--r--  1 hara abelab 621544 2013-11-29 17:59 hmmdefs
    -rw-r--r--  1 hara abelab   9142 2013-11-29 17:59 stats
    -rw-r--r--  1 hara abelab   8376 2013-11-29 17:50 tree
    -rw-r--r--  1 hara abelab 248244 2013-11-29 17:50 triphones


### 7b-1-2. スクリプトファイルの作成

~~~ sh
$ emacs prepare_adapt.hed
~~~

    LS "base_am/stats"
    RC 32 "rtree"


### 7b-1-3. 回帰木構成スクリプトの実施

~~~ sh
$ HHEd -T 1 -H base_am/hmmdefs -M model/adapt prepare_adapt.hed base_am/triphones
~~~

`model/adapt` 以下に`rtree.base` と `rtree.tree` というファイルが作られる


### 7b-1-4. 適応スクリプトの作成

適応の種類や適応に使うファイルなどの設定を書く

~~~ sh
$ emacs config/adapt.hconf
~~~

    HADAPT:TRANSKIND   = MLLRMEAN
    HADAPT:USEBIAS     = TRUE
    HADAPT:REGTREE     = rtree.tree
    HADAPT:ADAPTKIND   = TREE
    HADAPT:SPLITTHRESH = 1000.0
    HADAPT:KEEPXFORMDISTINCT = FALSE
    HADAPT:SAVESPKRMODELS = TRUE
    HADAPT:TRACE = 61
    HMODEL:TRACE = 512


## 7b-2. MLLR適応の実行

適応のために計算される／された回帰パラメータはそれぞれ`-J`から読み込まれて，`-K`に出力される．
オプションは以下の通り．

* `-J dir` ... ディレクトリ `dir` から適応**前**の音響モデルを読み込む．
* `-K dir` ... ディレクトリ `dir` に適応**後**の音響モデルを保存する
* `-u a` ... Adaptation (`a`)を行う

~~~ sh
$ HERest -C config/train.hconf -C config/adapt.hconf -I train_tri.mlf -H base_am/hmmdefs -u a -K model/adapt -J model/adapt -h '*%??.mfc' base_am/triphones -S mfcfile.list
~~~

`model/adapt` 以下に `hmmdefs.a` というファイルが作られる．
拡張子の`a`は`HERest`の`-h`オプションにおける「`%`」に相当する箇所が埋め込まれる．
例えば、話者IDのようなものがついたファイル群ならばそのID相当の文字数だけ`%%`などと書けば，
話者毎のモデルをつくることができる．
（例えば，`hmmdefs.M1`, `hmmdefs.M2`のようなファイルを作れる，ということ）


## 7b-3. 認識と評価

~~~ sh
$ HVite -T 1 -H base_am/hmmdefs -w digit.wdnet -i result_base.mlf -C config/train.hconf digit.dic base_am/triphones ../recog_digit/mfcc/d?-?.mfc
$ HResults -I config/ref_digit.mlf base_am/triphones result_base.mlf
~~~

    ====================== HTK Results Analysis =======================
      Date: Fri Nov 29 16:08:30 2013
      Ref : config/ref_digit.mlf
      Rec : result_base.mlf
    ------------------------ Overall Results --------------------------
    SENT: %Correct=92.00 [H=46, S=4, N=50]
    WORD: %Corr=92.00, Acc=92.00 [H=46, D=0, S=4, I=0, N=50]
    ===================================================================

~~~ sh
$ HVite -T 1 -H model/adapt/hmmdefs.a -w digit.wdnet -i result_adapt.mlf -C config/train.hconf digit.dic base_am/triphones ../recog_digit/mfcc/d?-?.mfc
$ HResults -I config/ref_digit.mlf base_am/triphones result_adapt.mlf
~~~

    ====================== HTK Results Analysis =======================
      Date: Fri Nov 29 16:55:35 2013
      Ref : config/ref_digit.mlf
      Rec : result_adapt.mlf
    ------------------------ Overall Results --------------------------
    SENT: %Correct=98.00 [H=49, S=1, N=50]
    WORD: %Corr=98.00, Acc=98.00 [H=49, D=0, S=1, I=0, N=50]
    ===================================================================


## 7b-4. ルールベース文法による認識と結果の比較

文法（`command.wdnet`など）の作成については実習7aを参照。


### 7b-4-1. ベースモデルと適応モデルによる認識

モデルの切り替え（`-H`）と結果の出力先（`-I`）を切り替えて認識結果を準備する．
文字化けする場合は，フィルタを通せば日本語が見られる
~~~ sh
$ perl filter.pl < result_cmd_base.mlf
~~~

#### ベースモデル

~~~ sh
$ HVite -T 1 -H base_am/hmmdefs -w command.wdnet -i result_cmd_base.mlf -C config/train.hconf command.dic base_am/triphones mfcc_command/c?-?.mfc
~~~

#### 適応モデル

~~~ sh
$ HVite -T 1 -H model/adapt/hmmdefs.a -w command.wdnet -i result_cmd_adapt.mlf -C config/train.hconf command.dic base_am/triphones mfcc_command/c?-?.mfc
~~~


### 7b-4-2. 認識率の表示と比較

#### ベースモデル

~~~ sh
$ HResults -f -I config/ref_command.mlf base_am/triphones result_cmd_base.mlf
~~~

    ------------------------ Sentence Scores --------------------------
    ====================== HTK Results Analysis =======================
      Date: Fri Nov 29 16:56:27 2013
      Ref : config/ref_command.mlf
      Rec : result_cmd_base.mlf
    -------------------------- File Results ---------------------------
    c1-1.rec:   66.67( 66.67)  [H=   2, D=  1, S=  0, I=  0, N=  3]
    c1-2.rec:  100.00(100.00)  [H=   3, D=  0, S=  0, I=  0, N=  3]
    c1-3.rec:   50.00( 50.00)  [H=   1, D=  0, S=  1, I=  0, N=  2]
    c1-4.rec:  100.00(100.00)  [H=   4, D=  0, S=  0, I=  0, N=  4]
    c1-5.rec:  100.00(100.00)  [H=   4, D=  0, S=  0, I=  0, N=  4]
    ------------------------ Overall Results --------------------------
    SENT: %Correct=60.00 [H=3, S=2, N=5]
    WORD: %Corr=87.50, Acc=87.50 [H=14, D=1, S=1, I=0, N=16]
    ===================================================================

#### 適応モデル

~~~ sh
$ HResults -f -I config/ref_command.mlf base_am/triphones result_cmd_adapt.mlf
~~~

    ------------------------ Sentence Scores --------------------------
    ====================== HTK Results Analysis =======================
      Date: Fri Nov 29 16:56:12 2013
      Ref : config/ref_command.mlf
      Rec : result_cmd_adapt.mlf
    -------------------------- File Results ---------------------------
    c1-1.rec:   66.67( 66.67)  [H=   2, D=  1, S=  0, I=  0, N=  3]
    c1-2.rec:  100.00(100.00)  [H=   3, D=  0, S=  0, I=  0, N=  3]
    c1-3.rec:  100.00(100.00)  [H=   2, D=  0, S=  0, I=  0, N=  2]
    c1-4.rec:  100.00(100.00)  [H=   4, D=  0, S=  0, I=  0, N=  4]
    c1-5.rec:  100.00(100.00)  [H=   4, D=  0, S=  0, I=  0, N=  4]
    ------------------------ Overall Results --------------------------
    SENT: %Correct=80.00 [H=4, S=1, N=5]
    WORD: %Corr=93.75, Acc=93.75 [H=15, D=1, S=0, I=0, N=16]
    ===================================================================
