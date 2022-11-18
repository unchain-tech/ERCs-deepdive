// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

// このファイルでは，ERC721トークンをtransferするときに，``to`` アドレスがERC721トークンを受け取ることができるかを判断できるものとなっています．
// というのも，コントラクトアドレスに送信したNFTというのは基本的にはGOXします．
// 例外として，コントラクトアドレス側にNFTを扱うためのコントラクトが存在する場合に引き出すことが出来るのです．
// そのため，不運なGOXを避けるために，NFTの送信を行う際には送信先の ``to`` アドレスがコントラクトアドレスだった場合にこのインターフェイスが導入されていないものには送れないようにする ``_safeTransfer`` という送信規格が提案されました．
// よって，NFTの送信を受けるためのコントラクトを作りたい場合はこのインターフェイスを継承しておくことが推奨されます．
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
