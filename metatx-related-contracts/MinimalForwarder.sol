// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSA.sol";
import "../utils/cryptography/draft-EIP712.sol";

// 主にテスト用のコントラクト、実運用するためのforwarderとしては機能が不十分。
// from address(送信者)の署名とNonceを検証する
/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 *
 * MinimalForwarder is mainly meant for testing, as it is missing features to be a good production-ready forwarder. This
 * contract does not intend to have all the properties that are needed for a sound forwarding system. A fully
 * functioning forwarding system with good properties requires more complexity. We suggest you look at other projects
 * such as the GSN which do have the goal of building a system like that.
 */
contract MinimalForwarder is EIP712 {
    // ECDSA署名を復号するためのrecover関数を使えるようにする
    using ECDSA for bytes32;

    // requestのstructを定義
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    // requestのstructをhash化したも
    // 署名を復号する際に使用する
    bytes32 private constant _TYPEHASH =
        keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)"
        );

    // signer毎に実行されたtransaction数を保持し、replay attackを防ぐために使用する
    mapping(address => uint256) private _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    // フロントエンドからrequestを投げる前に、この関数を呼び出して最新のnonceを取得し、requestに含める
    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    // signerの署名とnonce値を検証する
    function verify(ForwardRequest calldata req, bytes calldata signature)
        public
        view
        returns (bool)
    {
        address signer = _hashTypedDataV4( // encodeされたEIP712のメッセージのハッシュ値を返す
            keccak256(
                abi.encode(
                    _TYPEHASH,
                    req.from,
                    req.to,
                    req.value,
                    req.gas,
                    req.nonce,
                    keccak256(req.data)
                )
            )
        ).recover(signature); // ハッシュから値から署名者(metatxを実行した人)のアドレスを復号する
        // reqに含まれるnonceとcontract内で保持しているsignerのnonceが一致している
        // 且つ、ハッシュ値から復号したsignerとreq.fromが一致していればtrueを返す
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    // 署名を検証して、問題なけば、req.dataに含まれる関数名と引数を使って、関数を実行する
    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        // 署名、nonceを検証する
        require(
            verify(req, signature),
            "MinimalForwarder: signature does not match request"
        );
        // nonceをincrementする
        _nonces[req.from] = req.nonce + 1;

        // req.dataに含まれる関数名と引数を使って、関数を実行する
        (bool success, bytes memory returndata) = req.to.call{
            gas: req.gas,
            value: req.value
        }(abi.encodePacked(req.data, req.from)); // req.dataの末尾にreq.fromを追加

        // TODO: リンクの内容にある the 1/64 rule が理解できていません。誰か補足お願いします。
        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }
}
