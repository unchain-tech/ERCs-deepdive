// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Sender.sol)

pragma solidity ^0.8.0;

// `IERC777Sender`は`tokensToSend`という関数の実装を定義するインタフェースです.
// `tokensToSend`はトークンホルダーの「トークンがどこかに転送される」=「トークンが減少する」アクションが起きた際に, 
// そのことをトークンホルダーに通知する役目を担います.
//
// 以下に`IERC777Sender`と`tokensToSend`が使用される場面を示します. 先に`ERC777`と`IERC1820`のファイル冒頭の説明に目を通してください.
// 登場人物: `ERC777`のholderであるH. HのoperatorであるO.
// 前提: Hは, 自身のトークンが転送される際に
//      通知または何らかのアクション(特定の条件下では転送のトランザクションをキャンセルさせるなど)を起こしたいと考えているとします.
//      Hは, その処理を実装したコントラクト(つまり`IERC777Sender`を実装し`tokensToSend`関数に処理を記述したコントラクト)を用意し, `IERC1820`に登録しています.
// 1. OがHのトークンをどこかに送信(または焼却)しようと`ERC777`のsend関数を呼び出します.
// 2. send関数内では, トークン転送を行う前にHが`IERC777Sender`を実装したコントラクトを登録しているか`IERC1820`に問い合わせます.
// 3. 2がYesの場合, 登録されているコントラクトの`tokensToSend`関数を呼び出します. Noの場合は何も実行しません.
// 4. 3の終了後, トランザクションのキャンセル等起きなければトークンの転送処理に進みます.

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 * their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Sender {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}
