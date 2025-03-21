# EIP-XXX

## 目次

### 1. [はじめに](#1-はじめに)

### 2. [インポートされているファイル](#2-インポートされているファイル)

### 3. [ERCXXX.sol](#3-ERCXXX.sol)

1. [""import""，""using""，変数定義，そして ""constructor""](#31-importusing変数定義そして-constructor)
2. [ストレージ上の値を書き換えることがない ""view"" 関数群](#32-ストレージ上の値を書き換えることがない-view-関数群)
3. [主要な機能の発動を担う標準搭載関数群](#33-主要な機能の発動を担う標準搭載関数群)
4. [挙動を司る関数群，追加実装のための関数群](#34-挙動を司る関数群追加実装のための関数群)

### 4. [TIPs](#4-tips)

## 1. はじめに

ここでEIPについて概要を紹介してください

## 2. ERC721.sol にインポートされているファイル

ここに関連ファイルを列挙してください. 以下例

### 2.1. Address.sol

このファイルでは， `address` 型の変数に関する関数を集めた `Address` ライブラリを定義しています．
ERC721 における用途は，`isContract()` の利用です．この関数は `address` 値を引数にとり，そのアドレス長が 0 より大きいかどうかを `bool` 値で返します．こうすることで，4 種ほどの例外を除き，引数のアドレスがコントラクトアドレスかどうかを判断します．

> この例外というのはコントラクトが機能しない特殊な状況にある場合です．なので，実質的にはコントラクトが利用可能な状態であるかどうかを示すものになります．そして，コントラクトとウォレットアドレス(EOA アドレス)は形式が同じであるため，仮に存在するウォレットアドレスを引数としたとしても `isContract()` は `true` を返すと思われます．

↓ 元ファイル

[openzeppelin-contracts/contracts/utils/Address.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)

### 2.2. Context.sol

このファイルでは，`abstract` という分類の `contract` の中で，`msg.sender` という宣言をラップする `_msgSender`という関数を宣言しています．

わざわざ関数でラップしているのはなぜかというと，メタトランザクションスキームを用いる場合に `msg.sender` をそのまま使うのは都合が悪いからです．

以下に簡単な説明をのせておきます．詳しくは[ここ](https://github.com/unchain-dev/openzeppelin-deepdive/tree/main/metatx-related-contracts#2-meta-transaction%E3%81%A8%E3%81%AF-1)を参照してください．

> `msg.sender` は EVM に規定されたグローバル変数なので書き換えできませんが，関数の中に `msg.sender` をラップした `_msgSender()` 関数を使うことによって，メタトランザクション使用時には `_msg.sender()` 関数をオーバーライドして返り値を書き換えることにより `msg.sender(gas feeを支払うアドレス)` と `_msgSender()の返り値(txを実行したいアドレス)` を分けることができるようになります．

↓ 元ファイル

[openzeppelin-contracts/contracts/utils/Context.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol)

### 2.3. Strings.sol

これは，uint 列を文字列，特に 16 進数文字列に変換する関数のスタンダードを集めたライブラリです．
使い道については，下のような実例をみるとわかりやすいでしょう．
元ファイルではあまり触れられていませんが，エンコード(変換作業)のしくみについても少しふれてあるので，そのあたりも気になる方はレポジトリ内のコメント入りファイルを見てみてください．

> この ERC271 においては，tokenURI を参照する `tokenURI(uint256 tokenId)` 関数において， uint である `tokenId` を string に変換するときに用いている．
> これは関数内で string である `_baseURI()` と uint である `tokenId` を結合するためである．
> uint である `tokenId` を string に変換して `_baseURI()` と結合することで `tokenURI` を生成し，string 値として返すのである．

↓ 元ファイル

[openzeppelin-contracts/contracts/utils/Strings.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol)

etc

## 3. ERC XXX

ここにEIP/ERCの中身の解説を記述してください

## 4. TIPs

### 寄稿をお待ちしております！！
