# Oracles

## Invalid Validation

Oracle データフィードの検証が不十分

### 🔗 URL

https://github.com/code-423n4/2022-01-yield-findings/issues/136

### ⛳️ Condition

1. Chainlink の`latestRoundData`を使用している
2. 取得したデータの検証が不十分である

https://github.com/code-423n4/2022-04-jpegd/blob/e72861a9ccb707ced9015166fbded5c97c6991b6/contracts/vaults/FungibleAssetVaultForDAO.sol#L104-L115

```javascript
function _collateralPriceUsd() internal view returns (uint256) {
    int256 answer = oracle.latestAnswer(); // here
    uint8 decimals = oracle.decimals();

    require(answer > 0, "invalid_oracle_answer");　// here

    //check chainlink's precision and convert it to 18 decimals
    return
        decimals > 18
            ? uint256(answer) / 10**(decimals - 18)
            : uint256(answer) * 10**(18 - decimals);
}
```

### 👨‍💻 PoC

価格が新しいものであるかの確認、timestamp の値が正当であるのかという確認がありません。
この影響で価格が古かったり、間違った値を返してしまう可能性があります。

### ✅ Recommendation

ここにバグを修正する方法を記載してください

例: 下記のように変更してください

```javascript
// before
function _collateralPriceUsd() internal view returns (uint256) {
    int256 answer = oracle.latestAnswer(); // here
    uint8 decimals = oracle.decimals();

    require(answer > 0, "invalid_oracle_answer");　// here

    //check chainlink's precision and convert it to 18 decimals
    return
        decimals > 18
            ? uint256(answer) / 10**(decimals - 18)
            : uint256(answer) * 10**(18 - decimals);
}

// after
function _collateralPriceUsd() internal view returns (uint256) {
    int256 answer = oracle.latestAnswer(); // here
    uint8 decimals = oracle.decimals();

    require(answer > 0, "invalid_oracle_answer");　// here
    require(answeredInRound >= roundID, "ChainLink: Stale price"); // add
    require(timestamp > 0, "ChainLink: Round not complete"); // add

    //check chainlink's precision and convert it to 18 decimals
    return
        decimals > 18
            ? uint256(answer) / 10**(decimals - 18)
            : uint256(answer) * 10**(18 - decimals);
}
```

### 👬 Similar Issue

https://github.com/code-423n4/2022-04-backd-findings/issues/17
