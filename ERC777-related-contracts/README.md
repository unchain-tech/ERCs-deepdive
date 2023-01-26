# ERC777

## 目次

## 1. はじめに

ここでは，ERC20.sol とその中でインポートされている３つを含めた４つの sol ファイルについて，順番にコードベースでよみとくことによって ERC20 を完全に理解することを目指します．

しかし，この README.md ファイルではコードは極力使わず，実際にコードを読み解く sol ファイル群へのリンクは添えたうえで，日本語ベース・ノーコードでなるべく簡潔な解説を行っていきます．

> 尚，Solidity の文法に関してはある程度前提としていますが，Solidity のハンズオンラーニングの手段ともなりえるように，検索可能な用語を用いることを心掛けることとします．

### 要約

この規格は, ERC-20との後方互換性を保ちつつ, トークンコントラクトと対話するための新しい方法を定義しています.

特に新しい概念が２つあります.

- 他のアドレス(コントラクトまたはレギュラーアカウント)に代わってトークンを送信するオペレータ
- トークン所有者が自分のトークンをよりコントロールできるようにする送受信フック

## 2. インポートされているファイル

### 2.1 IERC777.sol

次に import されているのがこのファイルです．

このファイルでは，`interface` という分類の `contract` の中で，可視性が `private` でないものの型定義と，コメントを用いた関数の説明がなされています．

`abstract` と `interface` の違いは，`contract` 内に関数を内包するか否かです．

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC20/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol)

### 2.2 IERC777Recipient.sol
### 2.3 IERC777Sender.sol
### 2.4 IERC20.sol

次に import されているのがこのファイルです．

このファイルでは，`interface` という分類の `contract` の中で，可視性が `private` でないものの型定義と，コメントを用いた関数の説明がなされています．

`abstract` と `interface` の違いは，`contract` 内に関数を内包するか否かです．

↓ 元ファイル

[openzeppelin-contracts/contracts/token/ERC20/IERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol)

### 2.5 Address.sol

このファイルでは， `address` 型の変数に関する関数を集めた `Address` ライブラリを定義しています．
ERC5192 における用途は，`isContract()` の利用です．この関数は `address` 値を引数にとり，そのアドレス長が 0 より大きいかどうかを `bool` 値で返します．こうすることで，4 種ほどの例外を除き，引数のアドレスがコントラクトアドレスかどうかを判断します．

> この例外というのはコントラクトが機能しない特殊な状況にある場合です．なので，実質的にはコントラクトが利用可能な状態であるかどうかを示すものになります．そして，コントラクトとウォレットアドレス(EOA アドレス)は形式が同じであるため，仮に存在するウォレットアドレスを引数としたとしても `isContract()` は `true` を返すと思われます．

↓ 元ファイル

[openzeppelin-contracts/contracts/utils/Address.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)

### 2.6 Context.sol

ERC20 上で最初に import されているのがこのファイルです．

このファイルでは，`abstract` という分類の `contract` の中で，`msg.sender` という宣言をラップする `_msgSender`という関数を宣言しています．

わざわざ関数でラップしているのはなぜかというと，メタトランザクションスキームを用いる場合に `msg.sender` をそのまま使うのは都合が悪いからです．

