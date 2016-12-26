---
title: 実習7a: 文音声認識
---

# 実習7a: 文音声認識

本実習ではルールベースの文法を用いた連続単語音声錦（文音声認識）をおこなう．

## 7a-0. 作業ディレクトリに移動

~~~ sh
$ cd ~/OUSLP/work/recog_shop
~~~

## 7a-1. ルールベース文法の作成 (HParseを利用する場合)

本節ではHTKの`HParse`を用いた手順を説明する．
Juliusの`mkdfa.pl`を使う場合は，7a-4を参照のこと．

### 7a-1-1. 辞書の作成

~~~ sh
$ emacs command.dic
~~~

~~~
silB    []   silB
silE   []   silE
FRUIT   [ハクトウ]      h a k u t o:
FRUIT   [ピオーネ]      p i o: n e
FRUIT   [マスカット]    m a s u k a q t o
FRUIT   [バナナ]        b a n a n a
WO      [を]    o
KUDASAI [ください] k u d a s a i
ONEGAI  [お願いします] o n e g a i sh i m a s u
NUM     [一個] i q k o
NUM [二個] n i k o
NUM [三個] s a N k o
NUM [四個] y o N k o
NUM [五個] g o k o
~~~


### 7a-1-2. 文法のソースファイル作成

~~~ sh
$ emacs command.gram
~~~

~~~
$S = FRUIT;
$V = KUDASAI | ONEGAI;

$snt1 = $S WO $V;
$snt2 = $S $V;
$snt3 = $S WO NUM $V;
$snt4 = NUM $V;

( silB ($snt1 | $snt2 | $snt3 | $snt4) silE )
~~~

### 7a-1-3. 文法ファイルのコンパイル

~~~ sh
$ HParse command.gram command.wdnet
~~~


## 7a-2. ルールベース文法による認識

### 7a-2-1. 認識対象の音声ファイルの準備

~~~ sh
$ mkdir mfcc_command
$ HCopy -C config/wav2mfcc.hconf ../../speech/command/c1-1.wav mfcc_command/c1-1.mfc
$ HCopy -C config/wav2mfcc.hconf ../../speech/command/c1-2.wav mfcc_command/c1-2.mfc
$ HCopy -C config/wav2mfcc.hconf ../../speech/command/c1-3.wav mfcc_command/c1-3.mfc
$ HCopy -C config/wav2mfcc.hconf ../../speech/command/c1-4.wav mfcc_command/c1-4.mfc
$ HCopy -C config/wav2mfcc.hconf ../../speech/command/c1-5.wav mfcc_command/c1-5.mfc
~~~

### 7a-2-2. ベースモデルによる認識

`HVite`コマンドを使ってViterbi Algorithmによる音声認識をおこなう．
オプションの意味は以下の通りだが，詳しくは`HVite`単独で実行して得られるヘルプを読むかHTKBookを読むこと．

  * `-T 1` ... デバッグ用オプション．数字が大きいほど表示される情報が増える．
  * `-H base_am/hmmdefs` ... 音響モデル
  * `-w command.wdnet` ... 言語モデル（文法）
  * `-i result_cmd_base.mlf` ... 認識結果を出力
  * `-C config/train.conf` ... 音声特徴量の変換設定
  * `command.dic` ... 辞書（文法内のシンボルと音素列の対応表）
  * `base_am/triphones` ... `-H`で指定した音響モデル内に登録されている音素のリスト
  （辞書の内容を網羅している必要がある．また，それらは音響モデルファイルにも登録されている音素である必要もある．）
  * `mfcc_command/c?-?.mfc` ... 認識する特徴量ファイルのリスト．`?`はシェルが展開してファイル名の羅列に変換されている．

~~~ sh
$ HVite -T 1 -H base_am/hmmdefs -w command.wdnet -i result_cmd_base.mlf -C config/train.hconf command.dic base_am/triphones mfcc_command/c?-?.mfc
~~~

なお，認識結果ファイルでは日本語が文字化けしてしまう．
以下のフィルタ（`filter.pl`）を通せば日本語が見られる．

~~~ sh
$ perl filter.pl < result_cmd_base.mlf
~~~


## 7a-3. 認識率の算出

先ほど得られた認識結果ファイルを集計するために，`HResults`コマンドを用いる．
`-I`で指定したファイルには，音声ファイルを書き起こしたテキスト（transcription）から作られた，
単語列が書かれている．形式は`HVite -i`で得られる結果とほぼ同じ形式で書く．

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


なお，`mlf`はMaster Label Fileの略．


## 7a-4. 参考：Juliusを用いた文法ファイルの作成

参考としてJuliusの`mkdfa.pl`を用いた文法を作成する方法を説明する．
なお，Juliusで文法を作った場合，`HVite`で認識することはできない．

HTKベースで文法認識までできているならば，この項の内容は無視してよい．

#### 文法（command.grammar）の作成

~~~
S       :  NS_B FRUIT WO PLEASE NS_E
S       :  NS_B FRUIT PLEASE NS_E
S       :  NS_B FRUIT WO NUM PLEASE NS_E
S       :  NS_B FRUIT WO PLEASE NS_E

PLEASE  :  KUDASAI
PLEASE  :  ONEGAI
~~~

#### 単語リスト（command.voca）の作成

~~~
% NS_B
<s>   silB
% NS_E
</s>  silE
%FRUIT
ハクトウ      h a k u t o:
ピオーネ      p i o: n e
マスカット    m a s u k a q t o
バナナ        b a n a n a
%WO
を    o
%KUDASAI
ください  k u d a s a i
%ONEGAI
お願いします  o n e g a i sh i m a s u
%NUM
一個  i q k o
二個  n i k o
三個  s a N k o
四個  y o N k o
五個  g o k o
~~~

#### コンパイル（perlが必要）

~~~
$ mkdfa.pl command
~~~
