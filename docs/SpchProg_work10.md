---
title: 実習10: 音声認識エンジン Julius のチューニング
---

# 実習10: 音声認識エンジン Julius のチューニング（発展課題）

Juliusには様々なパラメータがあり，認識率にかかわる設定項目も多く存在する．
この演習課題では，音声認識精度あるいは音声認識率の最適化を行うためのチューニングを行う．

## 10.1 Juliusのデフォルトアルゴリズムの切り替え

Juliusはコンパイル時点で，いくつかの認識アルゴリズムを組み合わせたデフォルトの設定がなされている．
演習室にはコンパイル済みの`julius`として，高速設定の`julius-fast`と標準設定の`julius-std`を用意している．

### 10.1.1 julius-fastとjulius-stdをそれぞれ使ってみる

実習9を参考にして音声認識を`julius-fast`と`julius-std`のそれぞれで実行し、
その認識率や実行速度を確認せよ。


## 10.2 パラメータチューニング

参考: The Julius Book 第8章 認識アルゴリズムとパラメータ
      http://julius.sourceforge.jp/juliusbook/ja/desc_search.html

なお，以下の課題はすべてfast設定のJulius (`julius-fast`)を利用すればよい．

### 10.2.1 第1パスのチューニング

  * ビーム幅の指定（`-b`）
    * 大きいほど高精度、`0`は全探索
  * 言語重みと挿入ペナルティの調整（`-lmp x y`）
    * `x`: 言語重みを大きくすると言語モデルの制約が強くなる
    * `y`: マイナスで与える。絶対値を大きくすると単語数が少なくなる

### 10.2.2 第2パスのチューニング

  * ビーム幅の指定（`-b2`）: 大きいほど高精度
  * 言語重みと挿入ペナルティの調整（`-lmp2 x y`）
    * 第1パスと同様


### 10.2.3 考察の参考例

考察１：
実用を考えると「単語正解精度を高くしたい」場合と「単語認識率を高くしたい」場合との2パターンが考えられる．
それぞれの目的を達成するためには、どのようなパラメータ設定をすれば良いだろうか？
（例えば、両者の目的に沿ってパラメータチューニングをした場合、パラメータにはどのような関係（大小関係など）があるだろうか？）

考察２：
マルチパス探索は一般に前段では荒く探索して、後段で高精度な探索が行われる．
この前提を踏まえた場合、どのようなパラメータ設定をすれば良いだろうか？
（例えば、第1パスのビーム幅 `-b` と第2パスのビーム幅 `-b2` をどのように調整していくべきかを考えてみよう．）
