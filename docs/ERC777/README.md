# ERC777

- [ERC777](#erc777)
  - [1. はじめに](#1-はじめに)
  - [2. インポートされているファイル](#2-インポートされているファイル)
    - [2.1 IERC777.sol](#21-ierc777sol)
    - [2.2 IERC777Recipient.sol](#22-ierc777recipientsol)
    - [2.3 IERC777Sender.sol](#23-ierc777sendersol)
    - [2.4 IERC20.sol](#24-ierc20sol)
    - [2.5 Address.sol](#25-addresssol)
    - [2.6 Context.sol](#26-contextsol)
    - [2.7 IERC1820Registry.sol](#27-ierc1820registrysol)
  - [3. ERC777.sol](#3-erc777sol)
    - [3.1. import, 変数定義から constructor まで](#31-import-変数定義から-constructor-まで)
    - [3.2. ブロックチェーン上の変数を参照する view 関数群](#32-ブロックチェーン上の変数を参照する-view-関数群)
    - [3.3. 標準搭載関数群](#33-標準搭載関数群)
    - [3.4. メソッド記述と追加機能実装を担う internal 関数群](#34-メソッド記述と追加機能実装を担う-internal-関数群)
  - [4. ERC20 との比較](#4-erc20-との比較)
    - [データ](#データ)
    - [フック](#フック)
    - [オペレータ](#オペレータ)
    - [まとめ](#まとめ)
  - [5. 後方互換性について](#5-後方互換性について)

## 1. はじめに

ここでは，ERC777.sol とその中でインポートされている 7 つを含めた 8 つの sol ファイルについて，順番にコードベースで読み解くことによって ERC777 を完全に理解することを目指します．

しかし，この README.md ファイルではコードは極力使わず，実際にコードを読み解く sol ファイル群へのリンクは添えたうえで，日本語ベース・ノーコードでなるべく簡潔な解説を行っていきます．

> 尚，Solidity の文法に関してはある程度前提としていますが，Solidity のハンズオンラーニングの手段ともなりえるように，検索可能な用語を用いることを心掛けることとします．

## 2. インポートされているファイル

### 2.1 IERC777.sol

このファイルでは，`interface` という分類の `contract` の中で，可視性が `private` でないものの ERC777 の型定義と，コメントを用いた関数の説明がなされています．

`abstract` と `interface` の違いは，`contract` 内に関数を内包するか否かです．

↓ 元ファイル

[openzeppelin-contracts/blob/master/contracts/token/ERC777/IERC777.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC777/IERC777.sol)

### 2.2 IERC777Recipient.sol

このファイルの中身は ERC777 内でトークン転送時に実行されるフック `tokensReceived` を定義する `interface` です.

`tokensReceived` は ERC777 トークンがアカウント A からアカウント B に移動した後に, B が実行したい処理を実装するための関数です.

例えば, B は特定の条件下では A からのトークン転送を拒否するなどの処理を組み込むことが可能です.

↓ 元ファイル

[openzeppelin-contracts/blob/master/contracts/token/ERC777/IERC777Recipient.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC777/IERC777Recipient.sol)

### 2.3 IERC777Sender.sol

このファイルの中身は ERC777 内でトークン転送時に実行されるフック `tokensToSend` を定義する `interface` です.

`tokensToSend` は ERC777 トークンがアカウント A からアカウント B に移動する前に, A が実行したい処理を実装するための関数です.

例えば, A は特定の条件下ではトークン転送を中止するなどの処理を組み込むことが可能です.

↓ 元ファイル

[openzeppelin-contracts/blob/master/contracts/token/ERC777/IERC777Sender.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC777/IERC777Sender.sol)

### 2.4 IERC20.sol

このファイルの中身は ERC20 の `interface` です.

ERC777 は ERC20 との後方互換性を保っているため, ERC20 の機能も実装するためにインポートしています.

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC20/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol)

### 2.5 Address.sol

このファイルでは， `address` 型の変数に関する関数を集めた `Address` ライブラリを定義しています．
ERC777 における用途は，`isContract()` の利用です．この関数は `address` 値を引数にとり，そのアドレス長が 0 より大きいかどうかを `bool` 値で返します．こうすることで，4 種ほどの例外を除き，引数のアドレスがコントラクトアドレスかどうかを判断します．

> この例外というのはコントラクトが機能しない特殊な状況にある場合です．なので，実質的にはコントラクトが利用可能な状態であるかどうかを示すものになります．そして，コントラクトとウォレットアドレス(EOA アドレス)は形式が同じであるため，仮に存在するウォレットアドレスを引数としたとしても `isContract()` は `true` を返すと思われます．

↓ 元ファイル

[openzeppelin-contracts/contracts/utils/Address.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)

### 2.6 Context.sol

このファイルでは，`abstract` という分類の `contract` の中で，`msg.sender` という宣言をラップする `_msgSender`という関数を宣言しています．

わざわざ関数でラップしているのはなぜかというと，メタトランザクションスキームを用いる場合に `msg.sender` をそのまま使うのは都合が悪いからです．

以下に簡単な説明をのせておきます．詳しくは[ここ](https://github.com/unchain-dev/openzeppelin-deepdive/tree/main/metatx#2-meta-transaction%E3%81%A8%E3%81%AF-1)を参照してください．

> `msg.sender` は EVM に規定されたグローバル変数なので書き換えできませんが，関数の中に `msg.sender` をラップした `_msgSender()` 関数を使うことによって，メタトランザクション使用時には `_msg.sender()` 関数をオーバーライドして返り値を書き換えることにより `msg.sender(gas feeを支払うアドレス)` と `_msgSender()の返り値(txを実行したいアドレス)` を分けることができるようになります．

↓ 元ファイル

[openzeppelin-contracts/contracts/utils/Context.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol)

### 2.7 IERC1820Registry.sol

このファイルの中身は ERC1820 Registry の `interface` です.

ERC1820 Registry は, 任意のアカウントが「あるインタフェースとそのインタフェースを実装したコントラクト」を登録することを可能にします.

[IERC777Recipient](#22-ierc777recipientsol)と[IERC777Sender](#23-ierc777sendersol)のインタフェースとそのインタフェースを実装したコントラクトが任意のアカウントによって登録されているかの判定に使用します.

例えば, アカウント A が B にトークンを転送する際に, A は`tokensToSend`を実装したコントラクトを用意(登録)しているか, B は`tokensReceived`を実装したコントラクトを用意(登録)しているかが ERC777 コントラクト内部でチェックされます.

↓ 元ファイル

[openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC1820Registry.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC1820Registry.sol)

## 3. ERC777.sol

それでは本体である `ERC777.sol` についてみていきましょう．

ERC777 という規格は, ERC-20 との後方互換性を保ちつつ, トークンコントラクトと対話するための新しい方法を定義しています.

特に新しい概念が以下の２つです.

- オペレータ: トークンを送信・発行・焼却するアカウント
  トークンを保有するアカウント A のオペレータは A でもあり, 他のアカウント B をオペレータに追加することも可能です.
  つまり B が(A のオペレータに登録されているのならば) A の保有するトークンを転送することも可能です.

- フック関数(`tokensToSend`/`tokensReceived`): トークンの転送時に実行されるフック関数
  `tokensToSend`: トークン保有者が自分のトークンが減少する際に実行したい処理
  `tokensReceived`: トークン受信者が自分のトークンが増加する際に実行したい処理

### 3.1. import, 変数定義から constructor まで

まず最初に，先程紹介した `.sol` ファイルを import した後，必要な `contract` を `ERC777` という `contract` に継承させています．

```javascript
import "./IERC777.sol";
import "./IERC777Recipient.sol";
import "./IERC777Sender.sol";
import "../ERC20/IERC20.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/IERC1820Registry.sol";

contract ERC777 is Context, IERC777, IERC20 {
```

そして，ライブラリの使用の宣言と, 後に使用する ERC1820 Registry のインスタンス用意.

```javascript
    // ライブラリの使用を宣言.
    using Address for address;

    // ERC1820 Registryをインスタンス化.
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
```

各グローバル変数を定義．

```javascript
    // このマッピングがトークン残高の本体．名付けるならトークン残高．
    mapping(address => uint256) private _balances;

    // 文字通り，総供給量.
    uint256 private _totalSupply;

    // トークンネームとトークンシンボルの箱．
    string private _name;
    string private _symbol;

    // インタフェースのハッシュ値を保存.
    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // 全てのholderに適用されるデフォルトのoperatorリスト.
    address[] private _defaultOperatorsArray;

    // このマッピングは, 任意のアドレスがデフォルトoperatorであるかを判別するために使用される.
    mapping(address => bool) private _defaultOperators;

    // これらのマッピングは, アドレスAに対してアドレスBがoperatorであるかを判別するために使用される.
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    // このマッピングは，後述のtransferFrom関数で使われる．名付けるなら引き出し許可残高．
    mapping(address => mapping(address => uint256)) private _allowances;
```

続いて，デプロイ時に string 変数とデフォルトオペレータを初期化する `constructor` が定義されています．

`constructor`内の最後にはこのコントラクトが`ERC777Token`と`ERC20Token`を実装していることを ERC1820 Registry に登録しています.
この処理はトークンコントラクトが ERC777 の機能を実装している・ERC20 の機能を実装しているを利用者が判定するためのものです.

```javascript
    constructor(string memory name_, string memory symbol_, address[] memory defaultOperators_) {
        _name = name_;
        _symbol = symbol_;

        _defaultOperatorsArray = defaultOperators_;
        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _defaultOperators[defaultOperators_[i]] = true;
        }

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }
```

### 3.2. ブロックチェーン上の変数を参照する view 関数群

その後に，関数が定義されていきます．

まずは，変数を変更(変数に代入)できない `view` 関数で，処理が少ないものが定義されています．

```javascript
    // トークンネームを参照する関数
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // トークンシンボルを参照する関数
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // decimalsを返す関数．
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    // トークンが分割できる最小単位を返却する関数.
    function granularity() public view virtual override returns (uint256) {
        return 1;
    }

    // 総供給量を参照する関数．
    function totalSupply() public view virtual override(IERC20, IERC777) returns (uint256) {
        return _totalSupply;
    }

    // 最初の方で定義された_balancesマッピングから，該当アドレスにおける該当トークン残高を参照する関数．
    function balanceOf(address tokenHolder) public view virtual override(IERC20, IERC777) returns (uint256) {
        return _balances[tokenHolder];
    }
```

### 3.3. 標準搭載関数群

次に，`ERC777` のトークン操作のトリガーとなる関数とオペレータに関わる関数が定義されます．

トークン操作のトリガーとなる関数は, 次章で解説する実際の操作が記述された `internal` 関数をメソッドとして呼び出しています．

メソッドとトリガーと分ける理由は，複雑な関数を定義したいデベロッパーへの配慮のためでしょう．これにより，基本機能だけを用いたいデベロッパーは標準搭載関数で手間なく実装が完了でき，複雑な関数を定義したいデベロッパーは基本機能のメソッドが記述された `internal` 関数を骨組みとした複雑な関数の定義を容易に行えます．

```javascript
    // トークンを送信する関数．
    // ERC20でトークン送信に使用されるtransferとは定義を明確に分けるためにsendという名前で定義されている.
    function send(address recipient, uint256 amount, bytes memory data) public virtual override {
        _send(_msgSender(), recipient, amount, data, "", true);
    }

    // トークンを送信する関数.
    // ERC20との後方互換性のために実装されている.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _send(_msgSender(), recipient, amount, "", "", false);
        return true;
    }

    // トークンを焼却する関数．
    function burn(uint256 amount, bytes memory data) public virtual override {
        _burn(_msgSender(), amount, data, "");
    }

    // 引数の`operator`と`tokenHolder`の間にoperatorとholderの関係があるか否かを返却する関数.
    function isOperatorFor(address operator, address tokenHolder) public view virtual override returns (bool) {
        return
            operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }

    // 引数の`operator`を, 関数を呼び出したアカウントのoperatorとして認証する関数.
    function authorizeOperator(address operator) public virtual override {
        require(_msgSender() != operator, "ERC777: authorizing self as operator");

        if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[_msgSender()][operator];
        } else {
            _operators[_msgSender()][operator] = true;
        }

        emit AuthorizedOperator(operator, _msgSender());
    }

    // 引数の`operator`を, 関数を呼び出したアカウントのoperatorから削除する関数.
    function revokeOperator(address operator) public virtual override {
        require(operator != _msgSender(), "ERC777: revoking self as operator");

        if (_defaultOperators[operator]) {
            _revokedDefaultOperators[_msgSender()][operator] = true;
        } else {
            delete _operators[_msgSender()][operator];
        }

        emit RevokedOperator(operator, _msgSender());
    }

    // デフォルトoperatorを返却する関数.
    function defaultOperators() public view virtual override returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    // operator(msg.sender)がholder(引数では`sender`)に代わってトークンを送信する関数.
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), sender), "ERC777: caller is not an operator for holder");
        _send(sender, recipient, amount, data, operatorData, true);
    }

    // operator(msg.sender)がholder(引数では`account`)に代わってトークンを焼却する関数.
    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), account), "ERC777: caller is not an operator for holder");
        _burn(account, amount, data, operatorData);
    }

    // allowance(引き出し許可残高)を参照する関数．
    // ERC20との後方互換性のために実装されている.
    function allowance(address holder, address spender) public view virtual override returns (uint256) {
        return _allowances[holder][spender];
    }

    // 引き出し許可残高を変更する関数．
    // ERC20との後方互換性のために実装されている.
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address holder = _msgSender();
        _approve(holder, spender, value);
        return true;
    }

    // 引き出し許可をもとに，自分のアドレスに他のアドレスから残高を移動させる関数．
    function transferFrom(address holder, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(holder, spender, amount);
        _send(holder, recipient, amount, "", "", false);
        return true;
    }
```

### 3.4. メソッド記述と追加機能実装を担う internal 関数群

最後に，先ほどのトリガー関数のメソッドを記述するためのものや追加実装を行うためのものからなる `internal` 関数群が定義されています．

※`internal` という修飾子は関数の可視性(`public`, `private`, `internal`, `external`)を表しています．これついては[ここ](https://qiita.com/ryu-yama/items/fae7e502d1bd5f0707b0)を見るとよいでしょう．

```javascript
    // _mint関数(後に説明がなされる)を呼び出す関数．
    function _mint(address account, uint256 amount, bytes memory userData, bytes memory operatorData) internal virtual {
        _mint(account, amount, userData, operatorData, true);
    }

    // トークンmint(貨幣発行)の仕組みがかいてある．
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(account != address(0), "ERC777: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, amount);

        // Update state variables
        _totalSupply += amount;
        _balances[account] += amount;

        _callTokensReceived(operator, address(0), account, amount, userData, operatorData, requireReceptionAck);

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    // トークン転送(送金)の流れが書いてある．
    function _send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(from != address(0), "ERC777: transfer from the zero address");
        require(to != address(0), "ERC777: transfer to the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, to, amount, userData, operatorData);

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }

    // トークンburn(貨幣の消去，焼却)の仕組みがかいてある．
    function _burn(address from, uint256 amount, bytes memory data, bytes memory operatorData) internal virtual {
        require(from != address(0), "ERC777: burn from the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, address(0), amount, data, operatorData);

        _beforeTokenTransfer(operator, from, address(0), amount);

        // Update state variables
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: burn amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _totalSupply -= amount;

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    // トークン転送(送金)の仕組みが書いてある.
    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        _beforeTokenTransfer(operator, from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    // トークン引き出し許可更新の仕組みがかいてある．
    // ERC20との後方互換性のために実装されている.
    function _approve(address holder, address spender, uint256 value) internal virtual {
        require(holder != address(0), "ERC777: approve from the zero address");
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    // アカウントのトークンが減少(_send, _burn)する際にトークンの残高操作前に呼び出される.
    // フックを実行する関数.
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(from, _TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }

    // アカウントのトークンが増加(_mint, _send)する際にトークンの残高操作後に呼び出される.
    // フックを実行する関数.
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(to, _TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (requireReceptionAck) {
            require(!to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
    }

    // トークン引き出し許可残高を減らす関数.
    // ERC20との後方互換性のために実装されている.
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC777: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    // トークンの操作を行う関数(_mint, _burn, _move関数)の実行前に行いたい動作を設定できる．
    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount) internal virtual {}
```

↓ 元ファイル

[openzeppelin-contracts/blob/master/contracts/token/ERC777/ERC777.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC777/ERC777.sol)

## 4. ERC20 との比較

以下に ERC20 と比較して ERC777 が改善した主要な点を示す.

### データ

ERC777 の mint, send, burn 処理はすべてデータおよびオペレータデータフィールドを利用することができます.

これらのフィールドは単純なユースケースでは空かもしれませんが, トークンの転送に関連する貴重な情報を含めることも可能です.

つまり, データの内容によって処理を変化させるなど, ERC20 に比べてトークン転送プロセスを多様化させることが可能です.

### フック

ERC777 の規格には, トークン転送時に実行されるフック関数という概念が存在します.

- `tokensToSend`: トークン保有者が自分のトークンが減少する際に実行したい処理を記述するフック関数

- `tokensReceived`: トークン受信者が自分のトークンが増加する際に実行したい処理を記述するフック関数

以上を前提にトークンの転送について ERC20 と ERC777 を比較します.

ERC20 でトークンを転送する方法として以下の 2 つがあります.

アカウント A のトークンがアカウント B に転送される場合

- A が`transfer`関数を使用して B へ送信する

- A が`approve` 関数を使用して B へトークンを移動する権限を与え, B が`transferFrom` 関数を使用してトークンを転送する

1 つ目 の方法の懸念点として, A がトークンの送信先アドレスを間違える可能性があり, 間違えた宛先が「A からトークンを受信することを想定していないコントラクト」の場合は送信されたままトークンが「動かせなくなる」=「ロックされる」可能性があります.

2 つ目 の方法は, 受信者が転送アクションを起こすため 1 つ目の方法に比べ比較的安全な転送になりますが, 2 つのトランザクションが必要なため当事者間でのコミュニケーションが生じます.

これに対し, ERC777 でトークンを転送する際, 全ての転送プロセス(mint, send, operatorSend, transfer, transferFrom, burn, operatorBurn)に以下の処理が実装されることが明確に定義されています.

ある転送プロセスによって, アカウント A のトークンがアカウント B に転送される場合

1. A が `tokensToSend` を実装したコントラクトを用意していれば(ERC1820 Registry に登録していれば), `tokensToSend` を実行.
   `tokensToSend`内では, トランザクション情報を精査して特定の条件下ではトランザクションをキャンセルするなどの処理を書くことができます.

1. A のトークン残高を減らし, B のトークン残高を増やす.

1. B が `tokensReceived` を実装したコントラクトを用意していれば(ERC1820 Registry に登録していれば), `tokensReceived` を実行.
   `tokensToSend`内では, トランザクション情報を精査して特定の条件下ではトランザクションをキャンセルするなどの処理を書くことができます.

よって, 毎回のトークン転送において, トークン保有者とトークン受信者の両側で必要に応じてトランザクション内容のチェックが行われるため, トークンの誤送信を最小限に防ぐことができます.

また, アカウント B(トークン受信者)がコントラクトの場合は誤送信によってトークンがロックされる可能性が高まるため, B がコントラクトの場合は`tokensReceived`を用意しておくことが強制されています.
※ ERC20 との互換性のために実装されている transfer, transferFrom では強制されていません.

処理の流れは明確に定義されていますが, フック関数の実装内容は自由なので柔軟性があります.

また, 上記の転送処理が 1 つのトランザクションで行われることも当事者間の不要なコミュニケーションを削減できるという利点があります.

### オペレータ

ERC777 の規格には, ホルダーとオペレータという概念が存在し, トークンを保有するアカウントをホルダー, トークンを転送(発行/送信/焼却)するアクションを実際に起こすアカウントをオペレータと呼びます.

ホルダー A のオペレータは A でもあり, 他のアカウント B をオペレータに追加することも可能です.

つまり B が(A のオペレータに登録されているのならば) A の保有するトークンを転送することも可能です.

ERC20 では, `approve`関数を使用することで同じようなことが実現可能ですが, ERC777 のように「トークン保有者」と「転送アクションを起こすアカウント」に明確な関係性は定義されていません.

アカウント間に明確な関係性を定義することは, 各アカウントの役割をわかりやすくし, トークンコントラクトの機能を利用する際の混乱を間違いを避けられます.

例えば, ERC777 において, ホルダーがトークンを送信するときには`send`関数を使用し, オペレータがトークンを送信するときには`operatorSend`関数を使用します.
アカウントの役割が明確化されていることで, ホルダー・オペレータはそれぞれどの関数を使用してトークンを送信すれば良いのかわかりやすいです.

### まとめ

※ 個人の意見です.

ERC777 は, 上記の ERC20 の改善点が実装されている分, ERC20 よりも中身は複雑です.
懸念点としては, 利用者は機能の理解をするというハードルがあること, 毎トランザクションで ERC20 にはなかった処理が入ることによるガス代の増加(正確にどれくらいかは把握できていません)が挙げられると思います.

それでも上記の ERC20 の改善点がトークン利用者に必要とされる場合, 特にトークンの誤送信が問題として顕著に表れるなどは現実的そうですが, ERC777 の普及の可能性はあると思います.

↓ 情報源

[EIP777 Rationale](https://eips.ethereum.org/EIPS/eip-777#rationale)

## 5. 後方互換性について

この規格では ERC20 の関数 transfer, transferFrom, approve, allowance を並行して実装することで ERC-20 と完全互換のトークンとすることができます.

また, 標準のトークンの送信関数として transfer と transferFrom を使用せず,send と operatorSend を使用し, どのトークン規格(ERC777/ERC20)が使用されているかを解読する際の混乱や間違いを避けるようにしています.

ERC20 で規定されているイベント Transfer に対して, ERC777 では Sent/Minted/Burned が規定されています.
ERC777 のコントラクト利用者は, コントラクトを ERC20 として使用する場合は Transfer について考慮し, ERC777 として使用する場合は Sent/Minted/Burned について考慮するといった形で, それぞれを別の動きとして捉える必要があります.

コントラクトに ERC20 機能を有効または無効にするスイッチがある場合, スイッチが起動するたびに, トークンは ERC1820 を介して自身のアドレスの ERC20Token インタフェースを適宜登録または登録解除しなければなりません.

最後に, IERC1820 Registry をフック関数の実行フローに採用している点は, 既存の「フック関数を登録していないアカウント」でも ERC777 を使用できるという点で互換性を保ちます.

↓ 情報源

[EIP777 Backward Compatibility](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility)
