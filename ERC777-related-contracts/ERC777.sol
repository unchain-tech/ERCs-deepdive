// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC777/ERC777.sol)

pragma solidity ^0.8.0;

import "./IERC777.sol";
import "./IERC777Recipient.sol";
import "./IERC777Sender.sol";
import "../ERC20/IERC20.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/IERC1820Registry.sol";

// ERC777には以下の用語があります.
// holder: トークンの保有者.
// operator: holderに代わってトークンを送信したり焼却(バーン)することができるアドレス. 
//
// 全てのアカウントはデフォルトで自分自身のoperatorであり, 自分自身をoperatorから削除することはできません. 
// つまり自身のトークンを制御できなくなることはありません.

/**
 * @dev Implementation of the {IERC777} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * Support for ERC20 is included in this contract, as specified by the EIP: both
 * the ERC777 and ERC20 interfaces can be safely used when interacting with it.
 * Both {IERC777-Sent} and {IERC20-Transfer} events are emitted on token
 * movements.
 *
 * Additionally, the {IERC777-granularity} value is hard-coded to `1`, meaning that there
 * are no special restrictions in the amount of tokens that created, moved, or
 * destroyed. This makes integration with ERC20 applications seamless.
 */
contract ERC777 is Context, IERC777, IERC20 {
    // ライブラリの使用を宣言.
    // {address型のオブジェクト}.isContract, のようにAddressライブラリの関数を使用できるようになる.
    using Address for address;

    // ERC1820 Registryをインスタンス化.
    // ERC1820 Registryはブロックチェーン内に1つのみなのでアドレス値は固定.
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    // このマッピングがトークン残高の本体．名付けるならトークン残高．
    // アドレスに対してトークンの量を紐づけ，残高とみなす．
    mapping(address => uint256) private _balances;

    // 文字通り，総供給量.
    uint256 private _totalSupply;

    // トークンネームとトークンシンボルの箱．
    string private _name;
    string private _symbol;

    // インタフェースのハッシュ値を保存. 
    // 後にERC1820 Registryを介して, これらのインタフェースを実装したアカウントが登録されているかの判定に使用する.
    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // 全てのholderに適用されるデフォルトのoperatorリスト.
    // 後述のコントラクト作成(コンストラタ)時に設定できる.
    // セキュリティ上の理由からコントラクト作成後のリストの変更はできない.
    // holderはデフォルトoperatorの取り消し・再認証が可能.
    // This isn't ever read from - it's only used to respond to the defaultOperators query.
    address[] private _defaultOperatorsArray;

    // このマッピングは, 任意のアドレスがデフォルトoperatorであるかを判別するために使用される.
    // 後述のコンストラクタで, _defaultOperatorsArrayを元に記録される.
    // Immutable, but accounts may revoke them (tracked in __revokedDefaultOperators).
    mapping(address => bool) private _defaultOperators;

    // これらのマッピングは, アドレスAに対してアドレスBがoperatorであるかを判別するために使用される.
    // アドレスBがデフォルトoperatorの場合は_revokedDefaultOperatorsが使用される.
    // For each account, a mapping of its operators and revoked default operators.
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    // このマッピングは，後述のtransferFrom関数で使われる．名付けるなら引き出し許可残高．
    // 任意のアドレスAから，他の任意のアドレスBに対してアドレスAの残高からの引き出し許可を与えるというもの．
    // ERC20との後方互換性のために実装されている.
    // ERC20-allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    // コントラクト作成時の処理を記述する関数.
    // nameやsymbolを記録する.
    // デフォルトoperatorを記録する.
    // ERC777Tokenインタフェースと共に自身をERC1820 Registryに登録する必要がある.
    // また, ERC20との後方互換性を維持する場合は同様にERC1820 Registryに登録する必要がある.
    // もしコントラクトにERC777/ERC20の機能を有効/無効にするような実装がある場合は, ERC1820 Registryへの登録/解除も併せて行う必要がある.
    /**
     * @dev `defaultOperators` may be an empty array.
     */
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

    // トークンネームを参照する関数
    /**
     * @dev See {IERC777-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // トークンシンボルを参照する関数
    /**
     * @dev See {IERC777-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // decimalsを返す関数．
    // `ERC-20`との後方互換性を保つ場合は, decimalsが参照される可能性があるため実装する必要がある.
    // 実装した場合は常に18を返さなければならない.
    // 18に強制する理由は, 一般的または暗黙的にトークンコントラクトで使用されている10^18の単位とこのトークンの単位に違いが出ることによる混乱を避けるためだと思われる.
    /**
     * @dev See {ERC20-decimals}.
     *
     * Always returns 18, as per the
     * [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
     */
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    // トークンが分割できる最小単位を返却する関数.
    // ほとんどのトークンの場合は完全に分割できるべきで, 任意の量による分割を許可しない正当な理由がない限り1を返すべき.
    // ゲーム内アイテムの購入など, コントラクトが特定の用途と数量に限られている場合に不正転送を防ぐなどが前述の正当な理由になるかもしれない.
    // granularityに1以外を設定する場合は, トークンの発行・送信・焼却の際にその数量がgranularityの倍数でなければいけないことに注意.
    /**
     * @dev See {IERC777-granularity}.
     *
     * This implementation always returns `1`.
     */
    function granularity() public view virtual override returns (uint256) {
        return 1;
    }

    // 総供給量を参照する関数．
    /**
     * @dev See {IERC777-totalSupply}.
     */
    function totalSupply() public view virtual override(IERC20, IERC777) returns (uint256) {
        return _totalSupply;
    }

    // 最初の方で定義された_balancesマッピングから，該当アドレスにおける該当トークン残高を参照する関数．
    /**
     * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
     */
    function balanceOf(address tokenHolder) public view virtual override(IERC20, IERC777) returns (uint256) {
        return _balances[tokenHolder];
    }

    // トークンを送信する関数．
    // 実際の処理を行う本体とも言える_send関数については，後に説明がなされる．
    // ERC20でトークン送信に使用されるtransferとは定義を明確に分けるためにsendという名前で定義されている.
    // Etherと同じようにsend(recipient, amount, data)という形式で実行でき, dataには任意のデータを渡すことができる.
    // _send関数に渡す引数について以下参考.
    // ・operatorData: holder自身による実行を想定しているため空文字列
    // ・requireReceptionAck: ERC20の機能と区別するためにあるbool値で, デフォルトではtrue.
    /**
     * @dev See {IERC777-send}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function send(address recipient, uint256 amount, bytes memory data) public virtual override {
        _send(_msgSender(), recipient, amount, data, "", true);
    }

    // トークンを送信する関数.
    // 実際の処理を行う本体とも言える_send関数については，後に説明がなされる．
    // ERC20との後方互換性のために実装されている.
    // _send関数に渡す引数について以下参考.
    // ・data/operatorData/requireReceptionAck: ERC20には無い概念のため空文字列 or false
    /**
     * @dev See {IERC20-transfer}.
     *
     * Unlike `send`, `recipient` is _not_ required to implement the {IERC777Recipient}
     * interface if it is a contract.
     *
     * Also emits a {Sent} event.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _send(_msgSender(), recipient, amount, "", "", false);
        return true;
    }

    // トークンを焼却する関数．
    // 実際の処理を行う本体とも言える_burn関数については，後に説明がなされる．
    // ERC20では明示的に定義されていなかった関数だが, ERC777ではウォレットやDappsにトークン焼却のプロセスを統合することを想定して明示的に定義されている.
    // しかし, コントラクトの実装として一部または全holderがトークンを焼却することを禁止してもよい.
    // _burn関数に渡す引数について以下参考.
    // ・operatorData: holder自身による実行を想定しているため空文字列
    /**
     * @dev See {IERC777-burn}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function burn(uint256 amount, bytes memory data) public virtual override {
        _burn(_msgSender(), amount, data, "");
    }

    // 引数の`operator`と`tokenHolder`の間にoperatorとholderの関係があるか否かを返却する関数.
    // ・2つのアドレスが同じ場合は, 全てのholderは自身のoperatorでもあるためtrue
    // ・`operator`がデフォルトoperatorで, `tokenHolder`によって取り消されていなければtrue
    // ・`operator`が`tokenHolder`のoperatorに設定されていればtrue
    /**
     * @dev See {IERC777-isOperatorFor}.
     */
    function isOperatorFor(address operator, address tokenHolder) public view virtual override returns (bool) {
        return
            operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }

    // 引数の`operator`を, 関数を呼び出したアカウントのoperatorとして認証する関数.
    // 全てのholderが自身のoperatorでもあることは不変で, その関係性の取り消しや再認証はできない.
    // `operator`がデフォルトoperatorである場合は, 「_revokedDefaultOperatorsから削除する」=「再認証」.
    // そうでない場合は_operatorsに追加しoperatorとして設定する.
    /**
     * @dev See {IERC777-authorizeOperator}.
     */
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
    // 全てのholderが自身のoperatorでもあることは不変で, その関係性の取り消しや再認証はできない.
    // `operator`がデフォルトoperatorである場合は, 「_revokedDefaultOperatorsに追加する」=「取り消し」.
    // そうでない場合は_operatorsから削除しoperator設定を取り消す.
    /**
     * @dev See {IERC777-revokeOperator}.
     */
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
    /**
     * @dev See {IERC777-defaultOperators}.
     */
    function defaultOperators() public view virtual override returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    // operator(msg.sender)がholder(引数では`sender`)に代わってトークンを送信する関数.
    // operatorに権限がない場合はトランザクションをキャンセルする.
    // 実際の処理を行う本体とも言える_send関数については，後に説明がなされる．
    // msg.senderと`sender`が同じ場合, operatorDataの存在を除いてはsend関数と同じである.
    // _send関数に渡す引数について以下参考.
    // ・requireReceptionAck: ERC20の機能と区別するためにあるbool値で, デフォルトではtrue.
    /**
     * @dev See {IERC777-operatorSend}.
     *
     * Emits {Sent} and {IERC20-Transfer} events.
     */
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
    // operatorに権限がない場合はトランザクションをキャンセルする.
    // msg.senderと`account`が同じ場合, operatorDataの存在を除いてはburn関数と同じである.
    /**
     * @dev See {IERC777-operatorBurn}.
     *
     * Emits {Burned} and {IERC20-Transfer} events.
     */
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
    // 最初の方で定義した_allowancesマッピングを参照している．
    // ERC20との後方互換性のために実装されている.
    /**
     * @dev See {IERC20-allowance}.
     *
     * Note that operator and allowance concepts are orthogonal: operators may
     * not have allowance, and accounts with allowance may not be operators
     * themselves.
     */
    function allowance(address holder, address spender) public view virtual override returns (uint256) {
        return _allowances[holder][spender];
    }

    // 引き出し許可残高を変更する関数．
    // 実際の処理を行う本体とも言える_approve関数については，後に説明がなされる．
    // ERC20との後方互換性のために実装されている.
    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address holder = _msgSender();
        _approve(holder, spender, value);
        return true;
    }

    // 引き出し許可をもとに，自分のアドレスに他のアドレスから残高を移動させる関数．
    // ERC20との後方互換性のために実装されている.
    // 以下を順に実行している．
    // ・_spendAllowance関数で引き出し許可残高を引き出す残高だけへらす
    // ・_send関数で対象アドレスから自身のアドレスへ，残高を移動させる
    // 実際の処理を行う本体とも言える_のついた関数については，後に説明がなされる．
    /**
     * @dev See {IERC20-transferFrom}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Note that operator and allowance concepts are orthogonal: operators cannot
     * call `transferFrom` (unless they have allowance), and accounts with
     * allowance cannot call `operatorSend` (unless they are operators).
     *
     * Emits {Sent}, {IERC20-Transfer} and {IERC20-Approval} events.
     */
    function transferFrom(address holder, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(holder, spender, amount);
        _send(holder, recipient, amount, "", "", false);
        return true;
    }

    // _mint関数(後に説明がなされる)を呼び出す関数．
    // _mint関数には`requireReceptionAck`という引数があり, 
    // この引数はERC20の機能と区別するためにあるbool値で, デフォルトではtrue.
    // そのためわざわざtrueを指定しなくても実行できるようにこの関数が実装されていると思われる.
    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with the caller address as the `operator` and with
     * `userData` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function _mint(address account, uint256 amount, bytes memory userData, bytes memory operatorData) internal virtual {
        _mint(account, amount, userData, operatorData, true);
    }

    // トークンmint(貨幣発行)の仕組みがかいてある．
    // 一般的にmintプロセスは各トークンに固有であるため, ERC-777標準では定義されていない. そのためmint関数はない.
    // 以下を順に実行している．
    // ・自身のアドレスが0アドレスでないことを要求
    // ・転送前に行いたい操作を足せる　※_beforeTokenTransfer
    // ・mintしたい量(amount)を総供給量に追加
    // ・mint(mint先のアドレスの残高をamount分だけ増加させる)
    // ・アカウントのトークン残高が増加したため_callTokensReceivedを実行(後述)
    //   operatorDataはoperatorが_mintを呼び出す際に使用されるデータ.
    //   _callTokensReceived内で実行される関数で使用される可能性がある.
    // ・mint完了をMintedイベントでフロントへ通知
    // ・ERC20との後方互換性のためにTransferイベントも発生させる.
    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If `requireReceptionAck` is set to true, and if a send hook is
     * registered for `account`, the corresponding function will be called with
     * `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
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
    // 実際の処理を行う本体とも言える_のついた関数については，後に説明がなされる．
    // 以下を順に実行している．
    // ・各アカウントのアドレスが0x0でないことを要求
    // ・msg.senderをoperatorとする
    // 　※ holderがこの関数を呼び出している場合(msg.sender=holder)についてもholderは自身のoperatorでもあるので成立する.
    // ・`from`(=holder)の残高が減るため, トークン残高を変更する前に_callTokensToSendを呼び出す
    // ・トークンの残高を変更するために_move関数を呼び出す
    // ・`to`の残高が増えたため, トークン残高を変更後に_callTokensToSendを呼び出す
    //
    // ERC20の後方互換性のために実装されたtransfer/transferFromにおいてもこの_send関数が使用される.
    // つまり, ERC20には無い_callTokensToSend/_callTokensToSend関数の実行が行われるが, これは後方互換性より優先されるとのこと.
    //
    // データ引数について以下に説明をする.
    //         data: etherの送信と同様に, holderによって提供された情報を含む.
    //               _callTokensToSend, _callTokensReceived内で呼び出される関数でトランザクションを拒否するどうかの判断に使用することも可能.
    // operatorData: dataに似ているが, operatorによってのみ提供されるデータ.
    //               ロギの記録や特定のケース(支払いの参照など)目的で使われる.
    //               トークン受信者はこのデータを無視するか, 使っても記録する程度とのこと.
    /**
     * @dev Send tokens
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
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
    // 以下を順に実行している．
    // ・`from`が0x0でないことを要求
    // ・msg.senderをoperatorとする
    // 　※ holderがこの関数を呼び出している場合(msg.sender=holder)についてもholderは自身のoperatorでもあるので成立する.
    // ・転送前に行いたい操作を足せる　※_beforeTokenTransfer
    // ・`from`(=holder)の残高が減るため, トークン残高を変更する前に_callTokensToSend(後述)を呼び出す
    // ・仲介変数を定義して，送金元に送金したい量(amount)より大きな残高があるか確認
    //   ※ 既に送金元の残高が0より小さくならないことを確認しているため, 
    //     次の処理ではuncheckedで囲み余計な処理(オーバーフローの検証)を除くことでガス軽減を狙っているのだろう．
    // ・送金(送金元アドレスと総供給量の残高をamount分だけ増減させる)
    // ・送金完了をBurnedイベントでフロントへ通知
    // ・ERC20との後方互換性のためにTransferイベントも発生させる.
    //
    // データ引数について以下に説明をする.
    //         data: etherの送信と同様に, holderによって提供された情報を含む.
    //               _callTokensToSend, _callTokensReceived内で呼び出される関数でトランザクションを拒否するどうかの判断に使用することも可能.
    // operatorData: dataに似ているが, operatorによってのみ提供されるデータ.
    //               ロギの記録や特定のケース(支払いの参照など)目的で使われる.
    //               トークン受信者はこのデータを無視するか, 使っても記録する程度とのこと.
    /**
     * @dev Burn tokens
     * @param from address token holder address
     * @param amount uint256 amount of tokens to burn
     * @param data bytes extra information provided by the token holder
     * @param operatorData bytes extra information provided by the operator (if any)
     */
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
    // 以下を順に実行している．
    // ・転送前に行いたい操作を足せる　※_beforeTokenTransfer
    // ・仲介変数を定義して，送金元に送金したい量(amount)より大きな残高があるか確認
    //   ※ 既に送金元の残高が0より小さくならないことを確認しているため, 
    //     次の処理ではuncheckedで囲み余計な処理(オーバーフローの検証)を除くことでガス軽減を狙っているのだろう．
    // ・転送(送金先と送金元のアドレスの残高をamount分だけ増減させる)
    // ・転送完了をSentイベントでフロントへ通知
    // ・ERC20との後方互換性のためにTransferイベントも発生させる.
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
    // 自分のアドレスに対して相手のアドレスと残高をマッピングで紐づけることによって，相手に対して自分の残高の引き出し許可を定義している．
    // ERC20との後方互換性のために実装されている.
    /**
     * @dev See {ERC20-_approve}.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function _approve(address holder, address spender, uint256 value) internal virtual {
        require(holder != address(0), "ERC777: approve from the zero address");
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    // アカウントのトークンが減少(_send, _burn)する際にトークンの残高操作前に呼び出される.
    // holderがERC777TokensSenderの実装を登録している場合に, 
    // 実装しているコントラクト(implementer)に対してtokensToSend関数を呼び出す.
    // ERC777TokensSenderとtokensToSendに関してはIERC777TokensSender.solで説明がなされる.
    /**
     * @dev Call from.tokensToSend() if the interface is registered
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     */
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
    // holderがERC777TokensRecipientの実装を登録している場合に, 
    // 実装しているコントラクト(implementer)に対してtokensReceived関数を呼び出す.
    // ERC777TokensRecipientとtokensReceivedに関してはIERC777TokensSender.solで説明がなされる.
    // TODO: ここでロックしないためにcontractに実装を求めていることを説明
    /**
     * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
     * tokensReceived() was not registered for the recipient
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
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
    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {IERC20-Approval} event.
     */
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
    // デフォルトでは中身は空で，オーバーライドして中身を追加して使用する．
    // 例えば入力パラメータの検証などが可能.
    // ERC20には_afterTokenTransferという「トークン操作後に行いたい動作」の実装も定義されているが, ERC777にはない.
    // 上記の理由はわからないが, ERC777の作者から見てトークン操作後に行いたい処理の必要性が無かったのではないだろうか.
    /**
     * @dev Hook that is called before any token transfer. This includes
     * calls to {send}, {transfer}, {operatorSend}, minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount) internal virtual {}
}
