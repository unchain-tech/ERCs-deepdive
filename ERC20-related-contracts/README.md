# ERC20

## 目次

### 1. [はじめに](#はじめに)

### 2. ERC20.sol にインポートされているファイル

1. [Context.sol](#21-contextsol)
2. [IERC20.sol](#22-ierc20sol)
3. [IERC20Metadata.sol](#23-ierc20metadatasol)

### 3. [ERC20.sol](#3-erc20sol)

1. [""import"", 変数定義から "constructor" まで](#31-import-変数定義から-constructor-まで)
2. [ブロックチェーン上の変数を参照する ""view"" 関数群](#32-ブロックチェーン上の変数を参照する-view-関数群)
3. [標準搭載関数群](#33-標準搭載関数群)
4. [メソッド記述と追加機能実装を担う ""internal"" 関数群](#34-メソッド記述と追加機能実装を担う-internal-関数群)

### 4. [SCAM と approve 関数](#4-scamとapprove関数)

## 1. はじめに

ここでは，ERC20.sol とその中でインポートされている３つを含めた４つの sol ファイルについて，順番にコードベースでよみとくことによって ERC20 を完全に理解することを目指します．

しかし，この README.md ファイルではコードは極力使わず，実際にコードを読み解く sol ファイル群へのリンクは添えたうえで，日本語ベース・ノーコードでなるべく簡潔な解説を行っていきます．

> 尚，Solidity の文法に関してはある程度前提としていますが，Solidity のハンズオンラーニングの手段ともなりえるように，検索可能な用語を用いることを心掛けることとします．

## 2.1. Context.sol

ERC20 上で最初に import されているのがこのファイルです．

このファイルでは，`abstract` という分類の `contract` の中で，`msg.sender` という宣言をラップする `_msgSender`という関数を宣言しています．

わざわざ関数でラップしているのはなぜかというと，メタトランザクションスキームを用いる場合に `msg.sender` をそのまま使うのは都合が悪いからです．

以下に簡単な説明をのせておきます．詳しくは[ここ](https://github.com/unchain-dev/openzeppelin-deepdive/tree/main/metatx-related-contracts#2-meta-transaction%E3%81%A8%E3%81%AF-1)を参照してください．

> `msg.sender` は EVM に規定されたグローバル変数なので書き換えできませんが，関数の中に `msg.sender` をラップした `_msgSender()` 関数を使うことによって，メタトランザクション使用時には `_msg.sender()` 関数をオーバーライドして返り値を書き換えることにより `msg.sender(gas feeを支払うアドレス)` と `_msgSender()の返り値(txを実行したいアドレス)` を分けることができるようになります．

↓ 元ファイル

[openzeppelin-contracts/contracts/utils/Context.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol)

## 2.2. IERC20.sol

次に import されているのがこのファイルです．

このファイルでは，`interface` という分類の `contract` の中で，可視性が `private` でないものの型定義と，コメントを用いた関数の説明がなされています．

`abstract` と `interface` の違いは，`contract` 内に関数を内包するか否かです．

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC20/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol)

## 2.3. IERC20Metadata.sol

最後に `import` されているのがこのファイルです．

このファイルでは，`interface` という分類の `contract` の中で，

`_name` 変数を参照する `name` 関数，
`_symbol` 変数を参照する `symbol` 関数，
`decimals` を定義する `decimals` 関数

の三つの関数を型定義しています．

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol)

## 3. ERC20.sol

### 3.1. ""import"", 変数定義から "constructor" まで

さぁ，それでは本体である `ERC20.sol` についてみていきましょう．

まず最初に，先程紹介した 3 つの `.sol` ファイルを import した後，各 `contract` を `ERC20` という `contract` に継承させています．

```
import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";
contract ERC20 is Context, IERC20, IERC20Metadata {
```

そして，各グローバル変数を定義．

```
    // このマッピングがトークン残高の本体．名付けるならトークン残高．
    // アドレスに対してトークンの量を紐づけ，残高とみなす．
    mapping(address => uint256) private _balances;

    // このマッピングは，後述のtransferFrom関数で使われる．名付けるなら引き出し許可残高．
    // 任意のアドレスAから，他の任意のアドレスBに対してアドレスAの残高からの引き出し許可を与えるというもの．
    mapping(address => mapping(address => uint256)) private _allowances;

    // 文字通り，総供給量
    uint256 private _totalSupply;

    // トークンネームとトークンシンボルの箱．恐らくは，defi等でトークン情報を出力するときに使われる．
    string private _name;
    string private _symbol;
```

続いて，デプロイ時に string 変数を初期化する `constructor` が定義されています．引数(トークン名とトークンシンボル)はデプロイ時にコンパイルされた Solidity ファイルと一緒に渡してあげます．

```
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
```

### 3.2. ブロックチェーン上の変数を参照する ""view"" 関数群

その後に，関数が定義されていきます．

まずは，変数を変更(変数に代入)できない `view` 関数で，処理が少ないものが定義されています．

```
    // トークンネームを参照する関数
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // トークンシンボルを参照する関数
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // decimalsを参照，ではなくdecimalsを返す関数．
    // 規格からの変更はまずないだろうということで，変数としておいていないのだと考えられる．
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    // 総供給量を参照する関数．
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    // 最初の方で定義された_balancesマッピングから，該当アドレスにおける該当トークン残高を参照する関数．
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

```

### 3.3. 標準搭載関数群

そして，`ERC20` に標準搭載されている関数が定義されます．

- 自分による，自分のアドレスから任意のアドレスへのトークン転送
- 自分による，任意のアドレスからの引き出し許可残高を参照
- 自分による，任意のアドレスからの引き出し許可残高を変更
- 自分による，任意のアドレスから任意のアドレスへのトークン転送
- 自分による，任意のアドレスからの引き出し許可残高の増額
- 自分による，任意のアドレスからの引き出し許可残高の減額

以上 6 機能のトリガーとなる関数です．適切な引数と変数を定義し，次章で解説する実際の操作が記述された ""internal"" 関数をメソッドとして呼び出しています．

メソッドとトリガーと分ける理由は，複雑な関数を定義したいデベロッパーへの配慮のためでしょう．これにより，基本機能だけを用いたいデベロッパーは標準搭載関数で手間なく実装が完了でき，複雑な関数を定義したいデベロッパーは基本機能のメソッドが記述された ""internal"" 関数を骨組みとした複雑な関数の定義を容易に行えます．

```
    // 送金を行う関数．
    // 実際の処理を行う本体とも言える_trancefer関数については，後に説明がなされる．
    // ※中身が直下に無いのは，Solidityのコーディング規則に由来する．関数の可視性によって順序づけて書くようにと
    // 　ドキュメントに言及がある．(https://solidity-jp.readthedocs.io/ja/latest/style-guide.html#order-of-functions)
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    // allowance(引き出し許可残高)を参照する関数．
    // 最初の方で定義した_allowancesマッピングを参照している．
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // 引き出し許可残高を変更する関数．
    // 実際の処理を行う本体とも言える_approve関数については，後に説明がなされる．
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    // 引き出し許可をもとに，自分のアドレスに他のアドレスから残高を移動させる関数．
    // _spendAllowance関数で引き出し許可残高を引き出す残高だけへらし，
    // _transfer関数で対象アドレスか自身のアドレスへ，残高を移動させる
    // 実際の処理を行う本体とも言える _ のついた関数については，後に説明がなされる．
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // 引き出し許可残高を増やす関数．
    // allowance関数で呼び出した引き出し許可残高に増やしたい値を足した値 を用いて_approve関数を叩くことで，
    // 引き出し許可残高を上書きしている．
    // 実際の処理を行う本体とも言える_approve関数については，後に説明がなされる．
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    // 引き出し許可残高を減らす関数．
    // allowance関数で呼び出した引き出し許可残高から減らしたい値を引いた値 を用いて_approve関数を叩くことで，
    // 引き出し許可残高を上書きしている．
    // require文では，_approve関数に入れるuint成分が負の値とならないかどうか確認している．
    // 実際の処理を行う本体とも言える_approve関数については，後に説明がなされる．
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
```

### 3.4. メソッド記述と追加機能実装を担う ""internal"" 関数群

最後に，標準搭載関数のメソッドを記述するためのものや追加実装を行うためのものからなる `internal` 関数群が定義されています．

※`internal` という修飾子は関数の可視性(`public`, `private`, `internal`, `external`)を表しています．これついては[ここ](https://qiita.com/ryu-yama/items/fae7e502d1bd5f0707b0)を見るとよいでしょう．

3.3. でものべたように，多くの関数は標準搭載関数のメソッドを記述する関数ですが，違うものもあります．

まずは""\_mint"" 関数と ""\_burn"" 関数です．これらは文字通りトークンのミントとバーンのメソッドを記述した関数ですが，そのトリガー関数が ""ERC20.sol"" 上に標準搭載されていません．実装する場合は，[ERC20Burnable.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Burnable.sol) を ""import"" して ""burn"" 関数をを定義したり，直接 "mint" 関数を定義したりして メソッドを実行する関数を定義しなければなりません．

さらに，"\_beforeTokenTransfer"，"\_afterTokenTransfer" という，標準搭載関数の中でトークン転送を行う関数の前後で追加操作を行う関数が定義されています．これらはデフォルトでは何も定義されておらず，実装時に "override" 修飾子をつけて記述することで関数を上書きして使用します．

```
// トークン転送(送金)の仕組みがかいてある．
    // 以下を順に実行している．
    // ・自身のアドレスと相手のアドレスが0アドレスでないことを要求
    // ・転送前に行いたい操作を足せる　※_beforeTokenTransfer
    // ・仲介変数を定義して，送金元に送金したい量(amount)より大きな残高があるか確認
    // ・転送(送金先と送金元のアドレスの残高をamount分だけ増減させる)
    // ・転送完了をイベントでフロントへ通知
    // ・転送後に行いたい操作を足せる ※_afterTokenTransfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    // トークンmint(貨幣発行)の仕組みがかいてある．
    // mint関数は実装されていないため，transfer関数のような形で_mint関数を含む関数を別途実装する必要がある．
    // uncheckedというブロックは，ガス軽減策のようである．
    // 以下を順に実行している．
    // ・自身のアドレスが0アドレスでないことを要求
    // ・転送前に行いたい操作を足せる　※_beforeTokenTransfer
    // ・mintしたい量(amount)を総供給量に追加
    // ・mint(mint先のアドレスの残高をamount分だけ増加させる)
    // ・mint完了をイベントでフロントへ通知
    // ・転送後に行いたい操作を足せる ※_afterTokenTransfer
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    // トークンburn(貨幣の消去，焼却)の仕組みがかいてある．
    // burn関数は実装されていないため，transfer関数のような形で_burn関数を含む関数を別途実装する必要がある．
    // 以下を順に実行している．
    // ・自身のアドレスが0アドレスでないことを要求
    // ・転送前に行いたい操作を足せる　※_beforeTokenTransfer
    // ・仲介変数を定義して，送金元に送金したい量(amount)より大きな残高があるか確認
    // ・送金(送金先と送金元のアドレスの残高をamount分だけ増減させる)
    // ・送金完了をイベントでフロントへ通知
    // ・転送後に行いたい操作を足せる ※_afterTokenTransfer
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    // トークン引き出し許可更新の仕組みがかいてある．
    // 自分のアドレスに対して相手のアドレスと残高をマッピングで紐づけることによって，
    // 相手に対して自分の残高の引き出し許可を定義している．
    // 以下を順に実行しているっぽい．
    // ・自身と許可を与える者のアドレスが0アドレスでないことを要求
    // ・引き出し許可残高を更新
    // ・引き出し許可更新完了をイベントでフロントへ通知
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // トークン引き出し許可残高を減らす関数
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    // トークンの操作を行う関数(_burn, _mint, _transfer関数)の実行前に行いたい動作を設定できる．
    // デフォルトでは中身は空で，オーバーライドして中身を追加して使用する．
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // トークンの操作を行う関数(_burn, _mint, _transfer関数)の実行後に行いたい動作を設定できる．
    // デフォルトでは中身は空で，オーバーライドして中身を追加して使用する．
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
```

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC20/ERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)

## 4. SCAM と approve 関数

秘密鍵(メタマスクにおけるシードフレーズ)を SCAMMER に知られてしまえば，彼らは自身のデバイスにあなたのウォレットをインポートすることができるようになり，あなたの ERC20 トークンは彼らの手によっていとも簡単にあなたのウォレットから抜かれてしまうでしょう．

しかし，秘密鍵を知られなければ SCAM 被害にはあわないのでしょうか？

答えは NO です．

例えば，SCAM サイトのウォレットコネクトボタンに，メタマスクを呼び出す `web3.js` や `ethers.js` によるウォレットコネクトリクエストに加えて，あなたの残高からの多額の引き出し許可を SCAMMERs のウォレットに対して与える単一または複数の `approve` 関数の実行を承認するための関数実行リクエストが仕込まれていた場合のことを考えてみましょう．

あなたがウォレットコネクト要求を承認すると，もう一つの承認を要求されます．そのトランザクションに署名してしまったが最後，あなたのウォレットは特定の 1 種または複数の通貨の残高を SCAMMER から抜かれ放題な状態になります．

SCAMMERs による攻撃はこのような方法だけというわけではなく，今この瞬間にもあたらしい手法が開発されていることでしょう．

信頼のおけるサイト以外からのメタマスクのリクエストには十分に注意を払い，初回や怪しいと思った際には必ず，各チェーンの SCANNING アプリケーションで `contract` を確認してみるようにしましょう．