以下に簡単な説明をのせておきます．詳しくは[ここ](https://github.com/unchain-dev/openzeppelin-deepdive/tree/main/metatx-related-contracts#2-meta-transaction%E3%81%A8%E3%81%AF-1)を参照してください．

> `msg.sender` は EVM に規定されたグローバル変数なので書き換えできませんが，関数の中に `msg.sender` をラップした `_msgSender()` 関数を使うことによって，メタトランザクション使用時には `_msg.sender()` 関数をオーバーライドして返り値を書き換えることにより `msg.sender(gas feeを支払うアドレス)` と `_msgSender()の返り値(txを実行したいアドレス)` を分けることができるようになります．

↓ 元ファイル

[openzeppelin-contracts/contracts/utils/Context.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol)

### 2.7 IERC1820Registry.sol

## 3. ERC777.sol

### 3.1. ""import"", 変数定義から "constructor" まで

さぁ，それでは本体である `ERC20.sol` についてみていきましょう．

まず最初に，先程紹介した 3 つの `.sol` ファイルを import した後，各 `contract` を `ERC20` という `contract` に継承させています．

```solidity
import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";
contract ERC20 is Context, IERC20, IERC20Metadata {
```

そして，各グローバル変数を定義．

```solidity
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

```solidity
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
```

### 3.2. ブロックチェーン上の変数を参照する ""view"" 関数群

その後に，関数が定義されていきます．

まずは，変数を変更(変数に代入)できない `view` 関数で，処理が少ないものが定義されています．

```solidity
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

```solidity
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

```solidity
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

## 4. ERC20との比較

### ERC777 需要な点

本規格は，ERC-20との後方互換性を保ちつつ，ERC-20の欠点を解決し，EIP-223の問題点や脆弱性を回避することを主な意図としている。

以下、規格の主要な点に関する決定の根拠を示す。

- Lifecycle

ERC-777では、単にトークンを送るだけでなく、トークンのライフサイクル全体を定義しており、造幣プロセスから始まり、送信プロセス、燃焼プロセスで終了します。

ライフサイクルが明確に定義されていることは、特に希少性から価値が生まれる場合には、一貫性と正確性の点で重要です。一方、いくつかの ERC-20 トークンを見てみると、トークンの生成と破棄のプロセスが規格で明確に定義されていないため、totalSupply が返す値と実際の流通量との間に不一致が見受けられます。

- Data

ミント、センド、バーン処理はすべて、あらゆる動き（ミント、センド、バーン）に渡されるデータおよびオペレータデータフィールドを利用することができます。これらのフィールドは、単純なユースケースでは空かもしれませんが、送信者または銀行自体によって銀行振込に添付された情報のように、トークンの移動に関連する貴重な情報を含むかもしれません。

データフィールドの使用は、EIP-223 などの他の標準提案にも同様に存在し、この標準を検討したコミュニティの複数のメンバーから要求されました。

- Hooks

ほとんどの場合、ERC-20では、トークンをロックせずに安全にコントラクトに転送するために2つのコールが必要です。送信側からのApprove関数を使ったコールと、受信側からのtransferFromを使ったコールです。さらに、これは当事者間の余分なコミュニケーションを必要とし、明確に定義されていません。最後に、保有者はtransferとapprove/transferFromを混同してしまう可能性があります。前者を使用してトークンをコントラクトに転送すると、トークンがロックされる可能性が高くなります。
ロックとは？

フックは送信プロセスの合理化を可能にし、あらゆる受信者にトークンを送信する単一の方法を提供します。tokensReceived フックのおかげで、コントラクトは受信時に反応し、トークンのロックを防ぐことができる。 <- これがtokensReceivedがコントラクトには実装されてなければいけない理由

tokensReceivedフックは、保有者がいくつかのトークンの受信を拒否することも可能です。これは、例えばdataやoperatorDataフィールドにあるいくつかのパラメータに基づいて、受信したトークンを受け入れるか拒否するかを保持者に大きく制御させることができます。

同じ意図で、コミュニティからの提案に基づいて、tokensToSend フックが追加され、送信するトークンの移動を制御したり防いだりできるようになりました。

IERC1820を使用することは, 既存の何もフックを登録していない・実装していないコントラクトでもERC777を使用できるという点で互換性を保つ

- Operator

本標準規格では、トークンを移動させるあらゆるアドレスをオペレータの概念として定義しています。直感的には、すべてのアドレスがそれ自身のトークンを移動させますが、ホルダーとオペレータの概念を分離することで、より柔軟性を持たせることができます。これは主に、ホルダーが他のアドレスをオペレーターにできる仕組みを定義していることに起因しています。さらに、承認されたアドレスの役割が明確に定義されていないERC-20の承認コールとは異なり、ERC-777ではオペレータの意図やオペレータとのやり取りが詳細に記述されており、オペレータを承認する義務や、オペレータを取り消すホルダー側の取り消し不能な権利も含まれています。

デフォルトのオペレータは、事前承認されたオペレータに対するコミュニティの要求に基づいて追加されました。つまり、デフォルトですべての保有者に承認されるオペレータです。セキュリティ上の理由から、デフォルトのオペレータのリストは、トークン契約作成時に定義され、変更することはできません。どの保有者も、デフォルトのオペレータを取り消す権利を持っています。デフォルトのオペレータの明らかな利点の1つは、トークンの移動をエーテルレスで行えることです。デフォルトのオペレータは、トークン提供者がモジュール方式で機能を提供できるようにし、保有者がオペレータを通じて提供される機能を使用する際の複雑さを軽減するなど、他のユーザビリティ上の利点もあります。

オペレータという概念を足して, オペレータが呼び出す場合は関数が分かれているのが重要な気がする

### 後方互換性について

このEIPはtransferとtransferFromを使用せず、sendとoperatorSendを使用し、どのトークン規格が使用されているかを解読する際の混乱や間違いを避けるようにしています。

この規格では、ERC-20の関数transfer, transferFrom, approve, allowanceを並行して実装することで、ERC-20と完全互換のトークンとすることができます。

コントラクトに ERC20 機能を有効または無効にするスイッチがある場合、スイッチが起動するたびに、トークンは ERC1820 を介して自身のアドレスの ERC20Token インタフェースを適宜登録または登録解除しなければなりません (MUST)。登録を解除するには、トークン契約アドレスをアドレスとして、ERC20Token の keccak256 ハッシュをインターフェースハッシュとして、0x0 を実装者として setInterfaceImplementer を呼び出すことを意味します。(詳細は「ERC-1820のアドレスにインタフェースを設定する」を参照してください)。

したがって、トークンの移動に対して、ERC-20 Transfer と ERC-777 Sent, Minted または Burned (移動のタイプによる)の 2 つのイベントを発行してもよい。サードパーティの開発者は、この2つのイベントを別々の動きと見なさないように注意しなければならない（MUST）。原則として、アプリケーションがトークンを ERC20 トークンと見なす場合、Transfer イベントのみを考慮しなけれ ばなりません。アプリケーションがトークンを ERC777 トークンと見なす場合、Sent、Minted、Burned イベントのみを考慮しなけれ ばなりません(MUST)。

イベントがERC20と777で区別されていることを記述する