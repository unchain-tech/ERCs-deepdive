// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

// このファイルでは，``interface`` という分類の ``contract`` の中で，
// ``ERC721.sol`` 内で ``_name`` 変数を参照する ``name`` 関数，
// ``ERC721.sol`` 内で ``_symbol`` 変数を参照する ``symbol`` 関数，
// ``ERC721.sol`` 内で ``_baseURI()`` の返り値と ``tokenId`` を参照する ``tokenURI`` 関数
// の三つの関数を型定義しています．
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}