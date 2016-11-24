---
title: 実習6: サブワードHMM音響モデルの学習と認識
---

# 実習6: サブワードHMM音響モデルの学習と認識

## 6-0.（無ければ）作業ディレクトリ等のコピーと作成

~~~ bash
$ cd ~/OUSLP/work
$ mkdir recog_shop
$ cd recog_shop
$ cp -dR ~hara/share/OUSLP2016/skel/work/recog_shop/* .
~~~

結果の確認

~~~ bash
$ ls -la
合計 20
drwxr-xr-x 4 hara staff 4096 2013-11-29 18:27 .
drwxr-xr-x 6 hara staff 4096 2013-11-29 18:27 ..
drwxr-xr-x 2 hara staff 4096 2013-11-29 18:27 base_am
drwxr-xr-x 2 hara staff 4096 2013-11-29 18:27 config
-rwxr-xr-x 1 hara staff  741 2013-11-29 18:27 mkextlist.pl
-rwxr-xr-x 1 hara staff  304 2013-11-29 18:27 mkexttriscript.pl
-rwxr-xr-x 1 hara staff  213 2013-11-29 18:27 mkmixupscript.pl
-rwxr-xr-x 1 hara staff 1627 2013-11-29 18:27 mktdcscript.pl
-rwxr-xr-x 1 hara staff  249 2013-11-29 18:27 mktriscript.sh
-rwxr-xr-x 1 hara staff  411 2013-11-29 18:27 proto2hmmdefs.sh
-rwxr-xr-x 1 hara staff 1228 2013-11-29 18:27 shrink_rule.pl
~~~

## 6-1. ファイルリストの作成と特徴量ファイルへの変換

特徴量ファイルを保存するディレクトリを作成

~~~ bash
$ mkdir mfcc
~~~

指定ディレクトリからwavファイルを探し出して，ファイル一覧を作り，
ファイル一覧を変換対応ファイル一覧に変換する．

~~~ bash
$ find ../speech/balance/*.wav -name "a*.wav" > wavfile.list
$ awk '{sub(".+/","");sub("\.wav",".mfc");print "./mfcc/"$1}' < wavfile.list > mfcfile.list
$ paste -d" " wavfile.list mfcfile.list | tee hcopy.list
~~~

`HCopy`を用いて変換

~~~ bash
$ HCopy -T 1 -C config/wav2mfcc.hconf -S hcopy.list
~~~


## 6-2. 初期モデルの学習

~~~ bash
$ mkdir -p model/seed
$ HCompV -T 1 -C config/train.hconf -m -v 1.0e-3 -M model/seed config/proto_5states -S mfcfile.list
Calculating Fixed Variance
  HMM Prototype: config/proto_5states
  Segment Label: None
  Num Streams  : 1
  UpdatingMeans: Yes
  Target Direct: model/seed
25858 speech frames accumulated
Updating HMM Means and Covariances
Output written to directory model/seed
~~~

## 6-3. コンテキスト非依存（モノホン）モデルの学習

### 6-3-1. 初期モデルを全ての音素HMMに割り振る

~~~ bash
$ mkdir model/mono_{0,1,2,3}
$ ./proto2hmmdefs.sh model/seed/proto_5states > model/mono_0/hmmdefs
~~~

### 6-3-2. 繰り返し学習

  * 一般にファイル数が膨大になるのでリストファイルを作ることが多い
  * ほとんどのHTKのコマンドは`-S filelist`とすることで、
    多数のファイルを指定する代わりにファイルリストから読み込んでくれる。

一回目の学習

~~~ bash
$ HERest -v 0.01 -C config/train.hconf -I config/train.mlf -H model/mono_0/hmmdefs -M model/mono_1/ config/monophones -S mfcfile.list
Pruning-Off
 WARNING [-2331]  UpdateModels: by[25] copied: only 1 egs
 in HERest
 WARNING [-2331]  UpdateModels: dy[28] copied: only 1 egs
 in HERest
 WARNING [-2331]  UpdateModels: py[36] copied: only 1 egs
 in HERest
~~~

以下、二回目、三回目、・・・と所望の回数まで繰り返す

~~~ bash
$ HERest -v 0.01 -C config/train.hconf -I config/train.mlf -H model/mono_1/hmmdefs -M model/mono_2/ config/monophones -S mfcfile.list
$ HERest -v 0.01 -C config/train.hconf -I config/train.mlf -H model/mono_2/hmmdefs -M model/mono_3/ config/monophones -S mfcfile.list
~~~

## 6-4. コンテキスト依存（トライホン）モデルへの変換

### 6-4-1. ラベルファイルの変換とCorpus triphone リストの作成

~~~ bash
$ HLEd -T 1 -l '*' -i train_tri.mlf -n corpus_triphones config/modelTC.led config/train.mlf
~~~

  * `train_tri.mlf`というファイルが作られる。ラベルがtriphoneに置き換わっている。
  * `corpus_triphones`というファイルが作られる。学習データに存在するtriphoneの一覧が出力されている。


### 6-4-2. Physical triphoneリストの作成（縮約規則の適用）

~~~ bash
$ perl shrink_rule.pl < corpus_triphones > physical_triphones
~~~

  * 縮約規則はperlスクリプト（`shrink_rule.pl`）に置換ルールを書いてある。


### 6-4-3. モデルの変換

~~~ bash
$ mkdir model/tri_{0,1,2,3}
$ mkdir model/stats
$ HHEd -T 1 -H model/mono_3/hmmdefs -w model/tri_0/hmmdefs config/mktri.hed config/monophones
~~~

  * `model/tri_0/hmmdefs` にトライホンモデルが作られている。中身を確認しておくこと。

### 6-4-4. 繰り返し学習（-s model/stats/stat_tri_?に注意）

~~~ bash
$ HERest -v 0.01 -C config/train.hconf -I train_tri.mlf -H model/tri_0/hmmdefs -M model/tri_1/ -s model/stats/stat_tri_1 physical_triphones -S mfcfile.list
$ HERest -v 0.01 -C config/train.hconf -I train_tri.mlf -H model/tri_1/hmmdefs -M model/tri_2/ -s model/stats/stat_tri_2 physical_triphones -S mfcfile.list
$ HERest -v 0.01 -C config/train.hconf -I train_tri.mlf -H model/tri_2/hmmdefs -M model/tri_3/ -s model/stats/stat_tri_3 physical_triphones -S mfcfile.list
~~~

  * この段階では学習データ数が少ない（3以下）というwarningが大量に出ることがある

    WARNING [-2331]  UpdateModels: a-by+u[61] copied: only 1 egs

  * `model/stats/stat_tri_3` ファイルには各状態の確率的回数が記録されている（c.f. HMMのEM学習）

### 6-4-5. モデルファイルに含まれるトライホン定義の数と状態の数を確認

~~~ bash
$ grep '<BEGINHMM>' model/tri_3/hmmdefs | wc -l
1124
$ grep '<STATE>' model/tri_3/hmmdefs | wc -l
3372
~~~

* この時点ではHMMモデルそれぞれに状態が3つずつ存在している。


## Logical triphone外挿のための準備

  * 学習時に現れないが認識時に利用されるtriphoneを利用できるようにする
  * triphoneの状態共有で作成された分類木を利用する
  * この作業は混合数を挙げた後に行っても良いが、データ数が少ない場合`HHEd`の最適化処理（使われていない状態を削除する）によりエラーが起こることがあるため、この段階で実行する。


### 6-4-6. 現在のLogical triphonesを確認

~~~ bash
$ less config/all_logical_triphones
~~~

### 6-4-7. 既存のトライホンリストと追加するトライホンリストをマージ

~~~ bash
$ awk '{print $1}' physical_triphones config/all_logical_triphones | sort -u > new_logical_triphones
~~~

  * 実際の外挿は、次の状態共有のスクリプト（`tdc.hed`）内で行われる


## 6-5. 状態共有

### 6-5-1. ディレクトリの準備

~~~ bash
$ mkdir model/gtp_s200_m1_{0,1,2,3}
~~~

### 6-5-2. 状態共有のためのスクリプトを作成

  * 数字はしきい値で値を大きくするほど、状態数が少なくなる

~~~ bash
 $ perl mktdcscript.pl 160 model/stats/stat_tri_3 > tdc.hed
~~~

### 6-5-3. HHEd + tdc.hedによる状態共有の実行

~~~ bash
     $ HHEd -T 1 -H model/tri_3/hmmdefs -w model/gtp_s200_m1_0/hmmdefs tdc.hed physical_triphones
~~~

出力の一番最後を見ると、（この場合では）205状態になったことがわかる。

       TB: Stats 4->1 [25.0%]  { 4137->205 [5.0%] total }

新しいトライホンリストとして`tied_triphones`が作られる（`tdc.hed`の中で指定している）
また、回帰木作成用のtreeファイルが`model/tree`に作られる（同上）

~~~
$ grep '~h' model/gtp_s200_m1_0/hmmdefs | sort -u | wc -l
104
$ grep '~s' model/gtp_s200_m1_0/hmmdefs | sort -u | wc -l
205
~~~

状態数がおよそ200±10になるように何度か繰り返して調節する

また、`model/gtp_s200_m1_0/hmmdefs`の中身を見て、以下の要素の定義と参照の位置をそれぞれ見ておくと良い。

    ~h … HMMの定義
    ~s … 状態の定義
    ~t … 遷移行列の定義

基本的には、最初に`~t`による遷移行列の定義が存在して、次に`~s`による状態の定義が続く。
最後に`~h`でHMMの定義をしているが、その中で状態や遷移行列をそれぞれ`~s`や`~t`でエイリアスをつけている。


### 6-5-4. 繰り返し学習

~~~ bash
$ HERest -v 0.01 -C config/train.hconf -I train_tri.mlf -H model/gtp_s200_m1_0/hmmdefs -M model/gtp_s200_m1_1/ -s model/stats/stat_gtp_s200_m1_1 tied_triphones -S mfcfile.list
$ HERest -v 0.01 -C config/train.hconf -I train_tri.mlf -H model/gtp_s200_m1_1/hmmdefs -M model/gtp_s200_m1_2/ -s model/stats/stat_gtp_s200_m1_2 tied_triphones -S mfcfile.list
$ HERest -v 0.01 -C config/train.hconf -I train_tri.mlf -H model/gtp_s200_m1_2/hmmdefs -M model/gtp_s200_m1_3/ -s model/stats/stat_gtp_s200_m1_3 tied_triphones -S mfcfile.list
~~~

  * この段階からは、下記のWARNINGはいくらか減少しているはず。経験的な目安として、WARNINGが20個以上出ているようなら、状態共有をもっと行う（＝状態数を減らす）方が良い。

     WARNING [-2331]  UpdateModels: a-by+u[61] copied: only 1 egs


## 6-6. 混合数増加（1->2）と学習

### 6-6-1. ディレクトリ作成

~~~ bash
$ mkdir model/gtp_s200_m2_{0,1,2,3}
~~~

### 6-6-2. スクリプト作成

~~~ bash
$ perl mkmixupscript.pl model/stats/stat_gtp_s200_m1_3 2 > mixup,2.hed
~~~

### 6-6-3. HHEd + mixup,2.hedによる混合数増加の実行

~~~ bash
$ HHEd -T 3 -H model/gtp_s200_m1_3/hmmdefs -w model/gtp_s200_m2_0/hmmdefs mixup,2.hed tied_triphones
~~~

### 6-6-4. 繰り返し学習

~~~ bash
$ HERest -v 0.01 -C config/train.hconf -I train_tri.mlf -H model/gtp_s200_m2_0/hmmdefs -M model/gtp_s200_m2_1/ -s model/stats/stat_gtp_s200_m2_1 tied_triphones -S mfcfile.list
$ HERest -v 0.01 -C config/train.hconf -I train_tri.mlf -H model/gtp_s200_m2_1/hmmdefs -M model/gtp_s200_m2_2/ -s model/stats/stat_gtp_s200_m2_2 tied_triphones -S mfcfile.list
$ HERest -v 0.01 -C config/train.hconf -I train_tri.mlf -H model/gtp_s200_m2_2/hmmdefs -M model/gtp_s200_m2_3/ -s model/stats/stat_gtp_s200_m2_3 tied_triphones -S mfcfile.list
~~~

※ 同様にして混合数2から4へのスクリプトを作成して、繰り返し学習を行う


## 6-7. 数字発声認識用の辞書と文法

~~~ bash
    $ cp ../recog_digit/digit.{dic,gram} .
~~~

### 6-7-1. 辞書の修正

単語HMMの場合は単語＝モデルだったが今回は単語＝ (モデル)+ である。
文頭記号（`silB`）と文末記号（`silE`）も追加する。
また、前後の無音が長い場合に備えて、ショートポーズ（`sp`）も追加する

~~~ bash
    $ emacs digit.dic
~~~

    silB    []   silB
    silE    []   silE
    sp      []   sp
    ICHI    i ch i
    NI      n i
    SAN     s a N
    YON     y o N
    GO      g o
    ROKU    r o k u
    NA-NA   n a n a
    HACHI   h a ch i
    KYU     ky u:
    ZERO    z e r o


### 6-7-2. 文法の修正

文頭記号（`silB`）と文末記号（`silE`）を追加する。
さらに、0回以上の無音（`<sp>`）を許可することで前後の無音が長い場合に備える。

~~~
$ emacs digit.gram
~~~

    $digit = ICHI | NI | SAN | YON | GO | ROKU | NA-NA | HACHI | KYU | ZERO;
    ( silB <sp> $digit <sp> silE )

~~~ bash
$ HParse digit.gram digit.wdnet
~~~

## 6-8. 数字発声の認識

### 6-8-1. コンテキスト非依存（モノホン）

~~~bash
$ HVite -T 1 -H model/mono_3/hmmdefs -w digit.wdnet -i result_mono.mlf -C config/train.hconf digit.dic config/monophones ../recog_digit/mfcc/d?-?.mfc
$ HResults -I config/ref_digit.mlf config/monophones result_mono.mlf
====================== HTK Results Analysis =======================
  Date: Tue Nov 26 11:58:45 2013
  Ref : config/ref_digit.mlf
  Rec : result_mono.mlf
------------------------ Overall Results --------------------------
SENT: %Correct=72.00 [H=36, S=14, N=50]
WORD: %Corr=72.00, Acc=72.00 [H=36, D=0, S=14, I=0, N=50]
===================================================================
~~~

### 6-8-2. コンテキスト依存（トライホン） 200状態1混合

~~~bash
$ HVite -T 1 -H model/gtp_s200_m1_3/hmmdefs -w digit.wdnet -i result_s200m1.mlf -C config/train.hconf digit.dic tied_triphones ../recog_digit/mfcc/d?-?.mfc
$ HResults -I config/ref_digit.mlf tied_triphones result_s200m1.mlf
====================== HTK Results Analysis =======================
  Date: Tue Nov 26 11:58:01 2013
  Ref : config/ref_digit.mlf
  Rec : result_s200m1.mlf
------------------------ Overall Results --------------------------
SENT: %Correct=94.00 [H=47, S=3, N=50]
WORD: %Corr=94.00, Acc=94.00 [H=47, D=0, S=3, I=0, N=50]
===================================================================
~~~

### 6-8-3. コンテキスト依存（トライホン） 200状態2混合

~~~bash
$ HVite -T 1 -H model/gtp_s200_m2_3/hmmdefs -w digit.wdnet -i result_s200m2.mlf -C config/train.hconf digit.dic tied_triphones ../recog_digit/mfcc/d?-?.mfc
$ HResults -I config/ref_digit.mlf tied_triphones result_s200m2.mlf
====================== HTK Results Analysis =======================
  Date: Tue Nov 26 11:58:11 2013
  Ref : config/ref_digit.mlf
  Rec : result_s200m2.mlf
------------------------ Overall Results --------------------------
SENT: %Correct=98.00 [H=49, S=1, N=50]
WORD: %Corr=98.00, Acc=98.00 [H=49, D=0, S=1, I=0, N=50]
===================================================================
~~~

※`HResults`に`-f`オプションをつけるとファイル毎の単語認識率が出力できる


## 6-9. Logical triphoneを再度外挿する（おまけ）

  * 認識時に利用されるtriphoneが足りない場合に行う
  * triphoneの状態共有で作成された分類木を利用する。

足りない音素を `config/all_logical_triphones` に追加

~~~bash
$ emacs config/all_logical_triphones
~~~

スクリプトを作成

~~~bash
$ perl mkexttriscript.pl model/tree tmp_tied_triphones > exttri.hed
~~~

実行

~~~bash
$ HHEd -T 4 -H model/gtp_s200_m4_3/hmmdefs -w model/gtp_s200_m4_4/hmmdefs exttri.hed tied_triphones
~~~

  * ※ 作成されたモデル `model/gtp_s200_m4_4/hmmdefs` と音素リスト `ext_tied_triphones` をそれぞれ利用する。
