// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

// EIP-2771などの，メタトランザクションという
// ある程度オフチェーン通信コストと引き換えにガス代を仲介者が肩代わりするスキームが存在している．
// 詳しくはここを参照(https://github.com/unchain-dev/openzeppelin-deepdive/tree/main/metatx#2-meta-transaction%E3%81%A8%E3%81%AF-1)．
// msg.senderはEVMに規定されたグローバル変数なので書き換えできないが，
// 関数の中にmsg.senderをラップした_msgSender()関数を使うことによって，
// メタトランザクション使用時には_msg.sender()関数をオーバーライドして返り値を書き換えることにより，
// msg.sender(gas feeを支払うアドレス)と_msgSender()の返り値(txを実行したいアドレス)を
// 分けることができるようになる．
// そのために存在している抽象契約だそう．
 /**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}