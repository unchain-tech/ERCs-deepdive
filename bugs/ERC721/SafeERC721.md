# SafeERC721 を使用する

## 🔗 URL

https://github.com/code-423n4/2022-05-cally-findings/issues/136

## ⛳️ Condition

1. ERC721.transfer において送信先のアドレスが onERC721Received の確認をしていない

https://github.com/code-423n4/2022-03-lifinance/blob/main/src/Facets/DexManagerFacet.sol#L62-L77

```solidity
// transfer the NFTs or ERC20s back to the owner
vault.tokenType == TokenType.ERC721
    ? ERC721(vault.token).transferFrom(address(this), msg.sender, vault.tokenIdOrAmount) // here
}
```

## 👨‍💻 PoC

onERC721Received のチェックがなく、送信先が ERC721 トークンを適切に扱えないスマートコントラクト（マルチシグウォレットでもよい）の場合、NFT は操作することができず、結果的に失われることになります。

## ✅ Recommendation

OpenZeppelin の safeTransferFrom を transferFrom の代わりに使用する
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol#L164-L170

```solidity
// before
// transfer the NFTs or ERC20s back to the owner
vault.tokenType == TokenType.ERC721
    ? ERC721(vault.token).transferFrom(address(this), msg.sender, vault.tokenIdOrAmount) // here
}

// after
// transfer the NFTs or ERC20s back to the owner
vault.tokenType == TokenType.ERC721
    ? ERC721(vault.token).safeTransferFrom(address(this), msg.sender, vault.tokenIdOrAmount) // here
}
```

## 👬 Similar Issue

https://github.com/code-423n4/2022-04-backed-findings/issues/83
