// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

// このファイルには，インターフェイス検知の標準規格である ``ERC165`` にもとづくメソッドが定義されています．
// 検知を実装したいコントラクト，検知したいコントラクトに対して継承し，
// 前者の検知を実装したいコントラクト内で ``supportsInterface(bytes4 interfaceId)`` 関数を適切に ``override`` することで検知を行えるようになります．
// 検知時に実際に行うのは，引数(実装されているかどうか確かめたいインターフェイスのId)と，検知実装時に条件節として登録しておいたインターフェイス名に紐づいたインターフェイスIdとの真偽比較です．
// type()メソッドは元来関数名等EVMストレージに格納されたメソッドの型名を呼び出すグローバル関数ですが，インターフェイス名をゐれた場合には下記のように紐づいたIdを参照できます．
// これは，インターフェイスのデプロイ時にストレージにアップロードされたデータ上で，json形式の形で紐づけられているからだと考えられます．
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}
