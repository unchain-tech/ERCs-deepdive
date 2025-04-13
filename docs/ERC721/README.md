# ERC721

## 目次

### 1. [はじめに](#1-はじめに)

### 2. [ERC721.sol にインポートされているファイル](#2-erc721sol-にインポートされているファイル)

1. [Address,sol](#21-addresssol)
2. [Context.sol](#22-contextsol)
3. [Strings.sol](#23-stringssol)
4. [ERC165.sol](#24-erc165sol)
5. [IERC721.sol](#25-ierc721sol)
6. [IERC721Receiver.sol](#26-ierc721receiversol)
7. [IERC721Metadata.sol](#27-ierc721metadatasol)

### 3. [ERC721.sol]()

1. [""import""，""using""，変数定義，そして ""constructor""](#31-importusing変数定義そして-constructor)
2. [ストレージ上の値を書き換えることがない ""view"" 関数群](#32-ストレージ上の値を書き換えることがない-view-関数群)
3. [主要な機能の発動を担う標準搭載関数群](#33-主要な機能の発動を担う標準搭載関数群)
4. [挙動を司る関数群，追加実装のための関数群](#34-挙動を司る関数群追加実装のための関数群)

### 4. [TIPs](#4-tips)

## 1. はじめに

ここでは，ERC721.sol とその中でインポートされている 7 つを含めた 8 つの sol ファイルについて，順番にコードベースでよみとくことによって ERC721 を完全に理解することを目指します．

しかし，この README.md ファイルではコードは極力使わず，実際にコードを読み解く sol ファイル群へのリンクは添えたうえで，日本語ベース・ノーコードでなるべく簡潔な解説を行っていきます．

> 尚，Solidity の文法に関してはある程度前提としていますが，Solidity のハンズオンラーニングの手段ともなりえるように，検索可能な用語を用いることを心掛けることとします．

## 2. ERC721.sol にインポートされているファイル

以下では，`ERC721.sol` でインポートされているそれぞれのファイルについて，おおまかな内容と `ERC721.sol` 内での用途を説明していきます．
レポジトリ内の同名ファイルには，原本に適宜コメントを追加したファイルを同梱してあります．ご活用ください．

### 2.1. Address,sol

このファイルでは， `address` 型の変数に関する関数を集めた `Address` ライブラリを定義しています．
ERC721 における用途は，`isContract()` の利用です．この関数は `address` 値を引数にとり，そのアドレス長が 0 より大きいかどうかを `bool` 値で返します．こうすることで，4 種ほどの例外を除き，引数のアドレスがコントラクトアドレスかどうかを判断します．

> この例外というのはコントラクトが機能しない特殊な状況にある場合です．なので，実質的にはコントラクトが利用可能な状態であるかどうかを示すものになります．そして，コントラクトとウォレットアドレス(EOA アドレス)は形式が同じであるため，仮に存在するウォレットアドレスを引数としたとしても `isContract()` は `true` を返すと思われます．

↓ 元ファイル

[openzeppelin-contracts/contracts/utils/Address.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)

### 2.2. Context.sol

このファイルでは，`abstract` という分類の `contract` の中で，`msg.sender` という宣言をラップする `_msgSender`という関数を宣言しています．

わざわざ関数でラップしているのはなぜかというと，メタトランザクションスキームを用いる場合に `msg.sender` をそのまま使うのは都合が悪いからです．

以下に簡単な説明をのせておきます．詳しくは[ここ](https://github.com/unchain-dev/openzeppelin-deepdive/tree/main/metatx#2-meta-transaction%E3%81%A8%E3%81%AF-1)を参照してください．

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
仕組みについては ERC165，実装方法や検知の仕方については ERC721 に追記することとします．

### 2.5. IERC721.sol

このファイルでは，`interface` という分類の `contract` の中で，`ERC721.sol` 内に存在する関数の中で可視性が `internal` でないものの型定義と，コメントを用いた関数の説明がなされています．

`abstract` と `interface` の違いは，`contract` 内に関数を内包するか否かです．

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC721/IERC721.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol)

### 2.6. IERC721Receiver.sol

このファイルでは，ERC721 トークンを transfer するときに，`to` アドレスが ERC721 トークンを受け取ることができるかを判断できるものとなっています．
というのも，コントラクトアドレスに送信した NFT というのは基本的には GOX します．
例外として，コントラクトアドレス側に NFT を扱うためのコントラクトが存在する場合に引き出すことが出来るのです．
そのため，不運な GOX を避けるために，NFT の送信を行う際には送信先の `to` アドレスがコントラクトアドレスだった場合にこのインターフェイスが導入されていないものには送れないようにする `_safeTransfer` という送信規格が提案されました．
よって，NFT の送信を受けるためのコントラクトを作りたい場合はこのインターフェイスを継承しておくことが推奨されます．
仕組みについては，`_checkOnERC721Received()` 関数の説明で少しふれます．

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol)

### 2.7. IERC721Metadata.sol

このファイルでは，`interface` という分類の `contract` の中で，

`ERC721.sol` 内で `_name` 変数を参照する `name` 関数，
`ERC721.sol` 内で `_symbol` 変数を参照する `symbol` 関数，
`ERC721.sol` 内で `_baseURI()` の返り値と `tokenId` を参照する `tokenURI` 関数

の三つの関数を型定義しています．

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/IERC721Metadata.sol)

## 3. ERC721

### 3.1. ""import""，""using""，変数定義，そして ""constructor""

さぁ，それでは本体である `ERC721.sol` についてみていきましょう．

まず最初に，先程紹介した 7 つの `.sol` ファイルを import した後，そのうち `interface`， `abstract contract` を `ERC721` という `contract` に継承させています．

次に，`ERC721` の内部をみていきましょう．

最初に `using` コマンドでライブラリの使用を宣言しています．
次に，変数，マッピングを宣言しています．
そして，`constructor` で変数群を初期化しています．

```javascript
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    // ライブラリの使用を宣言
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // トークンID→所有者アドレス のマッピング
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // 所有者アドレス→保有枚数 のマッピング
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // トークンID→移転許可所有アドレス のマッピング
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // 所有者アドレスから移転許可所有アドレス，そして許可の有無へのダブルマッピング
    // 移転許可所有アドレスを登録する時にマッピングしておいて，
    // 許可移転する時に許可の有無を確認する時に使う
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        // トークン名，トークンシンボルを初期化
        _name = name_;
        _symbol = symbol_;
    }
```

### 3.2. ストレージ上の値を書き換えることがない ""view"" 関数群

さて，ここから関数の記述が始まります．

まず記述されるのが，ストレージの値を書き換えることのない `view` 関数群です．
これらは，おおまかにいえば 4 つに区分できます．

- ERC165 の機能を司る `supportsInterface()` 関数
- 上で定義してあった`mapping` に格納された値を参照する `balanceOf()`，`ownerOf` 関数
- 同じくうえで定義してあった変数を参照する `name()`，`symbol()` 関数
- tokenURI(メタデータ) を定義・参照するための `tokenURI()`，`_baseURI()` 関数

> 最後の `_baseURI()` 関数については少し特殊で，この関数はかなり簡単な作りになっており，作成者によってメタデータの扱いを大きく変えることができます．
> 例えば，`return ""` 内に任意の URL を入力しておけば単にそのアドレスから取得できる画像を表示するという実装になり，他方関数外に `string private baseURI` などの変数，そして変数を書き換える関数を定義し，`return ""` 部分を `return baseURI` として `name()` 変数と同様にその変数を呼び出すような形にしておけば，メタデータを後々変更することが可能な NFT を実装できます．

```javascript
    // ERC165の本体．
    // 引数に取ったinterfaceId(interface の識別子)が，ERC165が実装されたコントラクトまたは
    // 実装したコントラクトに継承したコントラクト内に実装されているか調べることができる．
    // 具体的には，まず，ERC165を実装したコントラクト内でERC165内で定義されたsupportsInterface(bytes4 interfaceId)関数をオーバーライドして，
    // 実装したコントラクトに継承するインターフェイスのIDと引数との等価演算全種を行い，
    // 継承されているコントラクトの中にERC165が実装されていた場合，そのコントラクトでも同様な等価演算全種を行う．
    // 最後に行われた全ての等価演算の結果の論理和をとって，返り値として返している．
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // 上で定義した_balancesマッピングの中身を参照する関数．
    // アドレスがもつ(このコントラクトで規定された)NFTの総数を返す．
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    // 上で定義した_ownersマッピングの中身を参照する関数．
    // 引数にとったトークンIDのNFT(もちろんこれもこのコントラクトで規定されたもののIdのこと)の所有者となっているアドレスを返す．
    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    // 上で定義したトークン名を参照する関数．
    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // 同じくうえで定義したトークンシンボルを参照する関数
    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // 下で定義する_baseURI()関数の返り値を参照する関数．
    // この返り値，すなはち_baseURI()関数の中身が俗にいうメタデータである．
    // 実際にはそれだけではなく，_requireMinted関数でミントされているか確認されたり，
    // return時にメタデータが空でないか確認されたりしている．
    // それを満たさなかった場合，revertされることになる．
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    // 上で言及したメタデータの中身．
    // 初期値では空になっている(空stringを返す)．
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
```

### 3.3. 主要な機能の発動を担う標準搭載関数群

次に記述されていくのは，主要な機能の発動を担う関数群です．
発動と表したのは，これらの関数群の挙動は `internal` 関数を呼び出す形で外部に記述されているからです．
それらの関数を呼び出すほかには， `require` 文で発動時の条件を付加したり，呼び出しに必要なローカル変数を定義したりしています．

- token 移送許可に関係する `approve()`，`getApproved()`，`setApprovalForAll()`，`isApprovedForAll` 関数
- 許可を受けた移送を実際に行う `transferFrom()`，`safeTransferFrom()` 関数

```javascript
    // tokenの現ownerがtoアドレスに対してtokenの移送許可を与える関数
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        // tokenIdのownerをマッピングから参照
        address owner = ERC721.ownerOf(tokenId);
        // toアドレスがownerアドレスと同一でないか確認．
        // 同一ならrevert．
        require(to != owner, "ERC721: approval to current owner");


        // トランザクション送信者が当該tokenのownerまたは移送許可を受けた者であるか確認
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        // 移送許可情報が記録されているマッピングを更新
        _approve(to, tokenId);
    }

    // token移送許可情報を参照する関数．
    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        // mintされているものかを確認
        _requireMinted(tokenId);

        // 移送許可情報が記録されているマッピングを参照
        return _tokenApprovals[tokenId];
    }

    // token移送許可を与える関数．
    // approveより上位の許可として定義されている模様
    // デフォルトでは使い道がないが，追加実装で活きてくる可能性がある．
    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        // 挙動を司る子関数を呼び出している
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    // operatorとして渡されたアドレスが上位許可``_operatorApprovals`` を有しているか確認する関数．
    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        // 移送許可情報が記録されているマッピングを参照
        return _operatorApprovals[owner][operator];
    }

    // 移送許可に準じたtoken移送を行う関数
    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        // 移送許可があるかどうかを確認
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        // 挙動を司る子関数を呼び出している
        _transfer(from, to, tokenId);
    }

    // transferFrom関数にERC165を適用した関数．
    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // 直下の関数を呼び出している
        safeTransferFrom(from, to, tokenId, "");
    }

    // caldataを引数として渡すために直上のsafeTransferFromが分割されたもの．
    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        // 移送許可があるかどうかを確認
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        // 挙動を司る関数を呼び出している
        _safeTransfer(from, to, tokenId, data);
    }

```

### 3.4. 挙動を司る関数群，追加実装のための関数群

残るは，上記の機能発動関数群に呼び出される関数と，いくつかの追加実装をサポートする関数を残すのみとなりました
．
直下に挙げるのは，全て挙動を司る関数です．
`_exists` だけ，初出の関数で，困惑する方がでないようことわっておくと，`_requireMinted` の挙動を司るものです．

- `_safeTransfer()`，`_exists()`，`_isApprovedOrOwner()`，`_transfer()`，`_approve()`，`_setApprovalForAll()`，`_requireMinted()`，`_checkOnERC721Received()`

そして直下の 3 関数は，準標準関数の挙動を司るものといえるでしょう．
挙動を呼び出す `safeMint()`，`burn()` のような関数内でこれらを呼び出しておけば使えるようになります．
mint 系の 2 つについては，NFT の発行のためにいずれかを必ず実行する必要がありますが，`constructor` 内で呼び出すことが可能なため，直コンできる機能発動のための `public` 関数として定義しておく必要はありません．

> このあたりについてコラムで触れているので，気になる方は[4 章]()を参照してください．

- `_safeMint()`，`_mint()`，`_burn()`

残る直下の 2 関数については， トークンの移動が行われる `_mint()`，`_transfer()` 関数のメソッド実行前と実行後に行う挙動を追加するためのものとなっています．

- `_beforeTokenTransfer()`，`_afterTokenTransfer()`

```javascript
    // transfer関数にERC721Rceiverを適用した関数．
    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        // 挙動を司る子関数を呼び出している
        _transfer(from, to, tokenId);
        // 送信先がコントラクトでかつERC721Receiverを採用していない場合revertする
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // _requireMinted()関数の子関数．
    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        // tokenIdのownerが存在するか確認している
        // Solidityでは大抵のパラメータの初期値は0になっているため，
        // 0アドレスと該当Idで参照した_owners[]マッピングの返り値(_owners[tokenId])を照合する
        return _owners[tokenId] != address(0);
    }

    // 文字通り，引数アドレスが引数Idのトークンのオーナーもしくは移送許可保持者であればtrueを返す関数．
    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        // マッピングを用いてIdからオーナーアドレスを参照しローカル変数に定義
        address owner = ERC721.ownerOf(tokenId);
        // 引数のアドレスとオーナー，上位移送許可の有無，そして通常移送許可の有無についての真偽演算を論理和にかける
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    // _mint関数にERC721Rceiverを適用した関数．
    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        // 直下の子関数を呼び出している
        _safeMint(to, tokenId, "");
    }

    直上から呼び出される子関数．
    ERC721Rceiverを適用している．
    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        // 挙動を司る子関数を呼び出している
        _mint(to, tokenId);
        // ERC721Receiverのメソッドを呼び出している
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    // トークンミントを行う時に実行されるメソッド．
    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        // ミント先が0アドレスでないことを確認
        require(to != address(0), "ERC721: mint to the zero address");
        // 既にミントされていないか確認する子関数を呼び出している
        require(!_exists(tokenId), "ERC721: token already minted");

        // トークンの移動前に実行されるメソッドを呼び出す
        _beforeTokenTransfer(address(0), to, tokenId);

        // 関係するマッピングの値を適切に変更している
        _balances[to] += 1;
        _owners[tokenId] = to;

        // フロントエンド等に向けたeventをemitしている
        emit Transfer(address(0), to, tokenId);

        // トークンの移動後に実行されるメソッドを呼び出す
        _afterTokenTransfer(address(0), to, tokenId);
    }

    // トークンをburnする関数
    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        // 引数をローカル変数に格納
        address owner = ERC721.ownerOf(tokenId);

        // トークンの移動前に実行されるメソッドを呼び出す
        _beforeTokenTransfer(owner, address(0), tokenId);

        // 移送許可のマッピングの中身を削除(値を初期値の0に)している
        // Clear approvals
        delete _tokenApprovals[tokenId];

        // 関係するマッピングを適切に変更している
        _balances[owner] -= 1;
        delete _owners[tokenId];

        // フロントエンド等に向けたeventをemitしている
        emit Transfer(owner, address(0), tokenId);

        // トークンの移動後に実行されるメソッドを呼び出す
        _afterTokenTransfer(owner, address(0), tokenId);
    }

    // トークン移送の挙動を司る関数
    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        // 引数tokenIdのトークンownerが引数のfromと一致しているか確認する
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        // 移送先が0アドレスでないことを確認
        require(to != address(0), "ERC721: transfer to the zero address");

        // トークンの移動前に実行されるメソッドを呼び出す
        _beforeTokenTransfer(from, to, tokenId);

        // 移送許可のマッピングの中身を削除(値を初期値の0に)している
        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        // 関係するマッピングを適切に変更している
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        // フロントエンド等に向けたeventをemitしている
        emit Transfer(from, to, tokenId);

        // トークンの移動後に実行されるメソッドを呼び出す
        _afterTokenTransfer(from, to, tokenId);
    }

    // トークン移送許可付与の挙動を司る関数．
    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        // 関係するマッピングを適切に変更している
        _tokenApprovals[tokenId] = to;
        // フロントエンド等に向けたeventをemitしている
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    // 上位のトークン移送許可の付与の挙動を司る関数．
    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        // 移送許可の付与先がトークン保有者出ないことを確認
        require(owner != operator, "ERC721: approve to caller");

        // 関係するマッピングを適切に変更している
        _operatorApprovals[owner][operator] = approved;
        // フロントエンド等に向けたeventをemitしている
        emit ApprovalForAll(owner, operator, approved);
    }

    // 引数のtokenIdを持つトークンがミントされているかどうかを確認する関数
    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        // 挙動を司る子関数を呼び出している
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    // ERC721Rceiverが適用された関数上で適切な操作を施すための関数
    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        // if文の条件節でAddressライブラリから引用した関数の真偽演算を行い，
        // 引数のtoアドレスがコントラクトかどうか確認
        // コントラクトでないならelse文でtrueを返す
        if (to.isContract()) {
            // 当該コントラクトERC721Rceiverを実装しているか確かめる
            // 実装されていれば関数のセレクター(関数識別子)が返ってくるので，真偽演算で判定する
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                // onERC721Receiverの正しい関数識別子を呼び出し，to上での当該関数識別子呼び出しと比較
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                // reasonのlengthプロパティを参照
                // 空ならばカスタムエラーは存在しない
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                // 空でない場合，カスタムエラーが存在するので，
                // エラー内容をアセンブリrevertでキャッチする
                // https://ethereum.stackexchange.com/questions/133748/trying-to-understand-solidity-assemblys-revert-function
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // トークンの移動前に実行されるメソッドを呼び出す．
    // デフォルトでは空．
    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    // トークンの移動後に実行されるメソッドを呼び出す．
    // デフォルトでは空．
    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
```

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC721/ERC721.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol)

## 4. TIPs

### 寄稿をお待ちしております！！
