// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

// metatxのRecipientContractにあたるContractに継承するコントラクト
// trustedForwarderからmetatxを受け取るときに使用する
/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    // 悪意のある人がtrustedForwarderを書き換えることを防ぐために、
    // ownerのみ書き換え可能あるいは書き換え不可能にすることが推奨されている(https://eips.ethereum.org/EIPS/eip-2771)
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    // 引数のforwarder(msg.sender)がtrustedForwarderであることを確認する関数
    // このcontractがmetatxで実行されるものなのかを外部から判断することは難しいため
    // 受け取ったtransactionに応じて_msgSender()、_msgData()を適切にoverrideするために使用する
    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // trastedForwarderから呼び出された場合は、addressを抽出して、msg.senderの代わりにする
            // assembly {} はInline Assemblyという機能で、EVMに対して直接命令を書いている
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                // forwarderのexecuteでabi.encodePacked(req.data, req.from)しているので、msg.dataの最後の20bytesがaddressのデータとして使用される
                // sub(calldatasize(), 20)でaddressのスタート地点を計算する。
                // その値をcalldataloadに渡して、そこから32bytesを取り出す。
                // 32bytesの中身は e36ab9f4cc11bD98753F05943D5394D16B356D6A000000000000000000000000 こんな感じになっているので、
                // shift right 96bits(32bytes)をして、000000000000000000000000e36ab9f4cc11bD98753F05943D5394D16B356D6A の状態にする。
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            // trastedForwarder以外から呼び出された場合はoverride前のmsg.senderを返す
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            // addressを除いたmsg.dataを返す
            // forwarderのexecuteでabi.encodePacked(req.data, req.from)しているので、msg.dataの最後の20bytesがaddressのデータとして使用される
            return msg.data[:msg.data.length - 20];
        } else {
            // trastedForwarder以外から呼び出された場合はoverride前のmsg.senderを返す
            return super._msgData();
        }
    }
}
