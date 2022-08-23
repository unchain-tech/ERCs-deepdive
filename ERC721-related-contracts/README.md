# ERC721
## 目次
### 1. [はじめに](#はじめに)
### 2. ERC721.solにインポートされているファイル

1. [Address,sol](#21-addresssol)
2. [Context.sol](#22-contextsol)
3. [Strings.sol](#23-stringssol)
4. [ERC165.sol](#24-erc165sol)
5. [IERC721.sol](#25-ierc721sol)
6. [IERC721Receiver.sol](#26-ierc721receiversol)
7. [IERC721Metadata.sol](#27-ierc721metadatasol)


### 3. [ERC721.sol]()

1. []()
2. []()
3. []()
4. []()

### 4. [TIPs]()

## 1. はじめに

ここでは，ERC721.solとその中でインポートされている7つを含めた8つのsolファイルについて，順番にコードベースでよみとくことによってERC721を完全に理解することを目指します．

しかし，このREADME.mdファイルではコードは極力使わず，実際にコードを読み解くsolファイル群へのリンクは添えたうえで，日本語ベース・ノーコードでなるべく簡潔な解説を行っていきます．

> 尚，Solidityの文法に関してはある程度前提としていますが，Solidityのハンズオンラーニングの手段ともなりえるように，検索可能な用語を用いることを心掛けることとします．

## 2. ERC721.sol にインポートされているファイル

以下では，``ERC721.sol`` でインポートされているそれぞれのファイルについて，おおまかな内容と ``ERC721.sol`` 内での用途を説明していきます．
レポジトリ内の同名ファイルには，原本に適宜コメントを追加したファイルを同梱してあります．ご活用ください．

### 2.1. Address,sol

このファイルでは， ``address`` 型の変数に関する関数を集めた ``Address`` ライブラリを定義しています．
ERC721における用途は，``isContract()`` の利用です．この関数は ``address`` 値を引数にとり，そのアドレス長が0より大きいかどうかを ``bool`` 値で返します．こうすることで，4種ほどの例外を除き，引数のアドレスがコントラクトアドレスかどうかを判断します．
> この例外というのはコントラクトが機能しない特殊な状況にある場合です．なので，実質的にはコントラクトが利用可能な状態であるかどうかを示すものになります．そして，コントラクトとウォレットアドレス(EOAアドレス)は形式が同じであるため，仮に存在するウォレットアドレスを引数としたとしても ``isContract()`` は ``true`` を返すと思われます．

↓元ファイル
[openzeppelin-contracts/contracts/utils/Address.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)

### 2.2. Context.sol

このファイルでは，``abstract`` という分類の ``contract`` の中で，``msg.sender`` という宣言をラップする ``_msgSender``という関数を宣言しています． 

わざわざ関数でラップしているのはなぜかというと，メタトランザクションスキームを用いる場合に ``msg.sender`` をそのまま使うのは都合が悪いからです．

以下に簡単な説明をのせておきます．詳しくは[ここ](https://github.com/unchain-dev/openzeppelin-deepdive/tree/main/metatx-related-contracts#2-meta-transaction%E3%81%A8%E3%81%AF-1)を参照してください． 

> ``msg.sender`` は EVM に規定されたグローバル変数なので書き換えできませんが，関数の中に ``msg.sender`` をラップした ``_msgSender()`` 関数を使うことによって，メタトランザクション使用時には ``_msg.sender()`` 関数をオーバーライドして返り値を書き換えることにより ``msg.sender(gas feeを支払うアドレス)`` と ``_msgSender()の返り値(txを実行したいアドレス)`` を分けることができるようになります．

↓元ファイル
[openzeppelin-contracts/contracts/utils/Context.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol)



### 2.3. Strings.sol

これは，uint列を文字列，特に16進数文字列に変換する関数のスタンダードを集めたライブラリです．
使い道については，下のような実例をみるとわかりやすいでしょう．
元ファイルではあまり触れられていませんが，エンコード(変換作業)のしくみについても少しふれてあるので，そのあたりも気になる方はレポジトリ内のコメント入りファイルを見てみてください．

> このERC271においては，tokenURIを参照する ``tokenURI(uint256 tokenId)`` 関数において， uint である ``tokenId`` を string に変換するときに用いている．
これは関数内で string である ``_baseURI()`` と uint である ``tokenId`` を結合するためである．
uint である ``tokenId`` を string に変換して ``_baseURI()`` と結合することで ``tokenURI`` を生成し，string 値として返すのである．

↓元ファイル
[openzeppelin-contracts/contracts/utils/Strings.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol)

### 2.4. ERC165.sol

hogehoge


### 2.5. IERC721.sol

このファイルでは，``interface`` という分類の ``contract`` の中で，``ERC721.sol`` 内に存在する関数の中で可視性が ``internal`` でないものの型定義と，コメントを用いた関数の説明がなされています．

``abstract`` と ``interface`` の違いは，``contract`` 内に関数を内包するか否かです．

↓元ファイル
[openzeppelin-contracts/contracts/token/ERC721/IERC721.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol)


### 2.6. IERC721Receiver.sol

hogehoge


### 2.7. IERC721Metadata.sol

このファイルでは，``interface`` という分類の ``contract`` の中で，

``ERC721.sol`` 内で ``_name`` 変数を参照する ``name`` 関数，
``ERC721.sol`` 内で ``_symbol`` 変数を参照する ``symbol`` 関数，
``ERC721.sol`` 内で ``tokenId`` を参照する ``tokenURI`` 関数

の三つの関数を型定義しています．

↓元ファイル
[openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/IERC721Metadata.sol)

## 3. ERC721

### 3.1. hoge

hugahuga


### 3.2. huga

hugahuga


## 4. TIPs

anyTips