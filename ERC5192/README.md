# ERC5192

## 目次

### 1. [はじめに](#1-はじめに)

### 2. [ ERC5192.sol にインポートされることになるであろうファイル](#2-erc5192sol-にインポートされているファイル)

1. [Address,sol](#21-addresssol)
2. [Context.sol](#22-contextsol)
3. [Strings.sol](#23-stringssol)
4. [ERC165.sol](#24-erc165sol)
5. [I`ERC5192.sol`](#25-ierc5192sol)
6. [IERC721.sol](#26-ierc721sol)
7. [IERC721Receiver.sol](#27-ierc721receiversol)
8. [IERC721Metadata.sol](#28-ierc721metadatasol)

### 3. [`ERC5192.sol`](#3-ERC5192sol)

1. [変数 \_accountLock と 関数 locked](#31-変数-_accountLock-と-関数-locked)
2. [\_mint 関数への引数 lock の追加と，それによる \_accountLock の状態の決定](#32-_mint-関数への引数-lock-の追加と，それによる-_accountLock-の状態の決定)
3. [\_accountLock の状態により制限される関数](#33-_accountLock-の状態により制限される関数)

### 4. [TIPs](#4-tips)

## 1. はじめに

ここでは，今後，標準化されるであろう `ERC5192.sol` とその中でインポートされる可能性の高い 8 つを含めた 9 つの sol ファイルについて，順番にコードベースでよみとくことによって ERC5192 を理解することを目指します．

ERC5192 はまだ EIP の段階であり，正式には ERC でないことにご留意ください．
SoulBound Token （ SBT ）のための実装の一つである ERC5192 は，開発しやすいようにそのコンセプトの大部分が NFT として知られる ERC721 からの流用になっています．

この `README.md` ファイルではコードは極力使わず，実際にコードを読み解く sol ファイル群へのリンクは添えたうえで，日本語ベース・ノーコードでなるべく簡潔な解説を行っていきます．

> 尚，Solidity の文法に関してはある程度前提としていますが，Solidity のハンズオンラーニングの手段ともなりえるように，検索可能な用語を用いることを心掛けることとします．

## 2. ERC5192.sol にインポートされているファイル

以下では，`ERC5192.sol` でインポートされる可能性のあるそれぞれのファイルについて，おおまかな内容と `ERC5192.sol` 内での用途を説明していきます．
レポジトリ内の同名ファイルには，原本に適宜コメントを追加したファイルを同梱してあります．ご活用ください．

### 2.1. Address.sol

このファイルでは， `address` 型の変数に関する関数を集めた `Address` ライブラリを定義しています．
ERC5192 における用途は，`isContract()` の利用です．この関数は `address` 値を引数にとり，そのアドレス長が 0 より大きいかどうかを `bool` 値で返します．こうすることで，4 種ほどの例外を除き，引数のアドレスがコントラクトアドレスかどうかを判断します．

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

### 2.4. ERC165.sol

このファイルには，インターフェイス検知の標準規格である `ERC165` にもとづくメソッドが定義されています．
検知を実装したいコントラクト，検知したいコントラクトに対して継承し，
前者の検知を実装したいコントラクト内で `supportsInterface(bytes4 interfaceId)` 関数を適切に `override` することで検知を行えるようになります．
仕組みについては ERC165，実装方法や検知の仕方については ERC5192 に追記することとします．

### 2.5. IERC5192.sol

SoulBound Token を実装するための EIP 段階の標準になります．

このファイルでは，`interface` という分類の `contract` の中で，`ERC721.sol` 内に存在する関数の中で可視性が `internal` でないものの型定義と，コメントを用いた関数の説明がなされています．

`abstract` と `interface` の違いは，`contract` 内に関数を内包するか否かです．

[ethereum/EIPs/EIPS/eip-5192.md](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5192.md)

### 2.6. IERC721.sol

このファイルでは，`interface` という分類の `contract` の中で，`ERC5192.sol` 内に存在する関数の中で可視性が `internal` でないものの型定義と，コメントを用いた関数の説明がなされています．

`abstract` と `interface` の違いは，`contract` 内に関数を内包するか否かです．

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC721/IERC721.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol)

### 2.7. IERC721Receiver.sol

このファイルでは，ERC5192 トークンを transfer するときに，`to` アドレスが ERC5192 トークンを受け取ることができるかを判断できるものとなっています．
というのも，コントラクトアドレスに送信した NFT というのは基本的には GOX します．
例外として，コントラクトアドレス側に NFT を扱うためのコントラクトが存在する場合に引き出すことが出来るのです．
そのため，不運な GOX を避けるために，NFT の送信を行う際には送信先の `to` アドレスがコントラクトアドレスだった場合にこのインターフェイスが導入されていないものには送れないようにする `_safeTransfer` という送信規格が提案されました．
よって，NFT の送信を受けるためのコントラクトを作りたい場合はこのインターフェイスを継承しておくことが推奨されます．
仕組みについては，`_checkOnERC721Received()` 関数の説明で少しふれます．

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol)

### 2.8. IERC721Metadata.sol

このファイルでは，`interface` という分類の `contract` の中で，

`ERC721.sol` 内で `_name` 変数を参照する `name` 関数，
`ERC721.sol` 内で `_symbol` 変数を参照する `symbol` 関数，
`ERC721.sol` 内で `_baseURI()` の返り値と `tokenId` を参照する `tokenURI` 関数

の三つの関数を型定義しています．

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/IERC721Metadata.sol)

## 3. ERC5192

EIP 段階の IERC5192 をベースに，筆者が実装したものになります．
ERC5192 は大部分が ERC721 と共通のため，共通部分の解説については ERC721 の README をご覧ください．

[unchain-dev/openzeppelin-deepdive/ERC721-related-contracts/README.md](https://github.com/unchain-dev/openzeppelin-deepdive/tree/main/ERC721-related-contracts#readme)

### 3.1. 変数 \_accountLock と 関数 locked

変数定義における ERC721 との違いは，以下の `_accountLock` のみで，これは筆者が EIP をもとに独自に実装した変数になります．
この変数により，ERC5192 は transfer を制限可能な SoulBound Token としての役割を果たせるようになります．

```javascript
mapping(uint256 => bool) private _accountLock;
```

この変数は `uint256` のキーとして渡された `tokenId` が transfer 可能か否かを保存するフラグの役割を果たしています．
ミント時にのみフラグは更新され， `locked` 関数で外部から状態を確認することが出来ます．

`locked` 関数は EIP で提唱された IERC5192 に沿ったもので，関数の内部は筆者が実装をしました．
戻り値として， `tokenId` の transfer がロックされていれば `true` ，ロックされていなければ `false` を返します．

```javascript
function locked(uint256 tokenId) external view override returns (bool) {
    require(_exists(tokenId), "invalid token ID");
    return _accountLock[tokenId];
}
```

### 3.2. \_mint 関数への引数 lock の追加と，それによる \_accountLock の状態の決定

上述の `_accountLock` の状態を決定するため， `_mint` 関数で `lock` するかどうかの引数を受け取り， `_accountLock` に渡します．
このとき，渡した状態を EIP5192 で決められた IERC5192 に倣ってイベントとしてエミットします．

### 3.3. \_accountLock の状態により制限される関数

- approve
- getApproved
- transferFrom
- safeTransferFrom
- safeTransferFrom（引数 data を含むタイプ）
- \_safeTransfer
- \_isApprovedOrOwner
- \_transfer
- \_approve

`_accountLock` によって制限される関数として上記の関数を選んだのも筆者です．
全ての責任は私にあります．OMG

`tokenId` が引数として与えられているものを選定し，機能を制限しました．

## 4. TIPs

### 寄稿をお待ちしております！！

ご覧いただいてきたように， EIP の段階の IERC5192 をもとに，筆者が可能な限り実装してみたものになります．
もし間違いに気が付いた場合には，イシューやプルリクエストにて，お知らせいただけたら幸いです．
