// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

// IERC777Recipientは`tokensReceived`という関数の実装を定義するインタフェースです.
// `tokensReceived`はあるアカウントに対して「トークンが転送される」=「トークンが増加する」アクションが起きた際に, 
// アカウント(トークン受信者)があらかじめ登録しておいた処理を実行することができます.
// このようにあるプロセスの間に挿入する処理をフックと呼んだりします.
//
// 以下にIERC777Recipientと`tokensReceived`が使用される場面を示します. 先にERC777と`IERC1820`のファイル冒頭の説明に目を通してください.
// 登場人物: ERC777のholderであるH. HのoperatorであるO.
// 前提: Hは, 自身にトークンが転送される際に
//      通知または何らかのアクション(特定の条件下では転送のトランザクションをキャンセルさせるなど)を起こしたいと考えているとします.
//      Hは, その処理を実装したコントラクト(つまりIERC777Recipientを実装し`tokensReceived`関数に処理を記述したコントラクト)を用意し, `IERC1820`に登録しています.
// 1. OがHにトークンを送信(または発行)しようとERC777のsend関数を呼び出します.
// 2. send関数内では, Hの残高を変更後にHがIERC777Recipientを実装したコントラクトを登録しているか`IERC1820`に問い合わせます.
// 3. 2がYesの場合, 登録されているコントラクトの`tokensReceived`関数を呼び出します. Noの場合の処理は別であります.
// 4. 3の終了後, トランザクションのキャンセル等起きなければトークンの転送処理が完了します.

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    // この関数はholderの残高が変更された後に呼び出される必要がある.
    // revert処理を入れることでトークンの転送をキャンセルすることが可能.
    // msg.senderはERC777であることが期待される.
    // 引数の内容は以下です.
    // operator: operator
    // from: holder(0x0の場合はトークンが発行されたことを指す)
    // to: トークンの転送先
    // amount: 転送量
    // userData: (空でなければ)転送に付与されたデータ
    // operatorData: (空でなければ)operatorによって付与されたデータ
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}
