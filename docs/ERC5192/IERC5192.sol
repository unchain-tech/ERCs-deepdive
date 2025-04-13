// SPDX-License-Identifier: CC0-1.0
// ethereum EIP (EIPs/EIPS/eip-5192.md)
pragma solidity ^0.8.0;

// IERC5192はEIPの段階であることにご留意ください．
// このファイルでは，``interface`` という分類の ``contract`` の中で，``ERC5192.sol`` 内に存在する関数の中で可視性が ``internal`` でないものの型定義と，コメントを用いた関数の説明がなされています．
// ``abstract`` と ``interface`` の違いは，``contract`` 内に関数を内包するか否かです．

interface IERC5192 {
    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool);
}
