---
title: 実習8: 新聞記事言語モデルの学習と評価
---

# 実習8: 新聞記事言語モデルの学習と評価

この演習では一般的な言語モデルの作成を行うのではなく、次回以降から利用する予定の
音声認識エンジン Julius の仕様に合わせた言語モデルの作り方である。具体的には、

  1. 文頭、文末記号をつけない。
  2. 2-gramはそのままだが、3-gramは逆向きのテキストコーパスから作成する。

という違いがある。


## 8-1. 作業ディレクトリ等

無ければ，以下の作業をおこなう．

~~~ sh
$ mkdir ~/OUSLP/work/mklm
$ cd ~/OUUSLP/work/mklm
$ cp -dR ~hara/share/OUSLP2016/skel/work/mklm/* .
~~~


## 8-2. mecabによる形態素解析

今回はニュース5000文のテキスト`data/news5000.txt`を利用する．

### 8-2-1. mecabによる形態素解析

~~~sh
$ head -1 data/news5000.txt | mecab
~~~

以下のURLの内容を見ながら，形態素解析の結果を観察する．

http://mecab.googlecode.com/svn/trunk/mecab/doc/index.html#parse


### 8-2-2. 言語モデル生成のためのデータ作成

今回は1つの形態素を「単語＋発音＋品詞」という組で表現する．

* 例：「地上+チジョー+名詞」

`mecab`の出力フォーマット（`-O`）は以下のURLを参照のこと。

* http://mecab.googlecode.com/svn/trunk/mecab/doc/format.html
* http://mecab.googlecode.com/svn/trunk/mecab/doc/index.html#format

    > 出力フォーマットは, ChaSen のそれと大きく異なります。 左から,
    >  表層形\t品詞,品詞細分類1,品詞細分類2,品詞細分類3,活用形,活用型,原形,読み,発音
    > となっています。

~~~sh
$ mecab --bos-format="" --eos-format="\n" --unk-format="%m+%m+%f[0]\s" --node-format="%m+%f[8]+%f[0]\s" < data/news5000.txt > news5000_morph.txt
~~~

### 8-2-3. 学習セットと評価セットの作成

今回は前半4,000文を学習用に利用して，後半1,000文を評価用に用いる．

~~~ sh
$ head -4000 news5000_morph.txt > news,train.txt
$ tail -1000 news5000_morph.txt > news,test.txt
~~~

## 8-3. ngram-countコマンドによる言語モデルの作成と評価

### 8-3-1. モデル（Good-Turingディスカウント法; GT）の作成

`ngram-count`コマンドはデフォルトで Good-Turing ディスカウンティングになる。

  > ngram-count uses Good-Turing discounting (aka Katz smoothing) by default

3-gramモデルを作る／使う際には，`-order 3` というオプションをつける．
オプションの数字がN-gramのNに相当する．

未知語を許容するモデルを作る／使う際には，`-unk`というオプションをつける．

#### Good-Turing法（GT）

~~~sh
$ ngram-count -order 3 -unk -text news,train.txt -write news.wfreq -lm news,gt.lm
~~~

#### 出力されたファイルについて

  * `news.wfreq `には、3-gram, 2-gram, 1-gram の出現回数が記録される
  * `news,gt.lm` には、言語モデル（ARPA形式）が記録される
    * 対数確率、素性、バックオフ係数（対数確率）が順番に書かれている
    * バックオフ係数は、最大次数（今回なら3-gram）では書かれない（詳しくは講義資料参照）

### 8-3-2. パープレキシティによる評価

#### クローズド条件

~~~sh
$ ngram -lm news,gt.lm -unk -ppl news,train.txt
~~~

#### オープン条件

~~~sh
$ ngram -lm news,gt.lm -unk -ppl news,test.txt
~~~

#### 評価結果の見方

`man ngram`を行うと記載されている。

> Perplexity is given with two different normalizations:
> counting all input tokens (``ppl'') and excluding end-of-sentence tags (``ppl1'').


### 8-3-3. その他のディスカウンティング手法でも作成

#### Witten-bell法（WB）

~~~sh
$ ngram-count -order 3 -unk -wbdiscount -text news,train.txt -lm news,wb.lm
~~~

#### Modified Kneiser-Ney法（KN）

~~~sh
$ ngram-count -order 3 -unk -kndiscount -text news,train.txt -lm news,kn.lm
~~~

### 8-3-4. 評価

~~~sh
$ ngram -lm news,wb.lm -unk -ppl news,train.txt
$ ngram -lm news,kn.lm -unk -ppl news,train.txt
~~~

~~~sh
$ ngram -lm news,kn.lm -unk -ppl news,test.txt
$ ngram -lm news,wb.lm -unk -ppl news,test.txt
~~~

* クローズド条件とオープン条件の結果から，GT,WB, KNそれぞれの違いを考察してみよう．
* 未知語あり／なしの3-gramモデルについて作成し，その違いを考察してみよう．


## 8-4. Julius用の言語モデル作成

音声認識エンジン Julius のための言語モデル作成を行う．
ここでは学習・評価には分けないで5,000文全てを利用して学習する．

### 8-4-1. 正向き2-gramモデルの作成

`-write-vocab` オプションを使って，同時に単語リストも作成する．

~~~sh
$ ngram-count -order 2 -unk -kndiscount -text news5000_morph.txt -write-vocab news5000.vocab -lm news5000_2gram.lm
~~~

### 8-4-2. 逆向きコーパスを作成

~~~sh
$ perl -ane 'print join(" ", reverse(@F)),"\n"' < news5000_morph.txt > news5000_rev.txt
~~~

### 8-4-3. 逆向きN-gramモデルの作成

今回3-gramを作りたいので，`N=3`とする．

~~~sh
$ ngram-count -order 3 -unk -kndiscount -text news5000_rev.txt -write-vocab news5000.vocab -lm news5000_3gram_rev.lm
~~~


### 8-4-4. Julius専用の言語モデルに変換

Julius用の言語モデルとして`news5000.bingram`というファイルを作る．

~~~ sh
$ mkbingram -nlr news5000_2gram.lm -nrl news5000_3gram_rev.lm news5000.bingram
~~~

Juliusは圧縮したファイルも読み込めるので、gzip圧縮をかけておくとよい．
（HDDからの読み込みオーバーヘッドが減って起動が速くなる効果もある）

~~~sh
$ gzip news5000.bingram
~~~

### 8-4-5. Julius用の辞書ファイルを作成

`-write-vocab`の出力である単語リストから，辞書を作成する．
Juliusで利用できる辞書はHTKの辞書と同じ形式である。
単語リストから、「発音」を抽出し、「音素列」に変換する必要がある。

~~~ sh
perl vocab2htkdic.pl < news5000.vocab > news5000.dic 2> news5000.err
~~~

`news5000.dic`が生成された辞書で，`news5000.err`は自動で読み付与が出来なかった単語リストである。

### 8-4-6. Juliusで確認してみる

まずは実行してみる．

~~~sh
$ julius -h ../recog_shop/base_am/hmmdefs -hlist ../recog_shop/base_am/triphones -v news5000.dic -d news5000.bingram.gz
~~~

次のようなエラーが出ることがある．

    Error: voca_load_wordlist: line 2124: logical phone "dy-u+e" not found
    Error: voca_load_wordlist: the line content was: デュエット+デュエット+名詞     [デュエット]    dy u e q t o
    Error: voca_load_htkdict: begin missing phones
    Error: voca_load_htkdict: dy-u+e
    Error: voca_load_htkdict: end missing phones

このエラーに対応するためには，本来ならば「トライホンの外挿（実習7b参照）」を行う．
今回は，エラーの数も少ないので先見知識を利用することにする．
具体的には，以下の処理をおこなえばよい．

    トライホンリスト（tied_triphones）から，Logical Triphone（左列）の y-u+e を探索し，
    そのPhysical Triphone（右列）を覚えておく．
    トライホンリストの末尾にLogical Triphone（左列）として dy-u+e を追加し，
    そのPhysical Triphone（右列）として y-u+e を書いておく．

最終的に，以下のような出力で止まっていたら言語モデルが正しく読み込まれているはず．
（Ctrl+Cで強制終了できる）

     ### read analyzed parameter
     enter MFCC filename->
