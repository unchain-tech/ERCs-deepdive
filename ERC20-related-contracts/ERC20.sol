// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    // このマッピングがトークン残高の本体．名付けるならトークン残高．
    // アドレスに対してトークンの量を紐づけ，残高とみなす．
    mapping(address => uint256) private _balances;

    // このマッピングは，後述のtransferFrom関数で使われる．名付けるなら引き出し許可残高．
    // 任意のアドレスAから，他の任意のアドレスBに対してアドレスAの残高からの引き出し許可を与えるというもの．
    mapping(address => mapping(address => uint256)) private _allowances;

    // 文字通り，総供給量.
    uint256 private _totalSupply;

    // トークンネームとトークンシンボルの箱．恐らくは，defi等でトークン情報を出力するときに使われる．
    string private _name;
    string private _symbol;

    // コンストラクタ．デプロイ時に実行される定数(変数)初期化．
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // トークンネームを参照する関数
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // トークンシンボルを参照する関数
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // decimalsを参照，ではなくdecimalsを返す関数．
    // 規格からの変更はまずないだろうということで，変数としておいていないのだと考えられる．
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    // 総供給量を参照する関数．
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    // 最初の方で定義された_balancesマッピングから，該当アドレスにおける該当トークン残高を参照する関数．
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    // 送金を行う関数．
    // 実際の処理を行う本体とも言える_trancefer関数については，後に説明がなされる．
    // ※中身が直下に無いのは，Solidityのコーディング規則に由来する．関数の可視性によって順序づけて書くようにと
    // 　ドキュメントに言及がある．(https://solidity-jp.readthedocs.io/ja/latest/style-guide.html#order-of-functions)
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    // allowance(引き出し許可残高)を参照する関数．
    // 最初の方で定義した_allowancesマッピングを参照している．
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // 引き出し許可残高を変更する関数．
    // 実際の処理を行う本体とも言える_approve関数については，後に説明がなされる．
    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    // 引き出し許可をもとに，自分のアドレスに他のアドレスから残高を移動させる関数．
    // _spendAllowance関数で引き出し許可残高を引き出す残高だけへらし，
    // _transfer関数で対象アドレスか自身のアドレスへ，残高を移動させる
    // 実際の処理を行う本体とも言える _ のついた関数については，後に説明がなされる．
    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
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
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
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
    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    // トークン転送(送金)の仕組みがかいてある．
    // 以下を順に実行している．
    // ・自身のアドレスと相手のアドレスが0アドレスでないことを要求
    // ・転送前に行いたい操作を足せる　※_beforeTokenTransfer
    // ・仲介変数を定義して，送金元に送金したい量(amount)より大きな残高があるか確認
    // ・転送(送金先と送金元のアドレスの残高をamount分だけ増減させる)
    // ・転送完了をイベントでフロントへ通知
    // ・転送後に行いたい操作を足せる ※_afterTokenTransfer
    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
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
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
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
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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
    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
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
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // トークンの操作を行う関数(_burn, _mint, _transfer関数)の実行後に行いたい動作を設定できる．
    // デフォルトでは中身は空で，オーバーライドして中身を追加して使用する．
    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}