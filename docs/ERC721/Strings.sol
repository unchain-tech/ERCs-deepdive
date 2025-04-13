// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

// これは，uint列を文字列，特に16進数文字列に変換する関数のスタンダードを集めたライブラリです．
// ERC721に使われているのは ``toString(uint256 value)``関数のみであるため，解説はそこのみにとどめます．
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    // この関数は，引数のuintをストリング形式に変換しています．
    // 一つ目のwhile文で引数に指定したuintの桁数をuint変数であるdigitsに格納します．
    // 二つ目のwhile文では，まず引数のuintの一桁一桁を10を法としたmod演算(%)で分割した後，
    // それぞれに48(0x30)を足してから1バイトのバイナリ形式に変換し，桁数として格納したdigitsを上手く用いることによって
    // bufferというbytes(配列)として一桁ずつ順番に格納しています．
    // 48を足す(16進数二桁表示にしたときに一桁目が3になる)ことによって，
    // アラビア数字の0～9の数値の大きさが，ASCIIコードに即したアラビア数字0～9の文字コードのバイナリ情報に変換されます．
    // (ASCIIコードについては右を参照→(https://www.gixo.jp/blog/12465/))
    // 最後にstring()関数(バイナリの配列要素を順に連結してSolidityのstringとしてエンコードしてくれる)を利用して，
    // buffer配列をstring形式(Utf-8)にエンコードしています．
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        // 一つ目のwhile文
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        // 二つ目のwhile文
        while (value != 0) {
            digits -= 1;
            // 48(10進数) = 16^2 * 3 + 16^1 * 0 = 30(16進数)
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}
